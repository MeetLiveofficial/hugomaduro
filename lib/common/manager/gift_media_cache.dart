import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/model/general/settings_model.dart';

/// Disk cache for gift GIFs/images so the Send Gifts sheet does not
/// re-download them on every open.
///
/// En Web NO se instancia CacheManager: usa path_provider y provoca
/// MissingPluginException en bucle (pantalla en blanco).
class GiftMediaCache {
  GiftMediaCache._();

  static const String _key = 'gift_media_cache_v1';

  static CacheManager? _manager;
  static final Set<String> _queued = {};

  /// Null en Web. Usar solo en nativo.
  static CacheManager? get manager {
    if (kIsWeb) return null;
    return _manager ??= CacheManager(
      Config(
        _key,
        stalePeriod: const Duration(days: 30),
        maxNrOfCacheObjects: 250,
        repo: JsonCacheInfoRepository(databaseName: _key),
        fileService: HttpFileService(),
      ),
    );
  }

  static Future<void> precacheGifts(List<Gift>? gifts) async {
    if (kIsWeb) return;
    if (gifts == null || gifts.isEmpty) return;
    final cache = manager;
    if (cache == null) return;

    for (final gift in gifts) {
      final path = gift.image;
      if (path == null || path.isEmpty) continue;
      final url = path.addBaseURL();
      if (url.isEmpty || _queued.contains(url)) continue;
      _queued.add(url);
      // ignore: unawaited_futures
      _download(cache, url);
    }
  }

  static Future<void> _download(CacheManager cache, String url) async {
    try {
      await cache.downloadFile(url, key: url);
      if (kDebugMode) {
        Loggers.info('Gift cached: $url');
      }
    } catch (e) {
      _queued.remove(url);
      Loggers.error('Gift cache failed ($url): $e');
    }
  }
}
