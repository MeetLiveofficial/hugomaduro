import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/functions/debounce_action.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/post_service.dart';
import 'package:krimson/model/post_story/comment/fetch_comment_model.dart';
import 'package:krimson/model/post_story/post_model.dart';
import 'package:krimson/screen/comment_sheet/helper/comment_helper.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/screen/profile_screen/profile_screen_controller.dart';
import 'package:krimson/screen/profile_screen/widget/post_options_sheet.dart';
import 'package:krimson/screen/reels_screen/reel/reel_page_controller.dart';
import 'package:krimson/screen/reels_screen/widget/reel_page_type.dart';
import 'package:krimson/screen/report_sheet/report_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Condicional: File solo en móvil (web no soporta dart:io).
import 'reels_io_stub.dart'
    if (dart.library.io) 'reels_io_io.dart' as reels_io;

class ReelsScreenController extends BaseController {
  RxMap<int, ReelPlayerEntry> players = <int, ReelPlayerEntry>{}.obs;

  /// Debe coincidir con [ReelPageType.home.withId] → `home`.
  static const String tag = 'home';
  RxInt position = 0.obs;

  PageController pageController = PageController();

  RxList<Post> reels;
  Future<void> Function()? onFetchMoreData;

  final RxBool isRefreshing = false.obs;
  CommentHelper commentHelper = CommentHelper();
  bool isCurrentPageVisible = true;
  bool _playersHidden = false;

  ReelPageType reelPageType;

  ReelsScreenController(
      {required this.reels,
      required this.position,
      this.onFetchMoreData,
      required this.reelPageType});

  void controllerAlreadyInitialize(
      {required RxList<Post> reels,
      required RxInt position,
      Future<void> Function()? onFetchMoreData,
      required ReelPageType reelPageType}) {
    this.reels = reels;
    this.position = position;
    this.onFetchMoreData = onFetchMoreData;
    this.reelPageType = reelPageType;
    pageController = PageController(initialPage: position.value);
    players.clear();
  }

  @override
  void onInit() {
    super.onInit();
    WakelockPlus.enable();
  }

  @override
  void onClose() {
    super.onClose();
    pageController.dispose();
    WakelockPlus.disable();
    disposeAllController();
  }

  Future<void> initVideoPlayer() async {
    await _initializeControllerAtIndex(position.value);
    _playControllerAtIndex(position.value);
    // Solo precargar el siguiente (menos texturas = menos artefactos GPU).
    await _initializeControllerAtIndex(position.value + 1);
  }

  /// Al volver al tab: recrear players limpios.
  Future<void> rebindPlayersOnVisible() async {
    if (!_playersHidden &&
        players.values.any((e) => e.status == PlayerStatus.initialized)) {
      isCurrentPageVisible = true;
      _playControllerAtIndex(position.value);
      return;
    }
    isCurrentPageVisible = true;
    _playersHidden = false;
    await disposeAllController();
    await initVideoPlayer();
  }

  /// Al ocultar el tab: liberar texturas (no solo pause).
  Future<void> releasePlayersOnHidden() async {
    if (_playersHidden) return;
    _playersHidden = true;
    isCurrentPageVisible = false;
    await disposeAllController();
  }

  /// Reanuda el reel actual sin reiniciar desde 0 (vuelta al tab Home).
  void resumeCurrent() {
    isCurrentPageVisible = true;
    final entry = players[position.value];
    if (entry?.controller == null ||
        entry?.status != PlayerStatus.initialized) {
      unawaited(rebindPlayersOnVisible());
      return;
    }
    _playControllerAtIndex(position.value);
  }

  void onPageChanged(int index) {
    if (index > position.value) {
      _fetchMoreData();
      _playNextReel(index);
    } else {
      _playPreviousReel(index);
    }
    position.value = index;
    _playControllerAtIndex(index);
  }

  Future<void> _fetchMoreData() async {
    if (position >= reels.length - 3) {
      Future.delayed(const Duration(seconds: 1), () async {
        await onFetchMoreData?.call().then((value) {
          _initializeControllerAtIndex(position.value + 1);
        });
      });
    }
  }

  void _playNextReel(int index) {
    pauseAllPlayers(reset: true);
    _initializeControllerAtIndex(index);
    _initializeControllerAtIndex(index + 1);
    _disposeAllExcept(index);
  }

  void _playPreviousReel(int index) {
    pauseAllPlayers(reset: true);
    _initializeControllerAtIndex(index);
    _initializeControllerAtIndex(index + 1);
    _disposeAllExcept(index);
  }

