import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/model/support/support_ticket.dart';

class SupportService {
  SupportService._();
  static final SupportService instance = SupportService._();

  Future<SupportSummary> summary() async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.support.summary,
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'support summary failed');
    }
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return SupportSummary.fromJson(data);
  }

  Future<SupportTicket?> openOrGet({String? subject}) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.support.openOrGet,
      param: {if (subject != null) 'subject': subject},
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'openOrGet failed');
    }
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final raw = data['ticket'];
    if (raw is! Map) return null;
    return SupportTicket.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<({SupportTicket? ticket, List<SupportMessage> messages})>
      fetchMessages({int? ticketId, int? afterId}) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.support.fetchMessages,
      param: {
        'ticket_id': ticketId,
        'after_id': afterId,
        'limit': 50,
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'fetchMessages failed');
    }
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final rawTicket = data['ticket'];
    final ticket = rawTicket is Map
        ? SupportTicket.fromJson(Map<String, dynamic>.from(rawTicket))
        : null;
    final messages = ((data['messages'] as List?) ?? [])
        .map((e) => SupportMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return (ticket: ticket, messages: messages);
  }

  Future<({SupportTicket ticket, SupportMessage message})> sendMessage({
    int? ticketId,
    required String text,
    String? subject,
  }) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.support.sendMessage,
      param: {
        'ticket_id': ticketId,
        'message_type': 'text',
        'text_message': text,
        if (subject != null) 'subject': subject,
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'sendMessage failed');
    }
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return (
      ticket: SupportTicket.fromJson(
          Map<String, dynamic>.from(data['ticket'] as Map)),
      message: SupportMessage.fromJson(
          Map<String, dynamic>.from(data['message'] as Map)),
    );
  }

  Future<void> markRead({int? ticketId}) async {
    await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.support.markRead,
      param: {'ticket_id': ticketId},
      fromJson: (j) => j,
    );
  }
}
