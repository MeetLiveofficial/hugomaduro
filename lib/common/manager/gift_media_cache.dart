import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/model/general/settings_model.dart';

/// Disk cache for gift GIFs/images so the Send Gifts sheet does not
/// re-download them on every open.
class GiftMediaCache {
  GiftMediaCache._();

  static const String _key = 'gift_media_cache_v1';

  static final CacheManager manager = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 250,
      repo: JsonCacheInfoRepository(databaseName: _key),
      fileService: HttpFileService(),
    ),
  );

  static final Set<String> _queued = {};

  static Future<void> precacheGifts(List<Gift>? gifts) async {
    if (gifts == null || gifts.isEmpty) return;

    for (final gift in gifts) {
      final path = gift.image;
      if (path == null || path.isEmpty) continue;
      final url = path.addBaseURL();
      if (url.isEmpty || _queued.contains(url)) continue;
      _queued.add(url);
      // Fire-and-forget per URL so one failure does not block the rest.
      // ignore: unawaited_futures
      _download(url);
    }
  }

  static Future<void> _download(String url) async {
    try {
      await manager.downloadFile(url, key: url);
      if (kDebugMode) {
        Loggers.info('Gift cached: $url');
      }
    } catch (e) {
      _queued.remove(url);
      Loggers.error('Gift cache failed ($url): $e');
    }
  }
}
