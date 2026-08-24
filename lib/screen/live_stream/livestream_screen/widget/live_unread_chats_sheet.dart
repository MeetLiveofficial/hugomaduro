import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/service/api/chat_service.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/chat/chat_thread.dart';
import 'package:krimson/model/chat/message_data.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Mini panel de chats 1:1 sin leer + respuesta rápida desde el LIVE.
class LiveUnreadChatsSheet extends StatefulWidget {
  const LiveUnreadChatsSheet({super.key});

  @override
  State<LiveUnreadChatsSheet> createState() => _LiveUnreadChatsSheetState();
}

class _LiveUnreadChatsSheetState extends State<LiveUnreadChatsSheet> {
  bool _loading = true;
  List<ChatThread> _unread = [];
  ChatThread? _active;
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await ChatService.instance.fetchThreads();
      final list = <ChatThread>[
        ...result.chats.where((t) => (t.msgCount ?? 0) > 0),
        ...result.requests.where((t) => (t.msgCount ?? 0) > 0),
      ];
      for (final t in list) {
        t.bindChatUser();
      }
      if (!mounted) return;
      setState(() {
        _unread = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _unread = [];
        _loading = false;
      });
    }
  }

  Future<void> _sendReply() async {
    final thread = _active;
    final text = _replyCtrl.text.trim();
    final peerId = thread?.peerUserId ?? 0;
    if (thread == null || text.isEmpty || peerId <= 0 || _sending) return;
    setState(() => _sending = true);
    try {
      await ChatService.instance.sendMessage(
        peerUserId: peerId,
        type: MessageType.text,
        textMessage: text,
      );
      _replyCtrl.clear();
      thread.msgCount = 0;
      if (!mounted) return;
      setState(() {
        _unread.removeWhere((t) => t.peerUserId == peerId);
        _active = null;
      });
      Get.snackbar(
        '',
        'Mensaje enviado',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 16,
        titleText: const SizedBox.shrink(),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        '',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        titleText: const SizedBox.shrink(),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.58;
    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: Color(0xFF160E1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  if (_active != null)
                    IconButton(
                      onPressed: () => setState(() => _active = null),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white70, size: 18),
                    ),
                  Expanded(
                    child: Text(
                      _active == null
                          ? LKey.unreadChats.tr
                          : (_active!.chatUser?.fullname ??
                              _active!.chatUser?.username ??
                              LKey.chat.tr),
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ColorRes.themeAccentSolid,
                        strokeWidth: 2.4,
                      ),
                    )
                  : _active != null
                      ? _buildReplyPane()
                      : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_unread.isEmpty) {
      return Center(
        child: Text(
          'No tienes chats sin leer',
          style: TextStyleCustom.outFitRegular400(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: _unread.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final t = _unread[index];
        final user = t.chatUser;
        final name =
            (user?.fullname ?? user?.username ?? 'Usuario').trim();
        final unread = t.msgCount ?? 0;
        return Material(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _active = t),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CustomImage(
                    size: const Size(42, 42),
                    image: user?.profile?.addBaseURL(),
                    fullName: name,
                    radius: 21,
                    strokeWidth: 0,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyleCustom.outFitMedium500(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (t.lastMsg ?? '').trim().isEmpty
                              ? 'Nuevo mensaje'
                              : t.lastMsg!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyleCustom.outFitRegular400(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorRes.themeAccentSolid,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: TextStyleCustom.outFitMedium500(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReplyPane() {
    final t = _active!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              (t.lastMsg ?? '').trim().isEmpty
                  ? LKey.tapToReply.tr
                  : t.lastMsg!,
              style: TextStyleCustom.outFitRegular400(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyCtrl,
                  style: TextStyleCustom.outFitRegular400(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  cursorColor: ColorRes.themeAccentSolid,
                  decoration: InputDecoration(
                    hintText: 'Responder…',
                    hintStyle: TextStyleCustom.outFitRegular400(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _sendReply(),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: ColorRes.themeAccentSolid,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _sending ? null : _sendReply,
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
