class SupportTicket {
  SupportTicket({
    this.id,
    this.ticketNumber,
    this.subject,
    this.status,
    this.priority,
    this.lastMsg,
    this.userUnread,
    this.adminUnread,
  });

  final int? id;
  final String? ticketNumber;
  final String? subject;
  final String? status;
  final String? priority;
  final String? lastMsg;
  final int? userUnread;
  final int? adminUnread;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: _asInt(json['id']),
      ticketNumber: json['ticket_number']?.toString(),
      subject: json['subject']?.toString(),
      status: json['status']?.toString(),
      priority: json['priority']?.toString(),
      lastMsg: json['last_msg']?.toString(),
      userUnread: _asInt(json['user_unread']),
      adminUnread: _asInt(json['admin_unread']),
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

class SupportSummary {
  SupportSummary({
    required this.hasTicket,
    required this.lastMsg,
    required this.userUnread,
    this.ticket,
  });

  final bool hasTicket;
  final String lastMsg;
  final int userUnread;
  final SupportTicket? ticket;

  factory SupportSummary.fromJson(Map<String, dynamic> json) {
    return SupportSummary(
      hasTicket: json['has_ticket'] == true,
      lastMsg: (json['last_msg'] ?? 'Crea un ticket de soporte').toString(),
      userUnread: SupportTicket._asInt(json['user_unread']) ?? 0,
      ticket: json['ticket'] is Map
          ? SupportTicket.fromJson(Map<String, dynamic>.from(json['ticket']))
          : null,
    );
  }
}

class SupportMessage {
  SupportMessage({
    this.id,
    this.ticketId,
    this.authorType,
    this.authorId,
    this.isMe,
    this.messageType,
    this.textMessage,
    this.imageMessage,
    this.createdMs,
  });

  final int? id;
  final int? ticketId;
  final String? authorType;
  final int? authorId;
  final bool? isMe;
  final String? messageType;
  final String? textMessage;
  final String? imageMessage;
  final int? createdMs;

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: SupportTicket._asInt(json['id'] ?? json['db_id']),
      ticketId: SupportTicket._asInt(json['ticket_id']),
      authorType: json['author_type']?.toString(),
      authorId: SupportTicket._asInt(json['author_id']),
      isMe: json['is_me'] == true,
      messageType: json['message_type']?.toString() ?? 'text',
      textMessage: json['text_message']?.toString(),
      imageMessage: json['image_message']?.toString(),
      createdMs: SupportTicket._asInt(json['created_ms']),
    );
  }
}
