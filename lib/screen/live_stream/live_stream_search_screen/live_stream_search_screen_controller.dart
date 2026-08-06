import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/user_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/common_service.dart';
import 'package:krimson/common/service/api/live_session_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/model/livestream/livestream_user_state.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/live_stream/livestream_screen/host/livestream_host_screen.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_host_panel.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/screen/deepar/deepar.dart';
import 'package:krimson/screen/face_filters/models/face_filter_effect.dart';
import 'package:krimson/screen/face_filters/services/face_filter_catalog_store.dart';
import 'package:krimson/screen/face_filters/services/face_filter_pipeline.dart';
import 'package:krimson/screen/face_filters/widgets/beauty_camera_preview.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/firebase_const.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:retrytech_plugin/retrytech_plugin.dart';

/// Pre-live: portada (imagen fija) + beauty con preview de cámara.
/// La portada NUNCA se reemplaza por el stream de cámara.
class LiveStreamSearchScreenController extends BaseController {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  StreamSubscription<List<ConnectivityResult>>? _netSub;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final RxString previewTitle = ''.obs;
  final RxnString coverImageLocalPath = RxnString();
  final RxnString coverImageUploaded = RxnString();
  final Rxn<Uint8List> coverImageBytes = Rxn<Uint8List>();

  final RxBool beautyOn = false.obs;
  final RxDouble whiten = 50.0.obs;
  final RxDouble rosy = 40.0.obs;
  final RxDouble smooth = 55.0.obs;
  final RxDouble sharpen = 35.0.obs;
  final RxString networkLabel = LKey.networkWifi.obs;
  final RxList<User> inviteCandidates = <User>[].obs;
  final RxSet<int> invitedIds = <int>{}.obs;
  final RxBool inviteLoading = false.obs;

  /// Preview de cómo te ves (filtros). Independiente de [coverImageBytes].
  final FaceFilterPipeline beautyPipeline =
      FaceFilterPipeline(maxInferenceFps: 15, defaultBeautyIntensity: 0);
  final DeepArCameraController deepAr = DeepArCameraController();
  final GlobalKey beautyPreviewKey = GlobalKey();
  final RxBool cameraPreviewActive = false.obs;
  final Rx<FaceFilterId> selectedFilterId = FaceFilterId.none.obs;

  FaceFilterCatalogStore get filterCatalog => FaceFilterCatalogStore.instance;
  bool get useDeepAr => DeepArRuntime.useDeepAr();

