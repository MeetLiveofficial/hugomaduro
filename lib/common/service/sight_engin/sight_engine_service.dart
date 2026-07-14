import 'package:image_picker/image_picker.dart';

class SightEngineService {
  SightEngineService._();
  static final SightEngineService shared = SightEngineService._();

  Future<void> checkImagesInSightEngine({
    required List<XFile> xFiles,
    required void Function() completion,
  }) async {
    completion();
  }

  Future<void> chooseTextModeration({
    required String text,
    required void Function() completion,
  }) async {
    completion();
  }

  Future<void> checkVideoInSightEngine({
    required XFile xFile,
    required int duration,
    required void Function() completion,
  }) async {
    completion();
  }
}
