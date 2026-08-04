import 'package:flutter/material.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/face_filters/services/deep_ar_service.dart';

DeepArService createDeepArService() => DeepArServiceStub.instance;

/// Web / platforms without DeepAR native SDK.
class DeepArServiceStub extends ChangeNotifier implements DeepArService {
  DeepArServiceStub._();
  static final DeepArServiceStub instance = DeepArServiceStub._();

  @override
  bool get isConfigured => false;

  @override
  bool get isInitialized => false;

  @override
  List<DeepARFilters> get filters => const [];

  @override
  int? get selectedFilterId => null;

  @override
  dynamic get controller => null;

  @override
  Future<bool> initialize() async => false;

  @override
  Future<void> applyFilter(DeepARFilters? filter) async {}

  @override
  Future<void> clearEffect() async {}

  @override
  Future<void> destroy() async {}

  @override
  void markPreviewReady() {}

  @override
  Widget buildPreview({VoidCallback? onViewCreated}) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Text(
          'DeepAR no disponible',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  @override
  Future<String?> startVideoRecording() async => null;

  @override
  Future<String?> stopVideoRecording() async => null;

  @override
  Future<String?> takeScreenshot() async => null;
}
