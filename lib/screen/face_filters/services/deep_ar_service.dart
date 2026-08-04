import 'package:flutter/material.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/face_filters/services/deep_ar_service_stub.dart'
    if (dart.library.io) 'package:krimson/screen/face_filters/services/deep_ar_service_io.dart'
    as impl;

/// Fachada DeepAR (IO real / stub en web). También es [Listenable].
abstract class DeepArService implements Listenable {
  static DeepArService get instance => impl.createDeepArService();

  /// Settings: is_deepAR=1 + license key de la plataforma.
  bool get isConfigured;

  bool get isInitialized;

  /// Lista del panel (`deepARFilters`).
  List<DeepARFilters> get filters;

  /// Id del filtro activo (null = none).
  int? get selectedFilterId;

  /// Controller nativo tipado en IO; en stub siempre null.
  dynamic get controller;

  Future<bool> initialize();

  Future<void> applyFilter(DeepARFilters? filter);

  Future<void> clearEffect();

  Future<void> destroy();

  /// iOS: llamar cuando el preview crea la vista nativa.
  void markPreviewReady() {}

  /// Preview nativo; en stub es un placeholder.
  Widget buildPreview({VoidCallback? onViewCreated});

  Future<String?> startVideoRecording();

  Future<String?> stopVideoRecording();

  Future<String?> takeScreenshot();
}
