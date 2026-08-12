import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/call_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/no_data_widget.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/call/call_request_model.dart';
import 'package:krimson/screen/call_screen/incoming_call_screen.dart';
import 'package:krimson/screen/call_screen/live_incoming_call_overlay.dart';
import 'package:krimson/screen/call_screen/video_call_screen.dart';
import 'package:krimson/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CallsListController extends BaseController {
  final RxList<CallRequestModel> received = <CallRequestModel>[].obs;
  final RxList<CallRequestModel> sent = <CallRequestModel>[].obs;
  final Set<int> _seenIncomingIds = {};
  bool _didPrimeIncoming = false;
  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    refreshInbox();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      refreshInbox(silent: true);
    });
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<void> refreshInbox({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final inbox = await CallService.instance.inbox();
      received.assignAll(inbox.received);
      sent.assignAll(inbox.sent);

      final pendingIncoming =
          inbox.received.where((e) => e.isPending && e.id != null).toList();

      if (Get.isRegistered<DashboardScreenController>()) {
        final dash = Get.find<DashboardScreenController>();
        dash.callsUnReadCount.value = pendingIncoming.length;
        dash.unReadCount.value = dash.chatUnReadCount.value +
            dash.requestUnReadCount.value +
            dash.callsUnReadCount.value;
      }

      if (!_didPrimeIncoming) {
        _seenIncomingIds.addAll(pendingIncoming.map((e) => e.id!));
        _didPrimeIncoming = true;
      }
      // Sin auto-abrir IncomingCall: solo lista + badge (CHAT | REQUEST | CALL).
      // El usuario responde desde la pestaña CALL o tocando la notificación.
    } catch (e) {
      if (!silent) showSnackBar(e.toString());
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  Future<void> answer(CallRequestModel item) async {
    if (item.id == null) return;
    final opened = await LiveIncomingCallOverlay.show(item);
    if (!opened) {
      Get.to(() => IncomingCallScreen(call: item, asDialog: true));
    }
  }

  Future<void> reject(CallRequestModel item) async {
    if (item.id == null) return;
    showLoader();
    try {
      await CallService.instance.reject(item.id!);
      await refreshInbox();
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      stopLoader();
    }
  }

  Future<void> cancel(CallRequestModel item) async {
    if (item.id == null) return;
    showLoader();
    try {
      await CallService.instance.cancel(item.id!);
      final me = SessionManager.instance.getUser();
      if (me != null && item.coinsCost > 0) {
        me.coinWallet = (me.coinWallet ?? 0) + item.coinsCost;
        SessionManager.instance.setUser(me);
      }
      await refreshInbox();
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      stopLoader();
    }
  }

  Future<void> joinAccepted(CallRequestModel item) async {
    if (!item.isAccepted || item.roomId == null) return;
    Get.to(() => VideoCallScreen(call: item));
  }
}

class CallsListView extends StatelessWidget {
  const CallsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CallsListController>()
        ? Get.find<CallsListController>()
        : Get.put(CallsListController());

    return Obx(() {
      if (controller.isLoading.value &&
          controller.received.isEmpty &&
          controller.sent.isEmpty) {
        return const LoaderWidget();
      }
      final items = [...controller.received, ...controller.sent];
      items.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

      return NoDataView(
        showShow: items.isEmpty,
        title: LKey.callEmptyTitle.tr,
        description: LKey.callEmptyDescription.tr,
        child: RefreshIndicator(
          onRefresh: controller.refreshInbox,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final meId = SessionManager.instance.getUserID();
              final incoming = item.calleeId == meId;
              final peer = incoming ? item.caller : item.callee;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgLightGrey(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CustomImage(
                      size: const Size(44, 44),
                      image: peer?.profilePhoto?.addBaseURL(),
                      fullName: peer?.fullname ?? peer?.username,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peer?.fullname ?? peer?.username ?? '-',
                            style: TextStyleCustom.outFitMedium500(
                                color: textDarkGrey(context), fontSize: 14),
                          ),
                          Text(
                            item.isMatchSession
                                ? 'Match · ${item.status} · ${item.coinsCost} ${LKey.coins.tr}'
                                : '${incoming ? LKey.incomingCall.tr : LKey.outgoingCall.tr} · ${item.status} · ${item.coinsCost} ${LKey.coins.tr}',
                            style: TextStyleCustom.outFitRegular400(
                                color: textLightGrey(context), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (item.isPending && incoming) ...[
                      TextButtonCustom(
                        onTap: () => controller.answer(item),
                        title: LKey.accept.tr,
                        backgroundColor: themeAccentSolid(context),
                        titleColor: whitePure(context),
                        btnHeight: 32,
                        btnWidth: 72,
                        fontSize: 12,
                        horizontalMargin: 0,
                        margin: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 6),
                      TextButtonCustom(
                        onTap: () => controller.reject(item),
                        title: LKey.refuse.tr,
                        backgroundColor: bgGrey(context),
                        titleColor: textDarkGrey(context),
                        btnHeight: 32,
                        btnWidth: 72,
                        fontSize: 12,
                        horizontalMargin: 0,
                        margin: EdgeInsets.zero,
                      ),
                    ] else if (item.isPending && !incoming)
                      TextButtonCustom(
                        onTap: () => controller.cancel(item),
                        title: LKey.cancelCall.tr,
                        backgroundColor: bgGrey(context),
                        titleColor: textDarkGrey(context),
                        btnHeight: 32,
                        btnWidth: 72,
                        fontSize: 12,
                        horizontalMargin: 0,
                        margin: EdgeInsets.zero,
                      )
                    else if (item.isAccepted)
                      TextButtonCustom(
                        onTap: () => controller.joinAccepted(item),
                        title: LKey.videoCall.tr,
                        backgroundColor: themeAccentSolid(context),
                        titleColor: whitePure(context),
                        btnHeight: 32,
                        btnWidth: 72,
                        fontSize: 12,
                        horizontalMargin: 0,
                        margin: EdgeInsets.zero,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }
}
