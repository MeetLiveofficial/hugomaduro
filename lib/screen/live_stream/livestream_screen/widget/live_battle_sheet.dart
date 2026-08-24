import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/widget/custom_image.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Sheet del host para elegir rival e iniciar Batalla 1v1.
Future<void> openLiveBattleSheet({
  required RxList<User> candidates,
  required RxBool loading,
  required RxnInt selectedOpponentId,
  required RxInt durationMinutes,
  required Future<void> Function() onSearchLoad,
  required Future<void> Function(String keyword) onSearch,
  required Future<void> Function() onStart,
}) async {
  await onSearchLoad();
  final searchCtrl = TextEditingController();

  await Get.bottomSheet(
    SafeArea(
      child: Container(
        height: MediaQuery.of(Get.context!).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: whitePure(Get.context!),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: bgGrey(Get.context!),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              LKey.startBattle.tr,
              textAlign: TextAlign.center,
              style: TextStyleCustom.unboundedSemiBold600(
                color: textDarkGrey(Get.context!),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Elige un rival. La audiencia enviará regalos para empujar el marcador.',
              textAlign: TextAlign.center,
              style: TextStyleCustom.outFitRegular400(
                color: textLightGrey(Get.context!),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final mins = durationMinutes.value;
              return Row(
                children: [
                  Text(
                    'Duración',
                    style: TextStyleCustom.outFitMedium500(
                      color: textDarkGrey(Get.context!),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  _DurationChip(
                    label: '1 min',
                    selected: mins == 1,
                    onTap: () => durationMinutes.value = 1,
                  ),
                  const SizedBox(width: 6),
                  _DurationChip(
                    label: '3 min',
                    selected: mins == 3,
                    onTap: () => durationMinutes.value = 3,
                  ),
                  const SizedBox(width: 6),
                  _DurationChip(
                    label: '5 min',
                    selected: mins == 5,
                    onTap: () => durationMinutes.value = 5,
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: searchCtrl,
              textInputAction: TextInputAction.search,
              onChanged: (v) => onSearch(v.trim()),
              onSubmitted: (v) => onSearch(v.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar rival…',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: bgGrey(Get.context!)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: bgGrey(Get.context!)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (loading.value && candidates.isEmpty) {
                  return const LoaderWidget();
                }
                if (candidates.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        LKey.noRivalsInLive.tr,
                        textAlign: TextAlign.center,
                        style: TextStyleCustom.outFitRegular400(
                          color: textLightGrey(Get.context!),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = candidates[index];
                    final id = user.id ?? -1;
                    return Obx(() {
                      final selected = selectedOpponentId.value == id;
                      return ListTile(
                        onTap: () => selectedOpponentId.value = id,
                        selected: selected,
                        selectedTileColor:
                            ColorRes.themeAccentSolid.withValues(alpha: 0.08),
                        leading: CustomImage(
                          size: const Size(40, 40),
                          strokeWidth: selected ? 2 : 0,
                          strokeColor: ColorRes.themeAccentSolid,
                          image: user.profilePhoto?.addBaseURL(),
                          fullName: user.fullname,
                        ),
                        title: Text(
                          user.username ?? user.fullname ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(user.fullname ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: ColorRes.themeAccentSolid,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'LIVE',
                                style: TextStyleCustom.outFitMedium500(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected
                                  ? ColorRes.themeAccentSolid
                                  : textLightGrey(context),
                            ),
                          ],
                        ),
                      );
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final canStart = (selectedOpponentId.value ?? 0) > 0;
              return ElevatedButton(
                onPressed: canStart
                    ? () async {
                        await onStart();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorRes.themeAccentSolid,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.black12,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  LKey.startBattle.tr,
                  style: TextStyleCustom.outFitMedium500(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  ).whenComplete(searchCtrl.dispose);
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? ColorRes.themeAccentSolid.withValues(alpha: 0.15)
          : bgGrey(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyleCustom.outFitMedium500(
              color: selected ? ColorRes.themeAccentSolid : textDarkGrey(context),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
