import 'dart:io' show Platform;
import 'dart:isolate';

import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/model/chat/message_data.dart';

/// Traducción on-device de mensajes de chat (Google ML Kit en Android e iOS).
///
/// Notas de rendimiento:
/// - El trabajo pesado corre en hilos nativos de ML Kit.
/// - Los MethodChannels de Flutter **no** están disponibles en Isolates puros;
///   por eso la cola de traducción vive en el isolate principal, cediendo
///   frames entre mensajes (`Future.delayed(Duration.zero)`).
/// - La preparación de lotes (filtrado / claves de caché) usa [Isolate.run].
class ChatTranslatorService {
  ChatTranslatorService._();

  static final ChatTranslatorService instance = ChatTranslatorService._();

  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();
  final LanguageIdentifier _languageId =
      LanguageIdentifier(confidenceThreshold: 0.45);

  /// Traductores reutilizados por par source→target (BCP-47).
  final Map<String, OnDeviceTranslator> _translators = {};

  /// Caché en memoria: `msgId|target|hash(text)` → texto traducido.
  final Map<String, String> _cache = {};
  static const int _maxCacheEntries = 800;

  /// Modelos ya confirmados como descargados en esta sesión.
  final Set<String> _downloadedModels = {};

  Future<void>? _preloadFuture;
  bool _isReady = false;
  bool get isReady => _isReady;

