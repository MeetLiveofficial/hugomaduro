import 'package:get/get.dart';
import 'package:krimson/model/general/settings_model.dart';

/// Stub Web: DeepAR no soporta Flutter Web.
class DeepArCameraController {
  final RxBool isReady = false.obs;
  final RxString statusMessage = 'DeepAR unavailable on web'.obs;
  final RxnInt selectedFilterId = RxnInt();

  dynamic get native => null;
  bool get isInitialized => false;
  bool get isRecording => false;

  Future<bool> initialize() async => false;

  Future<void> switchFilter(DeepARFilters? filter) async {}

  Future<void> clearEffect() async {}

  Future<void> flipCamera() async {}

  Future<dynamic> takeScreenshot() async => null;

  Future<void> startVideoRecording() async {}

  Future<dynamic> stopVideoRecording() async => null;

  Future<void> destroy() async {}
}
