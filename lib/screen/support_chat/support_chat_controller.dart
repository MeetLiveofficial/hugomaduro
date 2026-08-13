import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/service/api/support_service.dart';
import 'package:krimson/model/support/support_ticket.dart';

class SupportChatController extends BaseController {
  final Rxn<SupportTicket> ticket = Rxn<SupportTicket>();
  final RxList<SupportMessage> messages = <SupportMessage>[].obs;
  final TextEditingController textController = TextEditingController();
  final RxBool isTextEmpty = true.obs;
  final RxBool isSending = false.obs;
  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    textController.dispose();
    super.onClose();
  }

  void onTextChanged(String value) {
    isTextEmpty.value = value.trim().isEmpty;
  }

  Future<void> _bootstrap() async {
    isLoading.value = true;
    try {
      ticket.value = await SupportService.instance.openOrGet();
      await _refreshMessages();
      if (ticket.value?.id != null) {
        await SupportService.instance.markRead(ticketId: ticket.value?.id);
      }
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        _refreshMessages(silent: true);
      });
    } catch (e) {
      Loggers.error('support bootstrap: $e');
      showSnackBar(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _refreshMessages({bool silent = false}) async {
    try {
      final result = await SupportService.instance.fetchMessages(
        ticketId: ticket.value?.id,
      );
      ticket.value = result.ticket;
      final sorted = result.messages.toList()
        ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      messages.assignAll(sorted);
      if (!silent && ticket.value?.id != null) {
        await SupportService.instance.markRead(ticketId: ticket.value?.id);
      }
    } catch (e) {
      Loggers.error('support fetchMessages: $e');
      if (!silent) showSnackBar(e.toString());
    }
  }

  Future<void> sendText() async {
    final text = textController.text.trim();
    if (text.isEmpty || isSending.value) return;
    isSending.value = true;
    try {
      final result = await SupportService.instance.sendMessage(
        ticketId: ticket.value?.id,
        text: text,
      );
      ticket.value = result.ticket;
      textController.clear();
      isTextEmpty.value = true;
      messages.insert(0, result.message);
    } catch (e) {
      Loggers.error('support send: $e');
      showSnackBar(e.toString());
    } finally {
      isSending.value = false;
    }
  }
}
