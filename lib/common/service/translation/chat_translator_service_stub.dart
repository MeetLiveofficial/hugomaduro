import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/chat_service.dart';
import 'package:krimson/model/chat/message_data.dart';

/// Fallback para Web / plataformas sin ML Kit.
/// Traduce vía `POST /api/chat/translate` (el móvil sigue usando on-device).
class ChatTranslatorService {
  ChatTranslatorService._();

  static final ChatTranslatorService instance = ChatTranslatorService._();

  final Map<String, String> _cache = {};
  static const int _maxCacheEntries = 800;

  bool get isReady => true;

  Future<void> preloadForUserLanguage({String? langCode}) async {}

  Future<void> ensureReady({String? targetLangCode}) async {}

  Future<bool> isModelDownloaded(Object language) async => false;

  Future<void> ensureModelsDownloaded(
    List<Object> languages, {
    bool preferWifi = true,
  }) async {}

  Future<List<MessageData>> translateIncoming(
    List<MessageData> messages, {
    required int? myUserId,
    String? targetLangCode,
  }) async {
    if (messages.isEmpty) return messages;

    final target = (targetLangCode ?? SessionManager.instance.getLang())
        .trim()
        .toLowerCase()
        .split(RegExp(r'[-_]'))
        .first;

    final jobs = <({int index, int id, String text, String cacheKey})>[];
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final id = m.id;
      if (id == null) continue;
      if (myUserId != null && m.userId == myUserId) continue;
      if (m.isTranslated) continue;
      final text = (m.textMessage ?? '').trim();
      if (text.isEmpty) continue;
      final cacheKey = '$id|$target|${text.hashCode}';
      jobs.add((index: i, id: id, text: text, cacheKey: cacheKey));
    }

    if (jobs.isEmpty) return messages;

    final translationsById = <int, String>{};
    final toFetch = <({int id, String text, String cacheKey})>[];

    for (final job in jobs) {
      final cached = _cache[job.cacheKey];
      if (cached != null) {
        translationsById[job.id] = cached;
      } else {
        toFetch.add((id: job.id, text: job.text, cacheKey: job.cacheKey));
      }
    }

    if (toFetch.isNotEmpty) {
      try {
        final results = await ChatService.instance.translateTexts(
          targetLang: target,
          texts: toFetch.map((e) => e.text).toList(),
        );
        for (var i = 0; i < toFetch.length; i++) {
          final job = toFetch[i];
          final translated =
              i < results.length && results[i].trim().isNotEmpty
                  ? results[i]
                  : job.text;
          _putCache(job.cacheKey, translated);
          translationsById[job.id] = translated;
        }
      } catch (e) {
        Loggers.error('ChatTranslator(web) batch: $e');
        return messages;
      }
    }

    if (translationsById.isEmpty) return messages;

    return [
      for (final m in messages)
        if (m.id != null &&
            translationsById.containsKey(m.id) &&
            translationsById[m.id] != (m.textMessage ?? ''))
          m.copyWithTranslation(
            originalText: m.originalTextMessage ?? m.textMessage,
            translatedText: translationsById[m.id]!,
          )
        else
          m,
    ];
  }

  Future<String> translateText(
    String text, {
    String? targetLangCode,
    String? sourceLangCode,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;
    final target = (targetLangCode ?? SessionManager.instance.getLang())
        .trim()
        .toLowerCase()
        .split(RegExp(r'[-_]'))
        .first;
    try {
      final results = await ChatService.instance.translateTexts(
        targetLang: target,
        texts: [trimmed],
      );
      if (results.isNotEmpty && results.first.trim().isNotEmpty) {
        return results.first;
      }
    } catch (e) {
      Loggers.error('ChatTranslator(web) text: $e');
    }
    return text;
  }

  void _putCache(String key, String value) {
    if (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  Future<void> dispose() async {
    _cache.clear();
  }
}
