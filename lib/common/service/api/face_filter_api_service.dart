import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/model/filter/face_filter_models.dart';

/// API de catálogo de filtros faciales.
class FaceFilterApiService {
  FaceFilterApiService._();

  static final FaceFilterApiService instance = FaceFilterApiService._();

  Future<FaceFilterCatalogResponse> list({String? category}) {
    return ApiService.instance.call(
      url: WebService.filter.list,
      fromJson: FaceFilterCatalogResponse.fromJson,
      param: {
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
  }

  /// Sync incremental. Si [sinceVersion] es 0 → listado completo.
  Future<FaceFilterCatalogResponse> sync({
    int sinceVersion = 0,
    String? sinceIso,
  }) {
    return ApiService.instance.call(
      url: WebService.filter.sync,
      fromJson: FaceFilterCatalogResponse.fromJson,
      param: {
        'since_version': sinceVersion,
        if (sinceIso != null && sinceIso.isNotEmpty) 'since': sinceIso,
      },
    );
  }
}
