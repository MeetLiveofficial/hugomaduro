import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/functions/media_picker_helper.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/widget/confirmation_dialog.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/screen/camera_edit_screen/camera_edit_screen.dart';
import 'package:krimson/screen/camera_screen/camera_screen.dart';
import 'package:krimson/screen/color_filter_screen/widget/color_filtered.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';
import 'package:krimson/screen/face_filters/services/baked_preview_capture.dart';
import 'package:krimson/screen/face_filters/services/deep_ar_service.dart';
import 'package:krimson/screen/face_filters/services/face_camera_service.dart';
import 'package:krimson/screen/face_filters/services/face_filter_catalog_store.dart';
import 'package:krimson/screen/face_filters/services/face_filter_pipeline.dart';
import 'package:krimson/screen/face_filters/services/face_mesh_engine.dart';
import 'package:krimson/screen/face_filters/widgets/beauty_camera_preview.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/music_sheet/music_sheet.dart';
import 'package:krimson/screen/selected_music_sheet/selected_music_sheet.dart';
import 'package:krimson/screen/selected_music_sheet/selected_music_sheet_controller.dart';
import 'package:krimson/utilities/app_res.dart';

class CameraScreenController extends BaseController
    with GetSingleTickerProviderStateMixin {
  static const _progressUpdateInterval = 10;

  RxList<int> secondsList = AppRes.secondList.obs;

  final CameraScreenType cameraType;
  final PlayerController audioPlayer = PlayerController();
  RxBool isSecondListShow = true.obs;

  RxInt selectedSecond = AppRes.secondList.first.obs;
  RxBool isTorchOn = false.obs;
  RxBool isRecording = false.obs;
  RxBool isStartingRecording = false.obs;
  RxBool isEffectShow = true.obs;
  Rx<SelectedMusic?> selectedMusic = Rx(null);
  RxDouble progress = 0.0.obs;
  RxBool isCameraReady = false.obs;
  final Rx<FaceFilterId> selectedFilterId = FaceFilterId.none.obs;
  final Rxn<int> selectedDeepArFilterId = Rxn<int>();

  final GlobalKey previewBoundaryKey = GlobalKey();
  final FaceFilterPipeline filterPipeline =
      FaceFilterPipeline(maxInferenceFps: 18);
  FaceCameraService get cameraService => filterPipeline.camera;
  FaceMeshEngine get meshEngine => filterPipeline.mesh;
  FaceFilterCatalogStore get filterCatalog => FaceFilterCatalogStore.instance;
  DeepArService get deepAr => DeepArService.instance;
  bool get useDeepAr => deepAr.isConfigured;

  bool get isCaptureReady => isCameraReady.value;
  CameraController? get cameraController => cameraService.controller;
  double get nativeAspectRatio => cameraService.nativeAspectRatio;

  Timer? _progressTimer;

  CameraScreenController(this.cameraType, this.selectedMusic);

  @override
  void onInit() {
    super.onInit();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    _initialize();
  }

  @override
  void onClose() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _cleanUpResources();
    super.onClose();
  }

  Future<void> _initialize() async {
    if (kIsWeb) return;
    await _initCameraPipeline();
    await _initData();
  }

  Future<void> _initData() async {
    if (cameraType == CameraScreenType.story) {
      selectedSecond.value = AppRes.storyVideoDuration;
    }
    await _initializeAudioIfNeeded();
  }

  Future<void> _initializeAudioIfNeeded() async {
    if (selectedMusic.value == null) return;
    try {
      await audioPlayer.preparePlayer(
          path: selectedMusic.value?.downloadedURL ?? '');
      final audioTotalDurationInMs = await audioPlayer.getDuration();
      final newSecondList = <int>[];
      final audioSecond = (audioTotalDurationInMs / 1000).toInt();
      for (final element in secondsList) {
        if (element <= audioSecond) newSecondList.add(element);
      }
      if (newSecondList.isNotEmpty) {
        secondsList.value = newSecondList;
        selectedSecond.value = secondsList.first;
      } else {
        showSnackBar(
            LKey.recordUpToSeconds.trParams({'second': '$audioSecond'}));
        selectedSecond.value = audioSecond;
        isSecondListShow.value = false;
      }
      final startAudioMs = selectedMusic.value?.audioStartMS ?? 0;
      if (isStartingRecording.value) {
        await audioPlayer
            .seekTo(startAudioMs + (progress.value * 1000).toInt());
      } else {
        await audioPlayer.seekTo(startAudioMs);
      }
    } catch (e) {
      Loggers.error('Audio initialization error: $e');
    }
  }

  Future<void> _initCameraPipeline() async {
    isCameraReady.value = false;
    if (useDeepAr) {
      try {
        final ok = await deepAr.initialize();
        isCameraReady.value = ok;
        if (!ok) {
          showSnackBar('No se pudo iniciar DeepAR');
        }
      } catch (e, st) {
        Loggers.error('DeepAR camera init: $e\n$st');
        isCameraReady.value = false;
        showSnackBar('Error DeepAR: $e');
      }
      return;
    }
    final granted = await cameraService.requestPermissions();
    if (!granted) {
      showPermissionDeniedSheet();
      return;
    }
    try {
      filterCatalog.sync();
      final ok = await filterPipeline.start(
        preferred: CameraLensDirection.front,
      );
      isCameraReady.value = ok;
      if (!ok) showSnackBar('No se pudo iniciar la cámara');
    } catch (e, st) {
      Loggers.error('Camera pipeline error: $e\n$st');
      isCameraReady.value = false;
      showSnackBar('Error al iniciar filtros faciales: $e');
    }
  }

  void _cleanUpResources() {
    _progressTimer?.cancel();
    disposeCamera();
    filterPipeline.beauty.dispose();
    audioPlayer.release();
    audioPlayer.dispose();
  }

  Future<void> disposeCamera() async {
    isCameraReady.value = false;
    await filterPipeline.stop();
    await deepAr.destroy();
  }

  void showPermissionDeniedSheet() {
    Get.bottomSheet(
      ConfirmationSheet(
        title: LKey.cameraMicrophonePermissionTitle.tr,
        description: LKey.cameraMicrophonePermissionDescription
            .trParams({'app_name': AppRes.appName}),
        onTap: openAppSettings,
        onClose: () => Get.back(),
        positiveText: LKey.openSetting.tr,
        isDismissible: true,
      ),
      enableDrag: false,
      isDismissible: false,
    );
  }

  Future<void> onMediaTap() async {
    try {
      switch (cameraType) {
        case CameraScreenType.post:
          final mediaFile = await MediaPickerHelper.shared
              .pickVideo(source: ImageSource.gallery);
          if (mediaFile != null) await _handleReel(mediaFile);
          break;
        case CameraScreenType.story:
          final mediaFile = await MediaPickerHelper.shared.pickMedia();
          if (mediaFile != null) {
            await (mediaFile.type == MediaType.image
                ? handleImageStory(mediaFile)
                : handleVideoStory(mediaFile));
          }
          break;
      }
    } catch (e) {
      Loggers.error('Media selection error: $e');
    }
  }

  Future<void> handleImageStory(MediaFile file) async {
    final imagePath = file.file.path;
    try {
      final bgColor = await imagePath.getGradientFromImage;
      await _navigateToEditScreen(
          PostStoryContentType.storyImage, imagePath, imagePath, bgColor);
    } catch (e) {
      Loggers.error('Gradient Error $e');
    }
  }

  Future<void> handleVideoStory(MediaFile file) async {
    final thumbnailPath = file.thumbNail.path;
    final videoPath = file.file.path;
    final bgColor = await thumbnailPath.getGradientFromImage;
    await _navigateToEditScreen(
        PostStoryContentType.storyVideo, videoPath, thumbnailPath, bgColor);
  }

  Future<void> _navigateToEditScreen(
    PostStoryContentType type,
    String contentPath,
    String thumbnailPath,
    LinearGradient bgColor,
  ) async {
    final content = PostStoryContent(
      type: type,
      content: contentPath,
      thumbNail: thumbnailPath,
      duration: AppRes.storyImageAndTextDuration,
      bgGradient: bgColor,
      sound: selectedMusic.value,
    );
    navigateCameraEditScreen(content);
  }

  Future<void> onToggleFlash() async {
    isTorchOn.toggle();
    await cameraService.setFlash(isTorchOn.value);
  }

  Future<void> onToggleCamera() async {
    if (isTorchOn.value) {
      isTorchOn.value = false;
      await cameraService.setFlash(false);
    }
    isCameraReady.value = false;
    await cameraService.switchCamera();
    isCameraReady.value = cameraService.isReady;
  }

  Future<void> onVideoRecordingStart() async {
    if (!isCaptureReady || isRecording.value) return;
    try {
      if (useDeepAr) {
        final ok = await deepAr.startVideoRecording();
        if (ok == null) throw Exception('DeepAR recording failed');
      } else {
        await cameraService.startVideoRecording();
      }
      _startAudioPlayback();
      isRecording.value = true;
      isStartingRecording.value = true;
      _startProgressTimer();
    } catch (e) {
      Loggers.error('Video recording start error: $e');
    }
  }

  Future<void> onVideoRecordingPause() async {
    if (!isRecording.value) return;
    if (useDeepAr) {
      // DeepAR plugin no expone pause; se detiene el timer UI solamente.
      _pauseAudioPlayback();
      isRecording.value = false;
      _progressTimer?.cancel();
      return;
    }
    await cameraService.pauseVideoRecording();
    _pauseAudioPlayback();
    isRecording.value = false;
    _progressTimer?.cancel();
  }

  Future<void> onVideoRecordingResume() async {
    if (isRecording.value) return;
    if (useDeepAr) {
      _resumeAudioPlayback();
      isRecording.value = true;
      _startProgressTimer();
      return;
    }
    await cameraService.resumeVideoRecording();
    _resumeAudioPlayback();
    isRecording.value = true;
    _startProgressTimer();
  }

  Future<void> onVideoRecordingStop() async {
    if (!isStartingRecording.value) return;
    try {
      _stopAudioPlayback();
      _progressTimer?.cancel();
      isRecording.value = false;
      isStartingRecording.value = false;
      progress.value = 0;

      showLoader();
      XFile? file;
      if (useDeepAr) {
        final path = await deepAr.stopVideoRecording();
        if (path != null) file = XFile(path);
      } else {
        file = await cameraService.stopVideoRecording();
      }
      if (file == null) {
        stopLoader();
        showSnackBar('Capture File not found');
        return;
      }
      final thumbnailPath =
          await MediaPickerHelper.shared.extractThumbnail(videoPath: file.path);
      final mediaFile = MediaFile(
          file: file, type: MediaType.video, thumbNail: thumbnailPath);
      stopLoader();

      switch (cameraType) {
        case CameraScreenType.post:
          await _handleReel(mediaFile, isCameraFile: true);
          break;
        case CameraScreenType.story:
          await handleVideoStory(mediaFile);
          break;
      }
      selectedMusic.value = null;
    } catch (e) {
      stopLoader();
      Loggers.error('Video recording stop error: $e');
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    final totalSteps = selectedSecond.value * (1000 ~/ _progressUpdateInterval);
    final increment = selectedSecond.value / totalSteps;
    _progressTimer = Timer.periodic(
      const Duration(milliseconds: _progressUpdateInterval),
      (timer) {
        if (progress.value < selectedSecond.value) {
          progress.value = (progress.value + increment)
              .clamp(0.0, selectedSecond.value.toDouble());
        } else {
          timer.cancel();
          onVideoRecordingStop();
        }
      },
    );
  }

  void _startAudioPlayback() {
    if (selectedMusic.value == null) return;
    audioPlayer.seekTo(selectedMusic.value?.audioStartMS ?? 0);
    audioPlayer.startPlayer();
  }

  void _pauseAudioPlayback() => audioPlayer.pausePlayer();
  void _resumeAudioPlayback() => audioPlayer.startPlayer();
  void _stopAudioPlayback() => audioPlayer.stopPlayer();

  void onPlayPauseToggle({int? type}) {
    if (cameraType == CameraScreenType.post) {
      _toggleReelRecording();
    } else {
      if (type != null) {
        if (type == 1) {
          onVideoRecordingStart();
        } else {
          onVideoRecordingStop();
        }
      } else {
        capturePhoto();
      }
    }
  }

  void _toggleReelRecording() {
    if (!isStartingRecording.value) {
      onVideoRecordingStart();
    } else if (isRecording.value) {
      onVideoRecordingPause();
    } else {
      onVideoRecordingResume();
    }
  }

  Future<void> capturePhoto() async {
    if (!isCaptureReady) {
      showSnackBar('Cámara aún no está lista');
      return;
    }
    if (isRecording.value) return;

    showLoader();
    try {
      XFile? file;
      if (useDeepAr) {
        final path = await deepAr.takeScreenshot();
        if (path != null) file = XFile(path);
      } else {
        if (selectedFilterId.value != FaceFilterId.none) {
          file = await captureRepaintBoundaryToFile(previewBoundaryKey);
        }
        file ??= await cameraService.takePicture();
      }
      if (file == null) {
        showSnackBar('No se pudo capturar la foto');
        return;
      }
      stopLoader();
      await handleImageStory(
          MediaFile(file: file, type: MediaType.image, thumbNail: file));
    } catch (e) {
      Loggers.error('Photo capture error: $e');
      showSnackBar('Error al capturar: $e');
    } finally {
      stopLoader();
    }
  }

  Future<void> _handleReel(MediaFile file, {bool isCameraFile = false}) async {
    showLoader();
    try {
      final content = PostStoryContent(
          type: PostStoryContentType.reel,
          content: file.file.path,
          thumbNail: file.thumbNail.path,
          sound: selectedMusic.value);
      stopLoader();
      navigateCameraEditScreen(content);
    } catch (e) {
      Loggers.error('Reel handling error: $e');
      stopLoader();
    }
  }

  Future<void> onMusicTap() async {
    final music = await Get.bottomSheet<SelectedMusic>(
        MusicSheet(videoDurationInSecond: selectedSecond.value),
        isScrollControlled: true,
        enableDrag: false,
        isDismissible: false);
    if (music != null) {
      selectedMusic.value = music;
      await _initializeAudioIfNeeded();
    }
  }

  void onSelectedMusicTap(SelectedMusic? music) async {
    if (music != null && !isStartingRecording.value) {
      final newMusic = await Get.bottomSheet<SelectedMusic>(
        SelectedMusicSheet(
            selectedMusic: music, totalVideoSecond: selectedSecond.value),
        isScrollControlled: true,
      );
      if (newMusic != null) {
        selectedMusic.value = newMusic;
        await _initializeAudioIfNeeded();
      }
    }
  }

  void onDeleteMusic() {
    selectedMusic.value = null;
    audioPlayer.stopPlayer();
  }

  void onEffectToggle() => isEffectShow.toggle();

  void onFilterSelected(FaceFilterId id) {
    selectedFilterId.value = id;
    final look = id.beautyLook;
    if (look == null) return;
    if (id.isBeautyGpu) {
      filterPipeline.beauty.setLook(
        BeautyLook(
          intensity: look.intensity.clamp(0.7, 1.0),
          mode: look.mode,
        ),
      );
    } else {
      filterPipeline.beauty.setLook(look);
    }
  }

  Future<void> onDeepArFilterSelected(DeepARFilters? filter) async {
    selectedDeepArFilterId.value = filter?.id;
    if (filter == null) {
      await deepAr.clearEffect();
    } else {
      await deepAr.applyFilter(filter);
    }
  }

  Future<void> onNavigateTextStory() async {
    final content = PostStoryContent(
      type: PostStoryContentType.storyText,
      content: '',
      thumbNail: '',
      duration: AppRes.storyImageAndTextDuration,
      sound: selectedMusic.value,
    );
    navigateCameraEditScreen(content);
  }

  Future<void> navigateCameraEditScreen(PostStoryContent content) async {
    await disposeCamera();
    await Get.to(() => CameraEditScreen(content: content));
    _resetAll();
  }

  void onBackFromScreen() {
    if (isStartingRecording.value || selectedMusic.value != null) {
      Get.bottomSheet(
        ConfirmationSheet(
            title: LKey.startAgainTitle.tr,
            description: LKey.startAgainMessage.tr,
            onTap: _resetAll,
            positiveText: LKey.startAgain.tr),
      );
    } else {
      Get.back();
    }
  }

  void _resetAll() {
    isEffectShow.value = true;
    selectedFilterId.value = FaceFilterId.none;
    filterPipeline.beauty.setLook(const BeautyLook(intensity: 0, mode: 0));
    progress.value = 0.0;
    selectedMusic.value = null;
    secondsList.value = AppRes.secondList;
    selectedSecond.value = secondsList.first;
    isSecondListShow.value = true;
    _progressTimer?.cancel();
    audioPlayer.release();
    isStartingRecording.value = false;
    _initCameraPipeline();
  }
}

enum PostStoryContentType { reel, storyText, storyImage, storyVideo }

class PostStoryContent {
  final PostStoryContentType type;
  String? content;
  String? thumbNail;
  int? duration;
  List<double> filter;
  bool hasAudio;
  SelectedMusic? sound;
  LinearGradient? bgGradient;
  Uint8List? thumbnailBytes;

  PostStoryContent(
      {required this.type,
      this.content,
      this.thumbNail,
      this.duration,
      this.filter = defaultFilter,
      this.sound,
      this.bgGradient,
      this.thumbnailBytes,
      this.hasAudio = true});
}
