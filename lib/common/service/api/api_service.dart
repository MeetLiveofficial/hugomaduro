import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:krimson/common/functions/debounce_action.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/utils/params.dart';
import 'package:krimson/screen/auth_screen/login_screen.dart';
import 'package:krimson/screen/session_expired_screen/session_expired_screen.dart';
import 'package:krimson/utilities/const_res.dart';

class CancelToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  void dispose() {
    _isCancelled = false;
  }
}

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  final Map<CancelToken, http.Client> _activeClients = {};

  Map<String, String> _buildHeaders({required bool cancelAuthToken}) {
    final headers = <String, String>{
      Params.apikey: apiKey,
    };
    if (!cancelAuthToken && SessionManager.instance.hasAuthToken) {
      headers[Params.authToken] = SessionManager.instance.getAuthToken();
    }
    return headers;
  }

  Future<T> call<T>({
    required String url,
    Map<String, dynamic>? param,
    CancelToken? cancelToken,
    bool cancelAuthToken = false,
    T Function(Map<String, dynamic> json)? fromJson,
    Function()? onError,
  }) async {
    final client = http.Client();
    if (cancelToken != null && cancelToken.isCancelled) {
      _activeClients[cancelToken] = client;
    }

    Map<String, String> params = {};
    param?.removeWhere((key, value) =>
        key != Params.deviceToken &&
        (value == null || value == 'null' || value == ''));
    param?.forEach((key, value) {
      if (key == Params.deviceToken) {
        final token = "$value";
        params[key] = (token.isEmpty || token == 'null')
            ? 'krimson_web_${DateTime.now().millisecondsSinceEpoch}'
            : token;
        return;
      }
      if (value == null || value == 'null') return;
      params[key] = "$value";
    });

    final headers = _buildHeaders(cancelAuthToken: cancelAuthToken);
    Loggers.info("URL: $url");
    Loggers.info("header: $headers");
    Loggers.info("Parameters: ${params.isEmpty ? "Empty" : params}");
    try {
      final response = await client
          .post(Uri.parse(url), headers: headers, body: params)
          .timeout(const Duration(seconds: 20));
      Loggers.success(response.statusCode);
      if (cancelToken?.isCancelled ?? false) {
        if (kDebugMode) {
          print("Request cancelled: $url");
        }
        throw Exception('Request was cancelled');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse =
            jsonDecode(response.body) as Map<String, dynamic>;

        if (decodedResponse['message'] == 'this user is freezed!') {
          DebounceAction.shared.call(() {
            Get.offAll(
                () => const SessionExpiredScreen(type: SessionType.freeze));
          });
          return decodedResponse as T;
        }

        if (decodedResponse['status'] == false) {
          Loggers.error('API RESPONSE : ${decodedResponse['message']}');
          onError?.call();
        }

        var prettyString = const JsonEncoder.withIndent('  ').convert(decodedResponse);
        Loggers.info(prettyString);

        // Use the provided `fromJson` function to parse the response
        if (fromJson != null) {
          return fromJson(decodedResponse);
        }

        // If no `fromJson` is provided, return the raw response
        return decodedResponse as T;
      } else if (response.statusCode == 401) {
        Loggers.error('Unauthorized Error 401: ${response.statusCode}');
        // Solo forzar logout si Laravel confirma token inválido/ausente.
        // Otros 401 (p.ej. LiveKit interno mal mapeado) no deben cerrar sesión.
        final bodyLower = response.body.toLowerCase();
        final isSessionAuth = bodyLower.contains('invalid token') ||
            bodyLower.contains('token not provided') ||
            bodyLower.contains('unauthorized access');
        if (isSessionAuth) {
          SessionManager.instance.clearSomeKey();
          DebounceAction.shared.call(() {
            // Evita bucle Get.offAll(Login) si polls/timers siguen vivos tras logout.
            final route = Get.currentRoute.toLowerCase();
            if (route == '/login' || route.endsWith('/login')) return;
            Get.offAll(() => const LoginScreen(), routeName: '/login');
          });
        }
        throw Exception("Unauthorized Error: ${response.statusCode}");
      } else if (response.statusCode == 404) {
        Loggers.error('Please check baseURL in const.dart file');
        throw Exception("URL Error: ${response.statusCode} - $url");
      } else {
        final errorBody = response.body;
        String detail = '';
        try {
          final decoded = jsonDecode(errorBody);
          if (decoded is Map && decoded['message'] != null) {
            detail = decoded['message'].toString();
          }
        } catch (_) {
          detail = _extractErrorMessage(errorBody);
        }
        Loggers.error('HTTP Error ${response.statusCode}: $detail');
        throw Exception(detail.isNotEmpty
            ? 'HTTP Error: ${response.statusCode} - $detail'
            : 'HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } on HttpException {
      throw Exception('Could not connect to the server');
    } on FormatException catch (e) {
      // Handle JSON decoding errors
      Loggers.error("Invalid JSON format: ${e.message}");
      throw Exception("Invalid JSON format: ${e.message}");
    } on Exception catch (e) {
      Loggers.error("Unexpected error : $e");
      rethrow;
    } finally {
      _cleanupClient(cancelToken);
    }
  }

  String _extractErrorMessage(String responseBody) {
    final regex = RegExp(
      r'<!--\s*(.*?)\s*#0 ', // Matches everything between <!-- and #0
      dotAll: true,
    );
    final match = regex.firstMatch(responseBody);
    return match?.group(1)?.trim() ??
        "Unknown error occurred: ${_shorten(responseBody)}";
  }

  /// Shortens the response body if no specific error is found
  String _shorten(String responseBody) {
    const maxLength = 100;
    return responseBody.length > maxLength
        ? "${responseBody.substring(0, maxLength)}..."
        : responseBody;
  }

  Future<T> callGet<T>({required String url}) async {
    http.Response response = await http.get(Uri.parse(url));
    return jsonDecode(response.body);
  }

  Future<T> multiPartCallApi<T>({
    required String url,
    Map<String, dynamic>? param,
    required Map<String, List<XFile?>> filesMap,
    Function(double percentage)? onProgress,
    CancelToken? cancelToken,
    T Function(Map<String, dynamic> json)? fromJson,
  }) async {
    final client = http.Client();
    if (cancelToken != null) {
      _activeClients[cancelToken] = client;
    }

    final request = MultipartRequest(
      'POST',
      Uri.parse(url),
      onProgress: (bytes, totalBytes) {
        if (onProgress != null) {
          onProgress(bytes / totalBytes);
        }
      },
    );

    Map<String, String> params = {};
    param?.removeWhere((key, value) => value == null || value == 'null');
    param?.forEach((key, value) {
      params[key] = "$value";
    });

    request.fields.addAll(params);
    request.headers.addAll(_buildHeaders(cancelAuthToken: false));

    // Build multipart files before send. On Web, XFile paths are blob: URLs —
    // dart:io File does not work; always read bytes via XFile.
    for (final entry in filesMap.entries) {
      final keyName = entry.key;
      for (final xFile in entry.value) {
        if (xFile == null) continue;
        if (xFile.path.isEmpty && xFile.name.isEmpty) continue;
        try {
          final bytes = await xFile.readAsBytes();
          if (bytes.isEmpty) continue;
          request.files.add(http.MultipartFile.fromBytes(
            keyName,
            bytes,
            filename: xFile.name.isNotEmpty
                ? xFile.name
                : 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ));
        } catch (e) {
          Loggers.error('multipart file skip ($keyName): $e');
        }
      }
    }
    Loggers.info("URL : $url");
    Loggers.info("HEADERS : ${request.headers}");
    Loggers.info("FIELDS : ${request.fields}");
    Loggers.info("FILES : ${request.files.map((e) => e)}");

    try {
      final responseStream = await client.send(request);

      if (cancelToken?.isCancelled ?? false) {
        if (kDebugMode) {
          Loggers.error("Request cancelled: $url");
        }
        throw Exception('Request was cancelled');
      }

      final statusCode = responseStream.statusCode;
      final responseStr = await responseStream.stream.bytesToString();

      Map<String, dynamic> decodedResponse;
      try {
        decodedResponse = jsonDecode(responseStr) as Map<String, dynamic>;
      } catch (_) {
        Loggers.error(
            'multipart non-JSON response HTTP $statusCode: ${responseStr.length > 200 ? responseStr.substring(0, 200) : responseStr}');
        decodedResponse = {
          'status': false,
          'message': statusCode >= 500
              ? 'Server error ($statusCode). Try again.'
              : 'Upload failed (HTTP $statusCode)',
          'data': null,
        };
      }

      if (decodedResponse['status'] == false) {
        Loggers.error(decodedResponse['message']);
      }
      if (fromJson != null) {
        return fromJson(decodedResponse);
      }

      return decodedResponse as T;
    } finally {
      _cleanupClient(cancelToken);
    }
  }

  void _cleanupClient(CancelToken? cancelToken) {
    if (cancelToken != null) {
      _activeClients[cancelToken]?.close();
      _activeClients.remove(cancelToken);
    }
  }

  Future<void> useAndDeleteFile(File file) async {
    try {
      // Use the file as needed
      Loggers.warning('File path: ${file.path}');

      // Delete the file after use
      if (await file.exists()) {
        await file.delete();
        Loggers.success('File deleted from: ${file.path}');
      }
    } catch (e) {
      Loggers.error('Error: $e');
    }
  }
}

class MultipartRequest extends http.MultipartRequest {
  MultipartRequest(
    super.method,
    super.url, {
    this.onProgress,
  });

  final void Function(int bytes, int totalBytes)? onProgress;

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    int bytes = 0;

    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        bytes += data.length;
        if (onProgress != null) {
          onProgress!(bytes, total);
        }
        sink.add(data);
      },
    );

    return http.ByteStream(byteStream.transform(transformer));
  }
}
