import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/model/work/streamer_work_stats_model.dart';

class CallService {
  CallService._();
  static final CallService instance = CallService._();

  Future<CallRequestModel> create({required int userId}) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.create,
      param: {'user_id': userId},
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'call create failed');
    }
    return CallRequestModel.fromJson(
        Map<String, dynamic>.from(json['data'] as Map));
  }

  /// Recomienda streamer del mismo idioma para Match (sin crear la llamada).
  Future<MatchRecommendation> findMatch({String? appLanguage}) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.findMatch,
      param: {
        if ((appLanguage ?? '').trim().isNotEmpty)
          'app_language': appLanguage!.trim(),
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'no match available');
    }
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? {});
    final userMap = data['user'];
    if (userMap is! Map) {
      throw Exception('no match available');
    }
    return MatchRecommendation(
      user: User.fromJson(Map<String, dynamic>.from(userMap)),
      callCost: data['call_cost'] is num
          ? (data['call_cost'] as num).toInt()
          : int.tryParse('${data['call_cost'] ?? 0}') ?? 0,
      matchFreeSeconds: data['match_free_seconds'] is num
          ? (data['match_free_seconds'] as num).toInt()
          : int.tryParse('${data['match_free_seconds'] ?? 30}') ?? 30,
      appLanguage: data['app_language']?.toString(),
    );
  }

  Future<CallInboxResult> inbox() async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.inbox,
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'call inbox failed');
    }
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final received = (data['received'] as List? ?? [])
        .map((e) => CallRequestModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final sent = (data['sent'] as List? ?? [])
        .map((e) => CallRequestModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return CallInboxResult(received: received, sent: sent);
  }

  Future<CallRequestModel> accept(int callRequestId) async {
    return _mutate(WebService.call.accept, callRequestId);
  }

  Future<CallRequestModel> status(int callRequestId) async {
    return _mutate(WebService.call.status, callRequestId);
  }

  Future<CallRequestModel> reject(int callRequestId) async {
    return _mutate(WebService.call.reject, callRequestId);
  }

  Future<CallRequestModel> cancel(int callRequestId) async {
    return _mutate(WebService.call.cancel, callRequestId);
  }

  Future<CallRequestModel> end(int callRequestId) async {
    return _mutate(WebService.call.end, callRequestId);
  }

  Future<StreamerWorkStats> workStats() async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.workStats,
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'work stats failed');
    }
    return StreamerWorkStats.fromJson(
        Map<String, dynamic>.from(json['data'] as Map? ?? {}));
  }

  Future<Map<String, dynamic>> updateCallPrice({required int callPrice}) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.updateCallPrice,
      param: {'call_price': callPrice},
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'update call price failed');
    }
    return Map<String, dynamic>.from(json['data'] as Map? ?? {});
  }

  Future<CallRequestModel> _mutate(String url, int callRequestId) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: url,
      param: {'call_request_id': callRequestId},
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'call action failed');
    }
    return CallRequestModel.fromJson(
        Map<String, dynamic>.from(json['data'] as Map));
  }
}

class CallInboxResult {
  CallInboxResult({required this.received, required this.sent});
  final List<CallRequestModel> received;
  final List<CallRequestModel> sent;
}

class MatchRecommendation {
  MatchRecommendation({
    required this.user,
    required this.callCost,
    this.matchFreeSeconds = 30,
    this.appLanguage,
  });

  final User user;
  final int callCost;
  final int matchFreeSeconds;
  final String? appLanguage;
}
