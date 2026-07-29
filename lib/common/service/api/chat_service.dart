import 'dart:convert';

import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/model/chat/chat_thread.dart';
import 'package:krimson/model/chat/message_data.dart';

class ChatThreadsResult {
  ChatThreadsResult({required this.chats, required this.requests});
  final List<ChatThread> chats;
  final List<ChatThread> requests;
}

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  Future<ChatThreadsResult> fetchThreads() async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.chat.fetchThreads,
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'fetchThreads failed');
    }
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final chats = ((data['chats'] as List?) ?? [])
        .map((e) => ChatThread.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final requests = ((data['requests'] as List?) ?? [])
        .map((e) => ChatThread.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return ChatThreadsResult(chats: chats, requests: requests);
  }

  Future<List<MessageData>> fetchMessages({
    String? conversationId,
    int? peerUserId,
    int? afterId,
  }) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.chat.fetchMessages,
      param: {
        'conversation_id': conversationId,
        'peer_user_id': peerUserId,
        'after_id': afterId,
        'limit': 50,
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'fetchMessages failed');
    }
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ((data['messages'] as List?) ?? [])
        .map((e) => MessageData.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<MessageData> sendMessage({
    required int peerUserId,
    required MessageType type,
    String? textMessage,
    String? imageMessage,
    String? videoMessage,
    String? audioMessage,
    String? postMessage,
    String? storyReplyMessage,
    String? waveData,
  }) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.chat.sendMessage,
      param: {
        'peer_user_id': peerUserId,
        'message_type': type.value,
        'text_message': textMessage,
        'image_message': imageMessage,
        'video_message': videoMessage,
        'audio_message': audioMessage,
        'post_message': postMessage,
        'story_reply_message': storyReplyMessage,
        'wave_data': waveData,
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'sendMessage failed');
    }
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return MessageData.fromJson(
        Map<String, dynamic>.from(data['message'] as Map));
  }

  Future<void> markRead({required int peerUserId}) async {
    await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.chat.markRead,
      param: {'peer_user_id': peerUserId},
      fromJson: (j) => j,
    );
  }

  Future<void> updateThread({
    required int peerUserId,
    String? chatType,
    String? requestType,
    bool? isDeleted,
    bool? iBlocked,
  }) async {
    await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.chat.updateThread,
      param: {
        'peer_user_id': peerUserId,
        'chat_type': chatType,
        'request_type': requestType,
        'is_deleted': isDeleted == null ? null : (isDeleted ? 1 : 0),
        'i_blocked': iBlocked == null ? null : (iBlocked ? 1 : 0),
      },
      fromJson: (j) => j,
    );
  }

  /// Fallback de traducción (Web / sin ML Kit) vía backend.
  Future<List<String>> translateTexts({
    required String targetLang,
    required List<String> texts,
  }) async {
    if (texts.isEmpty) return const [];
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.chat.translate,
      param: {
        'target': targetLang,
        'texts_json': jsonEncode(texts),
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'translate failed');
    }
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final list = (data['translations'] as List?) ?? [];
    return list.map((e) => '$e').toList();
  }
}