  @override
  void onInit() {
    super.onInit();
    titleController.addListener(() {
      previewTitle.value = titleController.text;
    });
    _listenNetwork();
    filterCatalog.sync();
    // Cámara + filtros visibles de entrada (sin sheet Beauty).
    if (!kIsWeb) {
      Future.microtask(() async {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
        ]);
        await startBeautyCameraPreview();
        await beautyPipeline.beauty.load();
        beautyOn.value = true;
        _syncBeautyShaderIntensity();
      });
    }
  }

  /// Tap en filtro MediaPipe (carrusel pre-live).
  Future<void> onPreLiveFilterTap(FaceFilterId id) async {
    await startBeautyCameraPreview();
    selectedFilterId.value = id;
    beautyOn.value = id != FaceFilterId.none;
    if (id == FaceFilterId.none) {
      beautyPipeline.beauty.setLook(const BeautyLook(intensity: 0, mode: 0));
      return;
    }
    _syncBeautyShaderIntensity();
  }

  /// Tap en filtro DeepAR (carrusel pre-live).
  Future<void> onPreLiveDeepArFilterTap(DeepARFilters? filter) async {
    await startBeautyCameraPreview();
    await onDeepArFilterSelected(filter);
  }

  Future<void> onDeepArFilterSelected(DeepARFilters? filter) async {
    await deepAr.switchFilter(filter);
    if (filter != null) {
      // DeepAR activo en preview. En LIVE el .deepar no va sobre LiveKit;
      // no forzar Soft+sliders altos (eso dejaba la cámara amarilla/oscura).
      beautyOn.value = false;
      selectedFilterId.value = FaceFilterId.none;
      whiten.value = 50;
      rosy.value = 40;
      smooth.value = 55;
      sharpen.value = 35;
    } else {
      selectedFilterId.value = FaceFilterId.none;
      beautyOn.value = false;
    }
    _syncBeautyShaderIntensity();
  }

  void _syncBeautyShaderIntensity() {
    final style = selectedFilterId.value;
    final preset = style.isBeautyGpu ? style.beautyLook : null;
    beautyPipeline.beauty.setLook(
      beautyLookFromSliders(
        enabled: beautyOn.value && style != FaceFilterId.none,
        presetMode: preset?.mode,
        presetIntensity: preset?.intensity ?? 0.75,
        whiten: whiten.value,
        rosy: rosy.value,
        smooth: smooth.value,
        sharpen: sharpen.value,
      ),
    );
  }

  Future<void> openPreLiveBeauty() async {
    // Compat: abre sheet solo-filtros (ya no hay Beauty Settings).
    await startBeautyCameraPreview();
    await beautyPipeline.beauty.load();
    _syncBeautyShaderIntensity();
    await openLiveFiltersSheet(
      beautyOn: beautyOn,
      onApply: () async => _syncBeautyShaderIntensity(),
      selectedFilterId: selectedFilterId,
      styleEffects: filterCatalog.effects.toList(),
      useDeepArFilters: useDeepAr,
      deepArSelectedId: deepAr.selectedFilterId,
      onDeepArStyleSelected: onDeepArFilterSelected,
      onStyleSelected: (id) {
        selectedFilterId.value = id;
        beautyOn.value = id != FaceFilterId.none;
        _syncBeautyShaderIntensity();
      },
    );
  }

  void _listenNetwork() {
    final connectivity = Connectivity();
    connectivity.checkConnectivity().then((r) {
      networkLabel.value = networkLabelFromResults(r);
    });
    _netSub = connectivity.onConnectivityChanged.listen((r) {
      networkLabel.value = networkLabelFromResults(r);
    });
  }

  /// Libera cámara nativa Retrytech si quedó abierta (p.ej. desde Create Reel).
  void releaseNativeCameraIfNeeded() {
    if (kIsWeb) return;
    try {
      RetrytechPlugin.shared.disposeCamera;
    } catch (_) {}
  }

  Future<void> editPreLiveTitle() async {
    final draft = TextEditingController(text: titleController.text);
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(LKey.enterLiveStreamTitle.tr),
        content: TextField(
          controller: draft,
          autofocus: true,
          maxLength: 80,
          decoration: InputDecoration(
            hintText: LKey.enterLiveStreamTitle.tr,
            counterText: '',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(LKey.cancel.tr)),
          TextButton(onPressed: () => Get.back(result: true), child: Text(LKey.done.tr)),
        ],
      ),
    );
    if (ok == true) {
      titleController.text = draft.text.trim();
      previewTitle.value = titleController.text;
    }
    draft.dispose();
  }

  Future<void> onTapGoLive() async {
    final user = SessionManager.instance.getUser();
    final settings = SessionManager.instance.getSettings();
    if (user == null) {
      showSnackBar(LKey.somethingWentWrong.tr);
      return;
    }

    final canGoLive = AppRole.canStartLive(user);
    if (!canGoLive) {
      showSnackBar(
        AppRole.isClient(user)
            ? 'Los clientes no pueden iniciar LIVE.'
            : LKey.liveLockedUntilLevel.tr,
        second: 4,
      );
      return;
    }

    final dummyConflict = (settings?.dummyLives ?? []).any(
      (d) => d.userId == user.id && (d.status ?? 0) == 1,
    );
    if (dummyConflict) {
      showSnackBar(LKey.yourProfileIsAlreadyInUseForDummyEtc.tr);
      return;
    }

    invitedIds.clear();
    inviteCandidates.clear();
    final ok = await Get.bottomSheet<bool>(
      _StartLiveSheet(controller: this),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      enableDrag: true,
      ignoreSafeArea: false,
    );
    if (ok == true) {
      // Snapshot ANTES de destroy: DeepAR.clear selecciona null al liberar cámara.
      final hasDeepAr = deepAr.selectedFilterId.value != null;
      final snapDeepArId = deepAr.selectedFilterId.value;
      // Si había DeepAR: no sustituir por beauty Soft (rompe el look).
      // El ID se rehidrata en LIVE para el carrusel DeepAR.
      final snapBeautyOn = !hasDeepAr &&
          (beautyOn.value || selectedFilterId.value != FaceFilterId.none);
      final snapWhiten = whiten.value;
      final snapRosy = rosy.value;
      final snapSmooth = smooth.value;
      final snapSharpen = sharpen.value;
      final snapFilter = hasDeepAr
          ? FaceFilterId.none
          : selectedFilterId.value;

      // Liberar preview beauty + cámara nativa antes de LiveKit.
      await stopBeautyCameraPreview();
      releaseNativeCameraIfNeeded();
      await Future.delayed(const Duration(milliseconds: 250));
      await _startLive(
        user,
        beautyOn: snapBeautyOn,
        whiten: snapWhiten,
        rosy: snapRosy,
        smooth: snapSmooth,
        sharpen: snapSharpen,
        filterId: snapFilter,
        deepArFilterId: snapDeepArId,
      );
    }
  }

  Future<void> startBeautyCameraPreview() async {
    if (kIsWeb) return;
    if (useDeepAr) {
      if (cameraPreviewActive.value && deepAr.isReady.value) return;
      try {
        await beautyPipeline.stop();
        final ok = await deepAr.initialize();
        cameraPreviewActive.value = ok;
        if (!ok) {
          showSnackBar(deepAr.statusMessage.value.isEmpty
              ? 'No se pudo abrir DeepAR'
              : deepAr.statusMessage.value);
        }
      } catch (e, st) {
        Loggers.error('startBeautyCameraPreview DeepAR: $e\n$st');
        cameraPreviewActive.value = false;
        showSnackBar('Error DeepAR: $e');
      }
      return;
    }

    if (cameraPreviewActive.value && beautyPipeline.isReady) return;
    final cam = await Permission.camera.request();
    if (!cam.isGranted) {
      showSnackBar(LKey.cameraMicrophonePermissionTitle.tr);
      return;
    }
    try {
      await deepAr.destroy();
      filterCatalog.sync();
      final ok = await beautyPipeline.start();
      cameraPreviewActive.value = ok;
      if (ok) _syncBeautyShaderIntensity();
      if (!ok) {
        showSnackBar('No se pudo abrir la cámara para el preview');
      }
    } catch (e, st) {
      Loggers.error('startBeautyCameraPreview: $e\n$st');
      cameraPreviewActive.value = false;
      showSnackBar('Error al abrir cámara: $e');
    }
  }

  Future<void> stopBeautyCameraPreview() async {
    cameraPreviewActive.value = false;
    try {
      await beautyPipeline.stop();
      await deepAr.destroy();
    } catch (e) {
      Loggers.error('stopBeautyCameraPreview: $e');
    }
  }

  Future<void> openPreLiveInvite() async {
    await _loadInviteCandidates();
    openLiveInviteSheet(
      candidates: inviteCandidates,
      loading: inviteLoading,
      selectedIds: invitedIds,
      onInvite: (user) async {
        final id = user.id;
        if (id == null) return;
        invitedIds.add(id);
        inviteCandidates.refresh();
        showSnackBar(LKey.friendInvited.tr);
      },
      onSearch: _searchInviteCandidates,
    );
  }

  Future<void> _searchInviteCandidates(String keyword) async {
    inviteLoading.value = true;
    try {
      final users = await UserService.instance.searchUsers(
        keyWord: keyword,
        limit: 40,
      );
      inviteCandidates.assignAll(users);
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      inviteLoading.value = false;
    }
  }

  Future<void> _loadInviteCandidates() async {
    inviteLoading.value = true;
    try {
      final users = await UserService.instance.searchUsers(
        keyWord: '',
        limit: 40,
      );
      inviteCandidates.assignAll(users);
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      inviteLoading.value = false;
    }
  }

  Future<void> pickLiveCover() async {
    try {
      if (!kIsWeb) {
        final photos = await Permission.photos.request();
        if (!photos.isGranted && !photos.isLimited) {
          final storage = await Permission.storage.request();
          if (!storage.isGranted) {
            showSnackBar(LKey.enablePhotoAccessTitle.tr);
            return;
          }
        }
      }

      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (file == null) {
        showSnackBar('No se seleccionó imagen');
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        showSnackBar('Imagen inválida');
        return;
      }

      String stablePath = file.path;
      if (!kIsWeb) {
        final dir = await PlatformPathExtension.localPath;
        stablePath =
            '${dir}live_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(stablePath).writeAsBytes(bytes, flush: true);
      }

      coverImageBytes.value = bytes;
      coverImageLocalPath.value = stablePath;
      coverImageUploaded.value = null;
      Loggers.info('Live cover selected: $stablePath (${bytes.length} bytes)');
    } catch (e) {
      Loggers.error('pickLiveCover: $e');
      showSnackBar('Error al elegir imagen: $e');
    }
  }

  void clearLiveCover() {
    coverImageBytes.value = null;
    coverImageLocalPath.value = null;
    coverImageUploaded.value = null;
  }

  Future<void> _startLive(
    User user, {
    required bool beautyOn,
    required double whiten,
    required double rosy,
    required double smooth,
    required double sharpen,
    required FaceFilterId filterId,
    int? deepArFilterId,
  }) async {
    final title = titleController.text.trim();
    final details = descriptionController.text.trim();
    if (title.isEmpty) {
      showSnackBar(LKey.enterLiveStreamTitle.tr);
      return;
    }

    final description = details.isEmpty ? title : '$title\n$details';

    showLoader();
    try {
      String? coverPath = coverImageUploaded.value;
      final localCover = coverImageLocalPath.value;
      final bytes = coverImageBytes.value;
      if (coverPath == null &&
          ((localCover ?? '').isNotEmpty || (bytes?.isNotEmpty ?? false))) {
        try {
          XFile uploadFile;
          if ((localCover ?? '').isNotEmpty &&
              !kIsWeb &&
              File(localCover!).existsSync()) {
            uploadFile = XFile(localCover);
          } else if (bytes != null && bytes.isNotEmpty) {
            final dir = await PlatformPathExtension.localPath;
            final path =
                '${dir}live_cover_upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
            await File(path).writeAsBytes(bytes, flush: true);
            uploadFile = XFile(path);
            coverImageLocalPath.value = path;
          } else {
            throw Exception('Archivo de portada no encontrado');
          }
          final uploaded =
              await CommonService.instance.uploadFileGivePath(uploadFile);
          if (uploaded.status != true ||
              (uploaded.data == null || uploaded.data!.isEmpty)) {
            throw Exception(uploaded.message ?? 'Upload de portada falló');
          }
          coverPath = uploaded.data;
          coverImageUploaded.value = coverPath;
        } catch (e) {
          stopLoader();
          showSnackBar('No se pudo subir la portada: $e');
          return;
        }
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final coHosts = invitedIds.toList();
      Livestream stream;

      if (!useFirebase) {
        stream = await LiveSessionService.instance.start(
          description: description,
          coverImage: coverPath,
          coHostIds: coHosts,
          isRestrictToJoin: 0,
        );
      } else {
        stream = user.livestream(
          type: LivestreamType.livestream,
          time: now,
          description: description,
          restrictToJoin: 0,
          isDummyLive: 0,
          coHostIds: coHosts,
        );
        final hostState = user.streamState(
          stateType: LivestreamUserType.host,
          time: now,
        )..user = user.appUser;

        final roomRef =
            _db.collection(FirebaseConst.liveStreams).doc(stream.roomID);
        await roomRef.set(stream.toJson());
        await roomRef
            .collection(FirebaseConst.userState)
            .doc('${user.id}')
            .set(hostState.toJson());

        for (final coHostId in coHosts) {
          final invitee =
              inviteCandidates.firstWhereOrNull((u) => u.id == coHostId);
          final state = LivestreamUserState(
            type: LivestreamUserType.invited,
            userId: coHostId,
            liveCoin: 0,
            currentBattleCoin: 0,
            totalBattleCoin: 0,
            followersGained: [],
            joinStreamTime: now,
            user: invitee?.appUser,
          );
          await roomRef
              .collection(FirebaseConst.userState)
              .doc('$coHostId')
              .set(state.toJson(), SetOptions(merge: true));
        }
      }

      stopLoader();
      await Get.to(() => LivestreamHostScreen(
            isHost: true,
            livestream: stream,
            initialBeautyOn: beautyOn,
            initialWhiten: whiten,
            initialRosy: rosy,
            initialSmooth: smooth,
            initialSharpen: sharpen,
            initialBeautyFilterId: filterId,
            initialDeepArFilterId: deepArFilterId,
          ));
    } catch (e) {
      stopLoader();
      showSnackBar(e.toString());
    }
  }

  @override
  void onClose() {
    _netSub?.cancel();
    stopBeautyCameraPreview();
    beautyPipeline.beauty.dispose();
    deepAr.destroy();
    releaseNativeCameraIfNeeded();
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}

class _StartLiveSheet extends StatelessWidget {
  final LiveStreamSearchScreenController controller;

  const _StartLiveSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final keyboardOpen = keyboard > 0;
    // Compacto al contenido; con teclado limita altura y hace scroll.
    final available =
        (media.size.height - keyboard).clamp(260.0, media.size.height);
    final maxWithKeyboard = (available * 0.88).clamp(260.0, available);

    final formBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller.titleController,
          autofocus: true,
          maxLength: 80,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: LKey.enterLiveStreamTitle.tr,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.descriptionController,
          maxLength: 500,
          maxLines: keyboardOpen ? 2 : 2,
          minLines: 1,
          decoration: InputDecoration(
            hintText: 'Describe your live...',
            isDense: true,
            alignLabelWithHint: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (!keyboardOpen) ...[
          const SizedBox(height: 10),
          Obx(() {
            final bytes = controller.coverImageBytes.value;
            final hasCover = bytes != null && bytes.isNotEmpty;
            return Material(
              color: bgGrey(context),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: controller.pickLiveCover,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 88,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasCover)
                        Image.memory(
                          bytes,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      else
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: textLightGrey(context),
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add cover image',
                              style: TextStyleCustom.outFitMedium500(
                                color: textLightGrey(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      if (hasCover)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: controller.clearLiveCover,
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ] else ...[
          const SizedBox(height: 6),
          Text(
            'Cierra el teclado para elegir portada',
            textAlign: TextAlign.center,
            style: TextStyleCustom.outFitRegular400(
              color: textLightGrey(context),
              fontSize: 12,
            ),
          ),
        ],
        Obx(() {
          if (controller.invitedIds.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${LKey.invited.tr}: ${controller.invitedIds.length}',
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitMedium500(
                color: themeAccentSolid(context),
                fontSize: 13,
              ),
            ),
          );
        }),
      ],
    );

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: bgGrey(context),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            LKey.goLive.tr,
            textAlign: TextAlign.center,
            style: TextStyleCustom.unboundedSemiBold600(
              color: textDarkGrey(context),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );

    final startButton = Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Get.back(result: true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor(context),
            foregroundColor: whitePure(context),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(LKey.startLive.tr),
        ),
      ),
    );

    final sheetBody = SafeArea(
      top: false,
      child: keyboardOpen
          ? SizedBox(
              height: maxWithKeyboard,
              child: Column(
                children: [
                  header,
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: formBody,
                    ),
                  ),
                  startButton,
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: formBody,
                ),
                startButton,
              ],
            ),
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: whitePure(context),
          elevation: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: available * 0.92),
            child: sheetBody,
          ),
        ),
      ),
    );
  }
}
