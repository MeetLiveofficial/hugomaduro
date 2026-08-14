import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/enum/chat_enum.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/widget/custom_divider.dart';
import 'package:krimson/common/widget/gradient_text.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/chat/chat_thread.dart';
import 'package:krimson/screen/chat_screen/chat_screen_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class ChatBottomActionView extends StatelessWidget {
  final ChatScreenController controller;

  const ChatBottomActionView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          const CustomDivider(),
          const SizedBox(height: 10),
          Obx(() {
            ChatThread conversationUser = controller.conversationUser.value;
            bool iBlocked = conversationUser.iBlocked ?? false;
            bool iAmBlocked = conversationUser.iAmBlocked ?? false;

            if (iBlocked) {
              return ChatUnBlockedView(
                conversationUser: conversationUser,
                onTapUnblock: controller.toggleBlockUnblock,
              );
            } else if (iAmBlocked) {
              return const ChatIBlockedView();
            } else {
              if (conversationUser.chatType == ChatType.request) {
                return ChatBottomRequestView(
                    controller: controller, conversation: conversationUser);
              }
              return Stack(alignment: Alignment.center, children: [
                ChatTextField(
                    controller: controller.textController,
                    isTextEmpty: controller.isTextEmpty,
                    onChange: controller.onTextFieldChanged,
                    onCameraTap: controller.onCameraTap,
                    onChatActionTap: controller.onChatActionTap,
                    onSendTextMessage: controller.onSendTextMessage,
                    actions: ChatAction.getChatActions(
                        isGiphyEnabled: controller.setting?.gifSupport == 1,
                        includeGift: AppRole.canSendGifts())),
                AudioWavesContainer(controller: controller)
              ]);
            }
          }),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class ChatTextField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String value)? onChange;
  final VoidCallback? onCameraTap;
  final VoidCallback? onSendTextMessage;
  final Function(ChatAction value)? onChatActionTap;
  final RxBool isTextEmpty;
  final Color? borderColor;
  final List<ChatAction> actions;

  const ChatTextField(
      {super.key,
      required this.controller,
      this.onChange,
      this.onCameraTap,
      required this.isTextEmpty,
      this.onSendTextMessage,
      this.onChatActionTap,
      this.borderColor,
      this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(cornerRadius: 30),
            side: BorderSide(color: borderColor ?? bgGrey(context))),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Slot fijo: no eliminar el widget al escribir (evita perder foco).
          Obx(() {
            final hasNoText = isTextEmpty.value;
            return AnimatedSize(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: hasNoText
                  ? InkWell(
                      onTap: onCameraTap,
                      child: Container(
                        height: 40,
                        width: 40,
                        margin: const EdgeInsets.only(left: 2, right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              themeAccentSolid(context).withValues(alpha: .1),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.photo_camera_outlined,
                            size: 22, color: themeAccentSolid(context)),
                      ),
                    )
                  : const SizedBox(width: 4, height: 40),
            );
          }),
          Expanded(
            child: TextField(
              key: const ValueKey('chat_text_field'),
              controller: controller,
              onChanged: onChange,
              textAlignVertical: TextAlignVertical.center,
              minLines: 1,
              maxLines: 3,
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: InputBorder.none,
                hintText: '${LKey.writeHere.tr}..',
                hintStyle: TextStyleCustom.outFitLight300(
                    color: textLightGrey(context)),
              ),
              style: TextStyleCustom.outFitRegular400(
                  color: textDarkGrey(context), fontSize: 16),
            ),
          ),
          Obx(() {
            final hasNoText = isTextEmpty.value;
            if (hasNoText) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  actions.length,
                  (index) {
                    return InkWell(
                      onTap: () => onChatActionTap?.call(actions[index]),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          actions[index].icon,
                          size: 22,
                          color: textDarkGrey(context),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            return InkWell(
              onTap: onSendTextMessage,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
                child: GradientText(
                  LKey.send.tr,
                  gradient: StyleRes.themeGradient,
                  style: TextStyleCustom.unboundedMedium500(fontSize: 15),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class ChatBottomRequestView extends StatelessWidget {
  final ChatScreenController controller;
  final ChatThread conversation;

  const ChatBottomRequestView({
    super.key,
    required this.controller,
    required this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          Text(
              LKey.chatRequestMessage.trParams(
                  {'chat_user_name': '${conversation.chatUser?.username}'}),
              style: TextStyleCustom.outFitLight300(
                  fontSize: 15, color: textLightGrey(context))),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              controller.requestType.length,
              (index) {
                UserRequestAction requestType = controller.requestType[index];
                return Expanded(
                  child: InkWell(
                    onTap: () =>
                        controller.onChatRequestTap(requestType, conversation),
                    child: Container(
                      height: 37,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: ShapeDecoration(
                          color: requestType.color(context),
                          shape: SmoothRectangleBorder(
                              borderRadius:
                                  SmoothBorderRadius(cornerRadius: 30))),
                      alignment: Alignment.center,
                      child: Text(
                        requestType.title.tr.capitalize ?? '',
                        style: TextStyleCustom.outFitRegular400(
                            color: requestType.titleColor(context)),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class AudioWavesContainer extends StatelessWidget {
  final ChatScreenController controller;

  const AudioWavesContainer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.audioWidthAnimation == null) {
      return const SizedBox();
    }
    return AnimatedBuilder(
      animation: controller.audioWidthAnimation!,
      builder: (context, child) {
        return Align(
          alignment: Alignment.centerLeft,
          child: ClipRect(
            // Prevents overflow by clipping excess
            child: Container(
              width: controller.audioWidthAnimation!.value,
              height: 46,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              decoration: ShapeDecoration(
                color: bgLightGrey(context),
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(cornerRadius: 30),
                ),
              ),
              child: controller.audioWidthAnimation!.value >
                      120 // Hide Row when width is too small
                  ? Row(
                      children: [
                        // Left icon
                        InkWell(
                          onTap: controller.deleteRecordedAudio,
                          child: AnimatedContainer(
                            height: 45,
                            width: 45,
                            duration: const Duration(milliseconds: 100),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 1, vertical: 2),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ColorRes.likeRed.withValues(alpha: .1)),
                            alignment: Alignment.center,
                            child: Image.asset(AssetRes.icDelete,
                                height: 25, width: 25, color: ColorRes.likeRed),
                          ),
                        ),
                        // Middle expanding waveform
                        Expanded(
                          child: AudioWaveforms(
                            size: Size(MediaQuery.of(context).size.width, 35),
                            recorderController: controller.recorderController,
                            waveStyle: WaveStyle(
                                middleLineColor: Colors.transparent,
                                extendWaveform: true,
                                waveThickness: 1.5,
                                spacing: 3,
                                waveColor: bgGrey(context),
                                gradient: StyleRes.wavesGradient),
                          ),
                        ),
                        // Right send button
                        InkWell(
                          onTap: controller.sendRecordedAudio,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: GradientText(
                              LKey.send.tr,
                              gradient: StyleRes.themeGradient,
                              style: TextStyleCustom.unboundedMedium500(
                                  fontSize: 15),
                            ),
                          ),
                        )
                      ],
                    )
                  : null, // Hide Row when width is 0
            ),
          ),
        );
      },
    );
  }
}

class ChatUnBlockedView extends StatelessWidget {
  final ChatThread conversationUser;
  final Function(ChatThread conversationUser) onTapUnblock;

  const ChatUnBlockedView(
      {super.key, required this.conversationUser, required this.onTapUnblock});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          spacing: 5,
          children: [
            Text(
                LKey.youBlockedUser.trParams({
                  'block_user_name': '${conversationUser.chatUser?.username}'
                }),
                style: TextStyleCustom.outFitLight300(
                    fontSize: 15, color: textLightGrey(context)),
                textAlign: TextAlign.center),
            InkWell(
              onTap: () => onTapUnblock(conversationUser),
              child: Container(
                height: 37,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: ShapeDecoration(
                    color: bgGrey(context),
                    shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(cornerRadius: 30))),
                alignment: Alignment.center,
                child: Text(
                  LKey.unBlock.tr.capitalize ?? '',
                  style: TextStyleCustom.outFitRegular400(
                      color: textDarkGrey(context)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ChatIBlockedView extends StatelessWidget {
  const ChatIBlockedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(LKey.youAreBlockedByThisUser.tr,
        style: TextStyleCustom.outFitLight300(
            fontSize: 15, color: textLightGrey(context)),
        textAlign: TextAlign.center);
  }
}
