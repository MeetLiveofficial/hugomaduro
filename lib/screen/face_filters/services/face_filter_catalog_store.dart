import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/service/api/face_filter_api_service.dart';
import 'package:krimson/model/filter/face_filter_models.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';

/// Cache local + sync del catálogo remoto.
/// Fusiona con efectos builtin para que el painter siempre tenga fallback offline.
class FaceFilterCatalogStore extends GetxController {
  static FaceFilterCatalogStore get instance {
    if (Get.isRegistered<FaceFilterCatalogStore>()) {
      return Get.find<FaceFilterCatalogStore>();
    }
    return Get.put(FaceFilterCatalogStore(), permanent: true);
  }

  static const _storageBox = 'krimson';
  static const _keyCatalog = 'face_filters_catalog_v2';
  static const _keyVersion = 'face_filters_catalog_version_v2';
  static const _keySyncedAt = 'face_filters_synced_at_v2';

  final RxList<FaceFilterEffect> effects = <FaceFilterEffect>[].obs;
  final RxList<RemoteFilterCategory> categories = <RemoteFilterCategory>[].obs;
  final RxInt catalogVersion = 0.obs;
  final RxBool isSyncing = false.obs;

  final _storage = GetStorage(_storageBox);

  @override
  void onInit() {
    super.onInit();
    _loadCacheOrBuiltin();
  }

  void _loadCacheOrBuiltin() {
    catalogVersion.value = _storage.read(_keyVersion) ?? 0;
    final raw = _storage.read(_keyCatalog);
    if (raw is String && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final data = FaceFilterCatalogData.fromJson(map);
        _applyFullCatalog(data);
        return;
      } catch (e) {
        Loggers.error('FaceFilterCatalogStore cache parse: $e');
      }
    }
    effects.assignAll(FaceFilterEffect.catalog);
  }

  /// Sync en background. Seguro llamar al abrir cámara / live.
  Future<void> sync({bool forceFull = false}) async {
    if (isSyncing.value) return;
    isSyncing.value = true;
    try {
      final since = forceFull ? 0 : catalogVersion.value;
      final res = await FaceFilterApiService.instance.sync(sinceVersion: since);
      if (res.status != true || res.data == null) {
        Loggers.error('FaceFilter sync failed: ${res.message}');
        return;
      }
      final data = res.data!;
      if (since <= 0 || data.upserts.isEmpty && data.categories.isNotEmpty) {
        // Respuesta tipo list completa
        if (data.categories.isNotEmpty || data.uncategorized.isNotEmpty) {
          _applyFullCatalog(data);
          _persistFull(data);
        }
      } else if (data.hasChanges) {
        _applyIncremental(data);
      }
      catalogVersion.value = data.catalogVersion;
      _storage.write(_keyVersion, data.catalogVersion);
      if (data.syncedAt != null) {
        _storage.write(_keySyncedAt, data.syncedAt);
      }
    } catch (e, st) {
      Loggers.error('FaceFilterCatalogStore.sync: $e\n$st');
    } finally {
      isSyncing.value = false;
    }
  }

  void _applyFullCatalog(FaceFilterCatalogData data) {
    categories.assignAll(data.categories);
    final remoteByCode = <String, RemoteFaceFilter>{};
    for (final f in data.allFilters) {
      remoteByCode[f.code] = f;
    }

    final merged = <FaceFilterEffect>[];
    // Mantener orden del builtin; enriquecer con remoto.
    for (final local in FaceFilterEffect.catalog) {
      final remote = remoteByCode.remove(local.id.code);
      merged.add(remote?.toEffect() ?? local);
    }
    // Remotos desconocidos (futuros effect_type asset) se omiten del painter
    // hasta tener renderer; se pueden listar en UI premium.
    for (final leftover in remoteByCode.values) {
      if (leftover.localEffectId != null) {
        merged.add(leftover.toEffect());
      }
    }
    merged.sort((a, b) {
      final ao = a.remote?.sortOrder ?? a.id.index;
      final bo = b.remote?.sortOrder ?? b.id.index;
      return ao.compareTo(bo);
    });
    effects.assignAll(merged);
  }

  void _applyIncremental(FaceFilterCatalogData data) {
    final byCode = {
      for (final e in effects) e.id.code: e,
    };
    for (final code in data.removedCodes) {
      byCode.remove(code);
    }
    for (final upsert in data.upserts) {
      byCode[upsert.code] = upsert.toEffect();
    }
    if (data.categories.isNotEmpty) {
      categories.assignAll(data.categories);
    }
    final list = byCode.values.toList()
      ..sort((a, b) {
        final ao = a.remote?.sortOrder ?? 0;
        final bo = b.remote?.sortOrder ?? 0;
        return ao.compareTo(bo);
      });
    effects.assignAll(list);
    _persistMerged();
  }

  void _persistFull(FaceFilterCatalogData data) {
    _storage.write(
      _keyCatalog,
      jsonEncode({
        'item_base_url': data.itemBaseUrl,
        'catalog_version': data.catalogVersion,
        'synced_at': data.syncedAt,
        'categories': data.categories.map((c) => c.toJson()).toList(),
        'uncategorized': data.uncategorized.map((f) => f.toJson()).toList(),
      }),
    );
  }

  void _persistMerged() {
    final cats = categories.toList();
    final uncategorized = effects
        .where((e) => e.remote != null && e.remote!.categoryId == null)
        .map((e) => e.remote!)
        .toList();
    _storage.write(
      _keyCatalog,
      jsonEncode({
        'item_base_url': '',
        'catalog_version': catalogVersion.value,
        'categories': cats.map((c) {
          final codes = c.filters.map((f) => f.code).toSet();
          final filters = effects
              .where((e) => e.remote != null && codes.contains(e.id.code))
              .map((e) => e.remote!.toJson())
              .toList();
          return {...c.toJson(), 'filters': filters};
        }).toList(),
        'uncategorized': uncategorized.map((f) => f.toJson()).toList(),
      }),
    );
  }
}