  void _disposeAllExcept(int index) {
    // Solo índice actual + siguiente.
    final validIndexes = {index, index + 1};
    final keys = players.keys.toList();

    for (final i in keys) {
      if (!validIndexes.contains(i)) {
        _disposeControllerAtIndex(i);
        players.remove(i);
      }
    }
  }

  void _disposeControllerAtIndex(int index) {
    final entry = players[index];
    if (entry == null) return;
    if (entry.status == PlayerStatus.disposed ||
        entry.status == PlayerStatus.none) {
      return;
    }

    // Invalida cualquier init en vuelo para este índice.
    entry.generation++;
    final controller = entry.controller;
    final listener = entry.listener;
    entry.status = PlayerStatus.disposed;
    entry.controller = null;
    entry.listener = null;
    players[index] = entry;

    if (controller != null) {
      try {
        if (listener != null) {
          controller.removeListener(listener);
        }
      } catch (_) {}
      try {
        controller.pause();
      } catch (_) {}
      try {
        controller.dispose();
      } catch (_) {}
    }

    players.refresh();
    Loggers.info('🗑 DISPOSED $index');
  }

  Future<void> _initializeControllerAtIndex(int index) async {
    if (index < 0 || index >= reels.length) return;

    final existing = players[index];
    if (existing?.status == PlayerStatus.initializing ||
        existing?.status == PlayerStatus.initialized) {
      return;
    }

    final generation = (existing?.generation ?? 0) + 1;
    VideoPlayerController? controller;

    try {
      final reel = reels[index];
      if (reel.id == -1) {
        if (kIsWeb) {
          players[index] = ReelPlayerEntry(
            status: PlayerStatus.failed,
            generation: generation,
          );
          return;
        }
        controller = reels_io.createLocalVideoController(reel.video ?? '');
        if (controller == null) {
          players[index] = ReelPlayerEntry(
            status: PlayerStatus.failed,
            generation: generation,
          );
          return;
        }
      } else {
        final url = reel.video?.addBaseURL() ?? '';
        if (url.isEmpty) {
          players[index] = ReelPlayerEntry(
            status: PlayerStatus.failed,
            generation: generation,
          );
          return;
        }
        controller = VideoPlayerController.networkUrl(
          Uri.parse(url),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }

      // Guardar controller ya en initializing para poder disposearlo si cancela.
      players[index] = ReelPlayerEntry(
        controller: controller,
        status: PlayerStatus.initializing,
        generation: generation,
      );
      players.refresh();

      await controller.initialize();

      final current = players[index];
      if (current == null ||
          current.generation != generation ||
          current.status == PlayerStatus.disposed) {
        try {
          await controller.dispose();
        } catch (_) {}
        Loggers.info('⏭ INIT ABORTED $index (stale generation)');
        return;
      }

      if (!controller.value.isInitialized ||
          controller.value.size.width <= 0 ||
          controller.value.size.height <= 0) {
        try {
          await controller.dispose();
        } catch (_) {}
        players[index] = ReelPlayerEntry(
          status: PlayerStatus.failed,
          generation: generation,
        );
        players.refresh();
        return;
      }

      await controller.setLooping(true);

      // Re-check after async gap.
      final afterLoop = players[index];
      if (afterLoop == null ||
          afterLoop.generation != generation ||
          afterLoop.status == PlayerStatus.disposed) {
        try {
          await controller.dispose();
        } catch (_) {}
        return;
      }

      players[index] = ReelPlayerEntry(
        controller: controller,
        status: PlayerStatus.initialized,
        generation: generation,
      );
      players.refresh();

      Loggers.info('🚀 INITIALIZED $index');

      if (index == position.value) {
        _playControllerAtIndex(index);
      }
    } catch (e) {
      Loggers.error('❌ INIT FAILED $index $e');
      try {
        await controller?.dispose();
      } catch (_) {}
      final current = players[index];
      if (current != null && current.generation == generation) {
        players[index] = ReelPlayerEntry(
          status: PlayerStatus.failed,
          generation: generation,
        );
        players.refresh();
      }
    }
  }

  void _playControllerAtIndex(int index) {
    if (!isCurrentPageVisible) return;

    final dashController = Get.find<DashboardScreenController>();
    if (reelPageType == ReelPageType.home &&
        (dashController.selectedPageIndex.value !=
                DashboardScreenController.tabHome ||
            dashController.homeTabMode.value == HomeTabMode.feed)) {
      return;
    }

    final entry = players[index];
    final controller = entry?.controller;
    if (entry?.status != PlayerStatus.initialized || controller == null) {
      return;
    }

    try {
      if (!controller.value.isInitialized) return;
      if (controller.value.hasError) return;
      controller.play();
    } catch (e) {
      Loggers.error('PLAY FAILED $index $e');
      return;
    }

    DebounceAction.shared.call(milliseconds: 3000, () {
      if (index >= 0 && index < reels.length) {
        _increaseViewsCount(reels[index]);
      }
    });
    Loggers.info('🚀🚀🚀 PLAYING $index');
  }

  void _increaseViewsCount(Post reelData) {
    PostService.instance.increaseViewsCount(postId: reelData.id).then((value) {
      if (value.status == true) {
        if (Get.isRegistered<ReelController>(tag: reelData.id.toString())) {
          Get.find<ReelController>(tag: reelData.id.toString())
              .updateReelData(reel: reelData, isIncreaseCoin: true);
        }
      }
    });
  }

  void pauseAllPlayers({bool reset = false, bool markInvisible = false}) {
    if (markInvisible) {
      isCurrentPageVisible = false;
    }
    final keys = players.keys.toList();
    for (var i in keys) {
      _stopControllerAtIndex(i, reset: reset);
    }
  }

  void _stopControllerAtIndex(int index, {bool reset = false}) {
    if (reels.length > index && index >= 0) {
      final controller = players[index]?.controller;
      if (controller == null) return;
      try {
        controller.pause();
        if (reset) {
          controller.seekTo(const Duration());
        }
        Loggers.info('🚀🚀🚀 STOPPED $index reset=$reset');
      } catch (e) {
        Loggers.error('STOP FAILED $index $e');
      }
    }
  }

  Future<void> disposeAllController() async {
    final entries = players.entries.toList();
    for (var entry in entries) {
      entry.value.generation++;
      final controller = entry.value.controller;
      final listener = entry.value.listener;
      try {
        if (listener != null) {
          controller?.removeListener(listener);
        }
      } catch (_) {}
      try {
        controller?.pause();
      } catch (_) {}
      try {
        await controller?.dispose();
      } catch (_) {}
      entry.value.controller = null;
      entry.value.status = PlayerStatus.disposed;
    }
    players.clear();
  }

  /// Handle refresh logic
  Future<void> handleRefresh(Future<void> Function()? onRefresh) async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;

    await onRefresh?.call();
    await Future.delayed(const Duration(milliseconds: 200));
    if (reels.isNotEmpty) {
      position.value = 0;
      if (pageController.hasClients) {
        pageController.jumpToPage(0);
      }
      await disposeAllController();
      isCurrentPageVisible = true;
      await initVideoPlayer();
    }

    isRefreshing.value = false;
    update();
  }

