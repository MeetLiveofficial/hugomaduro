import 'package:flutter/material.dart';

class FaceFilterCatalogResponse {
  final bool status;
  final String? message;
  final FaceFilterCatalogData? data;

  FaceFilterCatalogResponse({this.status = false, this.message, this.data});

  factory FaceFilterCatalogResponse.fromJson(Map<String, dynamic> json) {
    return FaceFilterCatalogResponse(
      status: json['status'] == true,
      message: json['message']?.toString(),
      data: json['data'] is Map
          ? FaceFilterCatalogData.fromJson(
              Map<String, dynamic>.from(json['data']))
          : null,
    );
  }
}

class FaceFilterCatalogData {
  final String itemBaseUrl;
  final int catalogVersion;
  final String? syncedAt;
  final bool hasChanges;
  final List<RemoteFilterCategory> categories;
  final List<RemoteFaceFilter> uncategorized;
  final List<RemoteFaceFilter> upserts;
  final List<String> removedCodes;

  FaceFilterCatalogData({
    required this.itemBaseUrl,
    required this.catalogVersion,
    this.syncedAt,
    this.hasChanges = true,
    this.categories = const [],
    this.uncategorized = const [],
    this.upserts = const [],
    this.removedCodes = const [],
  });

  factory FaceFilterCatalogData.fromJson(Map<String, dynamic> json) {
    return FaceFilterCatalogData(
      itemBaseUrl: json['item_base_url']?.toString() ?? '',
      catalogVersion: _asInt(json['catalog_version']),
      syncedAt: json['synced_at']?.toString(),
      hasChanges: json['has_changes'] != false,
      categories: (json['categories'] as List? ?? [])
          .whereType<Map>()
          .map((e) =>
              RemoteFilterCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      uncategorized: (json['uncategorized'] as List? ?? [])
          .whereType<Map>()
          .map((e) => RemoteFaceFilter.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      upserts: (json['upserts'] as List? ?? [])
          .whereType<Map>()
          .map((e) => RemoteFaceFilter.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      removedCodes: (json['removed_codes'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  List<RemoteFaceFilter> get allFilters {
    final out = <RemoteFaceFilter>[...uncategorized];
    for (final c in categories) {
      out.addAll(c.filters);
    }
    out.addAll(upserts);
    return out;
  }
}

class RemoteFilterCategory {
  final int id;
  final String code;
  final String name;
  final String? iconUrl;
  final int sortOrder;
  final List<RemoteFaceFilter> filters;

  RemoteFilterCategory({
    required this.id,
    required this.code,
    required this.name,
    this.iconUrl,
    this.sortOrder = 0,
    this.filters = const [],
  });

  factory RemoteFilterCategory.fromJson(Map<String, dynamic> json) {
    return RemoteFilterCategory(
      id: _asInt(json['id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconUrl: json['icon_url']?.toString(),
      sortOrder: _asInt(json['sort_order']),
      filters: (json['filters'] as List? ?? [])
          .whereType<Map>()
          .map((e) => RemoteFaceFilter.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'icon_url': iconUrl,
        'sort_order': sortOrder,
        'filters': filters.map((e) => e.toJson()).toList(),
      };
}

class RemoteFaceFilter {
  final int id;
  final int? categoryId;
  final String? categoryCode;
  final String code;
  final String title;
  final String? description;
  final String? iconUrl;
  final String? assetUrl;
  final String effectType;
  final String? accentColor;
  final bool isPremium;
  final bool isFree;
  final int coinPrice;
  final int sortOrder;
  final int version;
  final Map<String, dynamic> metadata;

  RemoteFaceFilter({
    required this.id,
    this.categoryId,
    this.categoryCode,
    required this.code,
    required this.title,
    this.description,
    this.iconUrl,
    this.assetUrl,
    this.effectType = 'builtin',
    this.accentColor,
    this.isPremium = false,
    this.isFree = true,
    this.coinPrice = 0,
    this.sortOrder = 0,
    this.version = 1,
    this.metadata = const {},
  });

  factory RemoteFaceFilter.fromJson(Map<String, dynamic> json) {
    final premium = json['is_premium'] == true || json['is_premium'] == 1;
    return RemoteFaceFilter(
      id: _asInt(json['id']),
      categoryId:
          json['category_id'] == null ? null : _asInt(json['category_id']),
      categoryCode: json['category_code']?.toString(),
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      iconUrl: json['icon_url']?.toString(),
      assetUrl: json['asset_url']?.toString(),
      effectType: json['effect_type']?.toString() ?? 'builtin',
      accentColor: json['accent_color']?.toString(),
      isPremium: premium,
      isFree: json['is_free'] == true || !premium,
      coinPrice: _asInt(json['coin_price']),
      sortOrder: _asInt(json['sort_order']),
      version: _asInt(json['version'], fallback: 1),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'category_code': categoryCode,
        'code': code,
        'title': title,
        'description': description,
        'icon_url': iconUrl,
        'asset_url': assetUrl,
        'effect_type': effectType,
        'accent_color': accentColor,
        'is_premium': isPremium,
        'is_free': isFree,
        'coin_price': coinPrice,
        'sort_order': sortOrder,
        'version': version,
        'metadata': metadata,
      };

  Color parseAccent({Color fallback = const Color(0xFF9E9E9E)}) {
    final hex = accentColor;
    if (hex == null || hex.isEmpty) return fallback;
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    try {
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}

int _asInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}