  bool get _isSupportedPlatform {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Precarga silenciosa de modelos (idioma del usuario + inglés).
  /// Pensado para splash / arranque; no bloquea la UI.
  Future<void> preloadForUserLanguage({String? langCode}) {
    if (!_isSupportedPlatform) {
      _isReady = true;
      return Future.value();
    }
    return _preloadFuture ??= _doPreload(langCode);
  }

  Future<void> _doPreload(String? langCode) async {
    try {
      final target = resolveLanguage(
        langCode ?? SessionManager.instance.getLang(),
      );
      final models = <TranslateLanguage>{
        TranslateLanguage.english,
        target,
      };
      // Par habitual EN↔ES si el usuario usa español (o viceversa).
      if (target == TranslateLanguage.spanish) {
        models.add(TranslateLanguage.english);
      } else if (target == TranslateLanguage.english) {
        models.add(TranslateLanguage.spanish);
      }

      await ensureModelsDownloaded(
        models.toList(),
        preferWifi: true,
      );
      _isReady = true;
      Loggers.info(
        'ChatTranslator: modelos listos → '
        '${models.map((e) => e.bcpCode).join(", ")}',
      );
    } catch (e) {
      Loggers.error('ChatTranslator preload: $e');
      // Reintentar en el próximo ensureReady / translate.
      _preloadFuture = null;
      _isReady = false;
    }
  }

  /// Garantiza modelos antes de abrir el chat (wifi no obligatorio).
  Future<void> ensureReady({String? targetLangCode}) async {
    if (!_isSupportedPlatform) {
      _isReady = true;
      return;
    }
    await preloadForUserLanguage(langCode: targetLangCode);
    if (_isReady) return;

    final target = resolveLanguage(
      targetLangCode ?? SessionManager.instance.getLang(),
    );
    await ensureModelsDownloaded(
      [TranslateLanguage.english, target],
      preferWifi: false,
    );
    _isReady = true;
  }

  Future<bool> isModelDownloaded(TranslateLanguage language) async {
    if (!_isSupportedPlatform) return false;
    final code = language.bcpCode;
    if (_downloadedModels.contains(code)) return true;
    final ok = await _modelManager.isModelDownloaded(code);
    if (ok) _downloadedModels.add(code);
    return ok;
  }

  /// Descarga silenciosa de modelos faltantes.
  Future<void> ensureModelsDownloaded(
    List<TranslateLanguage> languages, {
    bool preferWifi = true,
  }) async {
    if (!_isSupportedPlatform) return;

    for (final lang in languages) {
      final code = lang.bcpCode;
      if (_downloadedModels.contains(code)) continue;
      final exists = await _modelManager.isModelDownloaded(code);
      if (exists) {
        _downloadedModels.add(code);
        continue;
      }
      try {
        final ok = await _modelManager.downloadModel(
          code,
          isWifiRequired: preferWifi,
        );
        if (ok) {
          _downloadedModels.add(code);
          Loggers.info('ChatTranslator: modelo descargado $code');
        }
      } catch (e) {
        // Reintento sin exigir Wi‑Fi (p. ej. solo datos móviles).
        if (preferWifi) {
          try {
            final ok = await _modelManager.downloadModel(
              code,
              isWifiRequired: false,
            );
            if (ok) _downloadedModels.add(code);
          } catch (e2) {
            Loggers.error('ChatTranslator download $code: $e2');
          }
        } else {
          Loggers.error('ChatTranslator download $code: $e');
        }
      }
    }
  }

  /// Traduce mensajes entrantes **antes** de pintar la lista.
  /// Los propios del usuario se dejan igual.
  Future<List<MessageData>> translateIncoming(
    List<MessageData> messages, {
    required int? myUserId,
    String? targetLangCode,
  }) async {
    if (!_isSupportedPlatform || messages.isEmpty) {
      return messages;
    }

    final targetCode =
        targetLangCode ?? SessionManager.instance.getLang();
    final target = resolveLanguage(targetCode);

    // Prep en isolate: filtrado + claves de caché (solo tipos serializables).
    final payload = <Map<String, Object?>>[
      for (final m in messages)
        {
          'id': m.id,
          'userId': m.userId,
          'text': m.textMessage,
          'alreadyTranslated': m.isTranslated,
        },
    ];
    final jobs = await Isolate.run(
      () => _prepareTranslationJobs(
        payload,
        myUserId: myUserId,
        targetBcp: target.bcpCode,
      ),
    );

    if (jobs.isEmpty) return messages;

    await ensureReady(targetLangCode: targetCode);

    // Cola en isolate principal (platform channels), cediendo frames.
    final translations = <int, String>{};
    for (final job in jobs) {
      final id = job['id'] as int?;
      final text = job['text'] as String? ?? '';
      final cacheKey = job['cacheKey'] as String? ?? '';
      if (id == null || text.isEmpty) continue;

      final cached = _cache[cacheKey];
      if (cached != null) {
        translations[id] = cached;
        await Future<void>.delayed(Duration.zero);
        continue;
      }

      try {
        final translated = await _translateText(
          text: text,
          target: target,
        );
        if (translated != null && translated.isNotEmpty) {
          _putCache(cacheKey, translated);
          translations[id] = translated;
        }
      } catch (e) {
        Loggers.error('ChatTranslator msg $id: $e');
      }
      // Cedemos el event loop para no bloquear frames de Flutter.
      await Future<void>.delayed(Duration.zero);
    }

    if (translations.isEmpty) return messages;

    return messages.map((m) {
      final id = m.id;
      if (id == null || !translations.containsKey(id)) return m;
      final translated = translations[id]!;
      if (translated == (m.textMessage ?? '')) {
        return m;
      }
      return m.copyWithTranslation(
        originalText: m.originalTextMessage ?? m.textMessage,
        translatedText: translated,
      );
    }).toList();
  }

  /// Traduce un texto suelto (p. ej. caption puntual).
  Future<String> translateText(
    String text, {
    String? targetLangCode,
    String? sourceLangCode,
  }) async {
    if (!_isSupportedPlatform || text.trim().isEmpty) return text;
    final target = resolveLanguage(
      targetLangCode ?? SessionManager.instance.getLang(),
    );
    await ensureReady(targetLangCode: target.bcpCode);
    return await _translateText(
          text: text,
          target: target,
          sourceHint: sourceLangCode != null
              ? resolveLanguage(sourceLangCode)
              : null,
        ) ??
        text;
  }

  Future<String?> _translateText({
    required String text,
    required TranslateLanguage target,
    TranslateLanguage? sourceHint,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    TranslateLanguage source = sourceHint ?? TranslateLanguage.english;
    try {
      final detected = await _languageId.identifyLanguage(trimmed);
      if (detected != 'und') {
        source = resolveLanguage(detected);
      }
    } catch (_) {
      // Fallback: inglés como origen más habitual en chats mixtos.
    }

    if (source.bcpCode == target.bcpCode) {
      return text;
    }

    await ensureModelsDownloaded(
      [source, target],
      preferWifi: false,
    );

    final translator = await _translatorFor(source, target);
    final out = await translator.translateText(trimmed);
    return out.isEmpty ? text : out;
  }

  Future<OnDeviceTranslator> _translatorFor(
    TranslateLanguage source,
    TranslateLanguage target,
  ) async {
    final key = '${source.bcpCode}>${target.bcpCode}';
    final existing = _translators[key];
    if (existing != null) return existing;
    final t = OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );
    _translators[key] = t;
    return t;
  }

  void _putCache(String key, String value) {
    if (_cache.length >= _maxCacheEntries) {
      // Evict FIFO simple.
      final first = _cache.keys.first;
      _cache.remove(first);
    }
    _cache[key] = value;
  }

  /// Mapea códigos de la app / BCP-47 a [TranslateLanguage].
  TranslateLanguage resolveLanguage(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '-');
    final primary = normalized.split('-').first;

    const map = <String, TranslateLanguage>{
      'en': TranslateLanguage.english,
      'es': TranslateLanguage.spanish,
      'pt': TranslateLanguage.portuguese,
      'fr': TranslateLanguage.french,
      'de': TranslateLanguage.german,
      'it': TranslateLanguage.italian,
      'ru': TranslateLanguage.russian,
      'zh': TranslateLanguage.chinese,
      'ja': TranslateLanguage.japanese,
      'ko': TranslateLanguage.korean,
      'ar': TranslateLanguage.arabic,
      'hi': TranslateLanguage.hindi,
      'tr': TranslateLanguage.turkish,
      'nl': TranslateLanguage.dutch,
      'pl': TranslateLanguage.polish,
      'sv': TranslateLanguage.swedish,
      'da': TranslateLanguage.danish,
      'fi': TranslateLanguage.finnish,
      'no': TranslateLanguage.norwegian,
      'nb': TranslateLanguage.norwegian,
      'cs': TranslateLanguage.czech,
      'el': TranslateLanguage.greek,
      'he': TranslateLanguage.hebrew,
      'iw': TranslateLanguage.hebrew,
      'id': TranslateLanguage.indonesian,
      'in': TranslateLanguage.indonesian,
      'ms': TranslateLanguage.malay,
      'th': TranslateLanguage.thai,
      'vi': TranslateLanguage.vietnamese,
      'uk': TranslateLanguage.ukrainian,
      'ro': TranslateLanguage.romanian,
      'hu': TranslateLanguage.hungarian,
      'sk': TranslateLanguage.slovak,
      'bg': TranslateLanguage.bulgarian,
      'hr': TranslateLanguage.croatian,
      'ca': TranslateLanguage.catalan,
      'af': TranslateLanguage.afrikaans,
      'sq': TranslateLanguage.albanian,
      'be': TranslateLanguage.belarusian,
      'bn': TranslateLanguage.bengali,
      'tl': TranslateLanguage.tagalog,
      'fil': TranslateLanguage.tagalog,
    };

    return map[primary] ?? TranslateLanguage.english;
  }

  /// Libera traductores y el identificador de idioma.
  Future<void> dispose() async {
    for (final t in _translators.values) {
      await t.close();
    }
    _translators.clear();
    await _languageId.close();
    _cache.clear();
    _downloadedModels.clear();
    _preloadFuture = null;
    _isReady = false;
  }
}

// ---------------------------------------------------------------------------
// Helpers serializables para Isolate.run (Maps / primitivos)
// ---------------------------------------------------------------------------

List<Map<String, Object?>> _prepareTranslationJobs(
  List<Map<String, Object?>> messages, {
  required int? myUserId,
  required String targetBcp,
}) {
  final jobs = <Map<String, Object?>>[];
  for (final m in messages) {
    final id = m['id'] as int?;
    final userId = m['userId'] as int?;
    final alreadyTranslated = m['alreadyTranslated'] as bool? ?? false;
    if (id == null) continue;
    if (myUserId != null && userId == myUserId) continue;
    if (alreadyTranslated) continue;
    final text = ('${m['text'] ?? ''}').trim();
    if (text.isEmpty) continue;
    jobs.add({
      'id': id,
      'text': text,
      'cacheKey': '$id|$targetBcp|${text.hashCode}',
    });
  }
  return jobs;
}