  void onReportTap() {
    Get.bottomSheet(
        ReportSheet(
            reportType: ReportType.post,
            id: reels[position.value].id?.toInt()),
        isScrollControlled: true);
  }

  void onUpdateComment(Comment comment, bool isReplyComment) {
    final post = reels.firstWhereOrNull((e) => e.id == comment.postId);
    if (post == null) {
      return Loggers.error('Post not found');
    }
    final controllerTag = post.id.toString();
    if (Get.isRegistered<ReelController>(tag: controllerTag)) {
      Get.find<ReelController>(tag: controllerTag)
          .reelData
          .update((val) => val?.updateCommentCount(1));
    }
  }

  void openPostOptionsSheet() {
    const tag = ProfileScreenController.tag;

    final controller = Get.isRegistered<ProfileScreenController>(tag: tag)
        ? Get.find<ProfileScreenController>(tag: tag)
        : Get.put(
            ProfileScreenController(
                SessionManager.instance.getUser().obs, (user) {}),
            tag: tag);

    Get.bottomSheet(
        PostOptionsSheet(
          controller: controller,
          onChanged: (type) {
            if (type == PublishType.goLive) {
              Future.delayed(
                const Duration(seconds: 1),
                () {
                  final controller = Get.find<DashboardScreenController>();
                  controller.onChanged(DashboardScreenController.tabLive);
                },
              );
            }
          },
        ),
        isScrollControlled: true);
  }

  onUpdateReelData(Post reel) {
    final index = reels.indexWhere((element) => element.id == reel.id);
    if (index != -1) {
      reels[index] = reel;
    }
  }
}

class ReelPlayerEntry {
  VideoPlayerController? controller;
  VoidCallback? listener;
  PlayerStatus status;
  int generation;

  ReelPlayerEntry({
    this.controller,
    this.listener,
    this.status = PlayerStatus.none,
    this.generation = 0,
  });
}

enum PlayerStatus { none, initializing, initialized, disposed, failed }
