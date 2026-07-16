import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/user_extension.dart';
import 'package:krimson/common/manager/firebase_app_helper.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/common_service.dart';
import 'package:krimson/common/service/api/live_session_service.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/livestream/livestream.dart';
import 'package:krimson/model/livestream/livestream_user_state.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/screen/live_stream/livestream_screen/audience/live_stream_audience_screen.dart';
import 'package:krimson/screen/live_stream/livestream_screen/host/livestream_host_screen.dart';
import 'package:krimson/screen/live_stream/livestream_screen/widget/live_host_panel.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/firebase_const.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveStreamSearchScreenController extends BaseController {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final RxList<Livestream> livestreams = <Livestream>[].obs;
  final RxBool isBootstrapping = true.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  StreamSubscription<List<ConnectivityResult>>? _netSub;
  Timer? _laravelPoll;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final RxnString coverImageLocalPath = RxnString();
  final RxnString coverImageUploaded = RxnString();
  final Rxn<Uint8List> coverImageBytes = Rxn<Uint8List>();

  /// Preferencias pre-live (beauty / invite / red).
  final RxBool beautyOn = false.obs;
  final RxDouble whiten = 50.0.obs;
  final RxDouble rosy = 40.0.obs;
  final RxDouble smooth = 55.0.obs;
  final RxDouble sharpen = 35.0.obs;
  final RxString networkLabel = LKey.networkWifi.obs;
  final RxList<User> inviteCandidates = <User>[].obs;
  final RxSet<int> invitedIds = <int>{}.obs;
  final RxBool inviteLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _listenNetwork();
    _bootstrap();
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

  Future<void> _bootstrap() async {
    try {
      if (useFirebase) {
        final ok = await FirebaseAppHelper.ensureInitialized();
        if (!ok) {
          showSnackBar(
            'Firebase no disponible: ${FirebaseAppHelper.lastError ?? "init failed"}',
          );
        }
        if (FirebaseAppHelper.isReady) {
          await syncDummyLivesToFirestore();
        }
      }
      _listenActiveLives();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('core/no-app') || msg.contains('no-app')) {
        showSnackBar('Firebase no inicializado. Reinicia la app.');
      } else if (msg.toLowerCase().contains('not found')) {
        showSnackBar(
          'Firestore no creado. Firebase Console → Firestore → Create database.',
        );
      } else {
        showSnackBar(msg);
      }
    } finally {
      isBootstrapping.value = false;
    }
  }

  /// Publica en Firestore los dummy lives del admin para que aparezcan en la lista.
  Future<void> syncDummyLivesToFirestore() async {
    if (!useFirebase) return;
    if (!FirebaseAppHelper.isReady) return;
    final settings = SessionManager.instance.getSettings();
    if ((settings?.liveDummyShow ?? 0) != 1) return;

    final dummyLives = settings?.dummyLives ?? [];
    for (final dummy in dummyLives) {
      if ((dummy.status ?? 0) != 1 || dummy.userId == null) continue;
      final roomId = dummy.userId.toString();
      final stream = Livestream(
        description: (dummy.title ?? '').trim().isEmpty
            ? 'Live'
            : dummy.title!.trim(),
        isRestrictToJoin: 0,
        type: LivestreamType.dummy,
        watchingCount: 0,
        roomID: roomId,
        hostViewID: -1,
        likeCount: 0,
        coHostIds: [],
        hostId: dummy.userId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        battleType: BattleType.initiate,
        isDummyLive: 1,
        dummyUserLink: dummy.link ?? '',
      );
      await _db
          .collection(FirebaseConst.liveStreams)
          .doc(roomId)
          .set(stream.toJson(), SetOptions(merge: true));
    }
  }

  void _listenActiveLives() {
    if (!useFirebase) {
      _refreshLaravelLives();
      _laravelPoll?.cancel();
      _laravelPoll = Timer.periodic(const Duration(seconds: 5), (_) {
        _refreshLaravelLives(silent: true);
      });
      return;
    }

    if (!FirebaseAppHelper.isReady) {
      // Sin Firebase: muestra dummy lives locales desde settings.
      final settings = SessionManager.instance.getSettings();
      final list = <Livestream>[];
      if ((settings?.liveDummyShow ?? 0) == 1) {
        for (final dummy in settings?.dummyLives ?? <DummyLive>[]) {
          if ((dummy.status ?? 0) != 1) continue;
          list.add(Livestream(
            description: dummy.title ?? 'Live',
            isRestrictToJoin: 0,
            type: LivestreamType.dummy,
            watchingCount: 0,
            roomID: '${dummy.userId}',
            hostViewID: -1,
            likeCount: 0,
            coHostIds: [],
            hostId: dummy.userId,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            battleType: BattleType.initiate,
            isDummyLive: 1,
            dummyUserLink: dummy.link ?? '',
          ));
        }
      }
      livestreams.assignAll(list);
      return;
    }

    _sub?.cancel();
    _sub = _db.collection(FirebaseConst.liveStreams).snapshots().listen(
      (snap) {
        final items = snap.docs
            .map((d) {
              try {
                return Livestream.fromJson(_safeLiveJson(d.data()));
              } catch (_) {
                return null;
              }
            })
            .whereType<Livestream>()
            .where((e) => (e.roomID ?? '').isNotEmpty)
            .toList();
        items.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
        livestreams.assignAll(items);
      },
      onError: (e) => showSnackBar(e.toString()),
    );
  }

  Map<String, dynamic> _safeLiveJson(Map<String, dynamic> raw) {
    final data = Map<String, dynamic>.from(raw);
    data['co-host_ids'] ??= <dynamic>[];
    data['watching_count'] ??= 0;
    data['like_count'] ??= 0;
    data['is_dummy_live'] ??= 0;
    data['dummy_user_link'] ??= '';
    data['battle_duration'] ??= 5;
    data['type'] ??= LivestreamType.livestream.value;
    data['battle_type'] ??= BattleType.initiate.value;
    return data;
  }

  Future<void> refreshList() async {
    isBootstrapping.value = true;
    await _bootstrap();
  }

  void openLivestream(Livestream stream) {
    final me = SessionManager.instance.getUser();
    if (me == null) {
      showSnackBar(LKey.somethingWentWrong.tr);
      return;
    }
    if (stream.hostId == me.id) {
      Get.to(() => LivestreamHostScreen(isHost: true, livestream: stream));
    } else {
      Get.to(() => LiveStreamAudienceScreen(isHost: false, livestream: stream));
    }
  }

  Future<void> onTapGoLive() async {
    final user = SessionManager.instance.getUser();
    final settings = SessionManager.instance.getSettings();
    if (user == null) {
      showSnackBar(LKey.somethingWentWrong.tr);
      return;
    }

    // Perfil usado como dummy live en admin
    final dummyConflict = (settings?.dummyLives ?? []).any(
      (d) => d.userId == user.id && (d.status ?? 0) == 1,
    );
    if (dummyConflict) {
      showSnackBar(LKey.yourProfileIsAlreadyInUseForDummyEtc.tr);
      return;
    }

    if (kIsWeb) {
      // En Web no hay cámara LiveKit nativa; aún así permitimos abrir host en modo demo.
      showSnackBar(
        'Live publishing on Web is limited. Prefer Android/iOS for full camera.',
        second: 3,
      );
    }

    titleController.clear();
    invitedIds.clear();
    inviteCandidates.clear();
    final ok = await Get.bottomSheet<bool>(
      _StartLiveSheet(controller: this),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
    if (ok == true) {
      await _startLive(user);
    }
  }

  void openPreLiveBeauty() {
    openLiveBeautySheet(
      liveController: null,
      whiten: whiten,
      rosy: rosy,
      smooth: smooth,
      sharpen: sharpen,
      beautyOn: beautyOn,
      onApply: () async {},
    );
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
    );
  }

  Future<void> _loadInviteCandidates() async {
    if (inviteCandidates.isNotEmpty) return;
    inviteLoading.value = true;
    try {
      final meId = SessionManager.instance.getUserID();
      final following = await UserService.instance.fetchMyFollowing(
        lastItemId: -1,
        userId: meId,
      );
      inviteCandidates.assignAll(
        following.map((e) => e.toUser).whereType<User>().toList(),
      );
      if (inviteCandidates.isEmpty) {
        final followers = await UserService.instance.fetchMyFollowers(
          lastItemId: -1,
          userId: meId,
        );
        inviteCandidates.assignAll(
          followers.map((e) => e.fromUser).whereType<User>().toList(),
        );
      }
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      inviteLoading.value = false;
    }
  }

  Future<void> _refreshLaravelLives({bool silent = false}) async {
    try {
      final list = await LiveSessionService.instance.listActive();
      livestreams.assignAll(list);
    } catch (e) {
      if (!silent) {
        showSnackBar('Lives: $e');
      }
    }
  }

  Future<void> pickLiveCover() async {
    try {
      if (!kIsWeb) {
        // Android 13+: photos; antiguos: storage.
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

      // Copia a path estable: en Android FileImage a veces falla con el path temporal.
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

  Future<void> _startLive(User user) async {
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
          final invitee = inviteCandidates
              .firstWhereOrNull((u) => u.id == coHostId);
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

      // Token LiveKit se solicita al entrar en LivestreamHostScreen.
      stopLoader();
      Get.to(() => LivestreamHostScreen(
            isHost: true,
            livestream: stream,
            initialBeautyOn: beautyOn.value,
            initialWhiten: whiten.value,
            initialRosy: rosy.value,
            initialSmooth: smooth.value,
            initialSharpen: sharpen.value,
          ));
    } catch (e) {
      stopLoader();
      showSnackBar(e.toString());
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    _netSub?.cancel();
    _laravelPoll?.cancel();
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: whitePure(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: bgGrey(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  LKey.goLive.tr,
                  textAlign: TextAlign.center,
                  style: TextStyleCustom.unboundedSemiBold600(
                    color: textDarkGrey(context),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.titleController,
                  autofocus: true,
                  maxLength: 80,
                  decoration: InputDecoration(
                    hintText: LKey.enterLiveStreamTitle.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.descriptionController,
                  maxLength: 500,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Describe your live...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                        height: 140,
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
                                  Icon(Icons.add_photo_alternate_outlined,
                                      color: textLightGrey(context), size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add cover image',
                                    style: TextStyleCustom.outFitMedium500(
                                      color: textLightGrey(context),
                                      fontSize: 13,
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
                Obx(() {
                  if (controller.invitedIds.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(result: true),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
