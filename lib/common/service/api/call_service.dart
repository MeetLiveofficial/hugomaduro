import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/model/call/call_request_model.dart';

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

  Future<CallInboxResult> inbox() async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.call.inbox,
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'call inbox failed');
    }
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return CallInboxResult(
      received: ((data['received'] as List?) ?? [])
          .map((e) => CallRequestModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      sent: ((data['sent'] as List?) ?? [])
          .map((e) => CallRequestModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Future<CallRequestModel> accept(int callRequestId) async {
    return _mutate(WebService.call.accept, callRequestId);
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
