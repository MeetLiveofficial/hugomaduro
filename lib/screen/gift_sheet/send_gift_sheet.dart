import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/common_extension.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/bottom_sheet_top_view.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/full_name_with_blue_tick.dart';
import 'package:krimson/common/widget/gift_media.dart';
import 'package:krimson/common/widget/gradient_text.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/livestream/app_user.dart';
import 'package:krimson/screen/gift_sheet/send_gift_sheet_controller.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/style_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class SendGiftSheet extends StatelessWidget {
  final GiftType giftType;
  final BattleView battleViewType;
  final int? userId;
  final List<AppUser> streamUsers;

  const SendGiftSheet(
      {super.key,
      this.giftType = GiftType.none,
      this.battleViewType = BattleView.red,
      required this.userId,
      this.streamUsers = const []});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.put(SendGiftSheetController(giftType, userId, streamUsers));

    return Container(
      height: Get.height / 1.5,
      margin: EdgeInsets.only(top: AppBar().preferredSize.height * 2.5),
      decoration: ShapeDecoration(
        shape: const SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.vertical(
            top: SmoothRadius(cornerRadius: 40, cornerSmoothing: 1),
          ),
        ),
        color: scaffoldBackgroundColor(context),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            BottomSheetTopView(
                title: LKey.sendGifts.tr,
                margin: const EdgeInsets.only(top: 15)),
            switch (giftType) {
              GiftType.none => const SizedBox(),
              GiftType.livestream => GiftForLiveStream(
                  controller: controller, streamUsers: streamUsers),
              GiftType.battle => Container(
                  width: double.infinity,
                  color: battleViewType.color,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomImage(
                              size: const Size(30, 30),
                              image: streamUsers.first.profile?.addBaseURL(),
                              fullName: streamUsers.first.fullname,
                              strokeColor: whitePure(context),
                              strokeWidth: 1.2),
                          const SizedBox(width: 5),
                          Flexible(
                              child: FullNameWithBlueTick(
                                  username: streamUsers.first.username,
                                  fontColor: whitePure(context),
                                  isVerify: streamUsers.first.isVerify))
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        LKey.youAreSendingCoinsTo
                            .trParams({'color': battleViewType.value}),
                        style: TextStyleCustom.outFitLight300(
                            color: whitePure(context), fontSize: 12),
                      )
                    ],
                  ),
                ),
            },
            const SizedBox(height: 10),
            Obx(() => GradientText(
                (controller.myUser.value?.coinWallet ?? '0').toString(),
                gradient: StyleRes.themeGradient,
                style: TextStyleCustom.unboundedSemiBold600(fontSize: 21))),
            Text(LKey.coinsYouHave.tr,
                style: TextStyleCustom.outFitRegular400(
                    fontSize: 15, color: textLightGrey(context))),
            Obx(() {
              final cats = controller.categories;
              if (cats.isEmpty) return const SizedBox(height: 10);
              return Column(
                children: [
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: cats.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final catId = isAll ? 0 : (cats[index - 1].id ?? 0);
                        final label = isAll
                            ? LKey.all.tr
                            : (cats[index - 1].name ?? '');
                        final selected =
                            controller.selectedCategoryId.value == catId;
                        return GestureDetector(
                          onTap: () => controller.selectCategory(catId),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: selected
                                  ? StyleRes.themeGradient
                                  : null,
                              color: selected
                                  ? null
                                  : bgLightGrey(context),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              label,
                              style: TextStyleCustom.outFitMedium500(
                                fontSize: 13,
                                color: selected
                                    ? whitePure(context)
                                    : textDarkGrey(context),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }),
            Expanded(child: Obx(
              () {
                final gifts = controller.visibleGifts;
                if (gifts.isEmpty) {
                  return Center(
                    child: Text(
                      LKey.noData.tr,
                      style: TextStyleCustom.outFitRegular400(
                          color: textLightGrey(context)),
                    ),
                  );
                }
                return GridView.builder(
                  controller: controller.scrollController,
                  itemCount: gifts.length + (controller.hasMore.value ? 1 : 0),
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisExtent: 126,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5),
                  itemBuilder: (context, index) {
                    if (index >= gifts.length) {
                      return const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    Gift gift = gifts[index];
                    return InkWell(
                      onTap: () => controller.onGiftTap(gift, context),
                      child: Container(
                        decoration: ShapeDecoration(
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                                cornerRadius: 5, cornerSmoothing: 1),
                          ),
                          color: bgLightGrey(context),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GiftMedia(
                              path: gift.image,
                              width: 65,
                              height: 65,
                              fit: BoxFit.contain,
                              muted: true,
                              looping: true,
                              placeholder: Image.asset(
                                AssetRes.icGift,
                                width: 65,
                                height: 65,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Text(
                                '${(gift.coinPrice ?? 0).numberFormat} ${LKey.coins.tr}',
                                style: TextStyleCustom.outFitMedium500(
                                    fontSize: 13,
                                    color: textLightGrey(context))),
                            GradientText(LKey.send.tr,
                                gradient: StyleRes.themeGradient,
                                style: TextStyleCustom.unboundedMedium500(
                                    fontSize: 13))
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ))
          ],
        ),
      ),
    );
  }
}

class GiftForLiveStream extends StatelessWidget {
  final SendGiftSheetController controller;
  final List<AppUser> streamUsers;

  const GiftForLiveStream(
      {super.key, required this.controller, required this.streamUsers});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          AppUser? giftUser =
              controller.livestreamController?.selectedGiftUser.value ??
                  (streamUsers.isNotEmpty ? streamUsers.first : null);
          if (giftUser == null) {
            return const SizedBox();
          }
          return streamUsers.length <= 1
              ? Container(
                  color: bgLightGrey(context),
                  child: _PopupMenuItemCustom(streamUser: giftUser))
              : PopupMenuButton<AppUser>(
                  initialValue: giftUser,
                  onSelected: (AppUser value) {
                    final live = controller.livestreamController;
                    if (live != null) {
                      live.selectedGiftUser.value = value;
                    }
                  },
                  shape: const RoundedRectangleBorder(
                    borderRadius: SmoothBorderRadius.vertical(
                        bottom:
                            SmoothRadius(cornerRadius: 15, cornerSmoothing: 1)),
                  ),
                  position: PopupMenuPosition.under,
                  constraints: const BoxConstraints(
                      maxWidth: double.infinity, minWidth: double.infinity),
                  itemBuilder: (BuildContext context) {
                    return List.generate(
                      streamUsers.length,
                      (index) => PopupMenuItem(
                          value: streamUsers[index],
                          padding: EdgeInsets.zero,
                          child: _PopupMenuItemCustom(
                              streamUser: streamUsers[index])),
                    );
                  },
                  child: _PopupMenuItemCustom(
                      isPopupChild: true, streamUser: giftUser),
                );
        }),
        const SizedBox(height: 3),
        Text(
          LKey.sendingCoinsMessage.tr,
          style: TextStyleCustom.outFitLight300(
              color: textLightGrey(context), fontSize: 13),
        )
      ],
    );
  }
}

class _PopupMenuItemCustom extends StatelessWidget {
  final bool isPopupChild;
  final AppUser streamUser;

  const _PopupMenuItemCustom(
      {this.isPopupChild = false, required this.streamUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isPopupChild ? bgLightGrey(context) : null,
      height: 45,
      width: MediaQuery.of(context).size.width - 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomImage(
            size: const Size(30, 30),
            image: streamUser.profile?.addBaseURL(),
            fullName: streamUser.fullname ?? '',
            strokeColor: whitePure(context),
            strokeWidth: 1,
          ),
          const SizedBox(width: 5),
          FullNameWithBlueTick(
            username: streamUser.username,
            isVerify: streamUser.isVerify,
            iconSize: 14,
          ),
          if (isPopupChild)
            Image.asset(AssetRes.icDownArrow_1, width: 26, height: 26),
        ],
      ),
    );
  }
}

enum GiftType {
  none,
  livestream,
  battle;
}

enum BattleView {
  red('red'),
  blue('blue');

  final String value;

  const BattleView(this.value);

  Color get color {
    switch (this) {
      case BattleView.red:
        return ColorRes.likeRed;
      case BattleView.blue:
        return ColorRes.battleProgressColor;
    }
  }
}
