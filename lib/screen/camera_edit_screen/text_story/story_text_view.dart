import 'dart:io';

import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/screen/camera_edit_screen/camera_edit_screen_controller.dart';
import 'package:krimson/screen/camera_edit_screen/text_story/story_text_view_controller.dart';
import 'package:krimson/screen/camera_screen/camera_screen_controller.dart';
import 'package:krimson/utilities/app_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

class CameraEditImageView extends StatelessWidget {
  final CameraEditScreenController cameraEditController;

  const CameraEditImageView({super.key, required this.cameraEditController});

  @override
  Widget build(BuildContext context) {
    final textController = Get.put(StoryTextViewController());
    cameraEditController.onNewTexFieldAdd = () {
      textController.addTextField();
    };

    // Primer campo de texto para stories de texto.
    if (cameraEditController.content.value.type ==
            PostStoryContentType.storyText &&
        textController.texts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (textController.texts.isEmpty) {
          textController.addTextField(initialText: 'Aa');
        }
      });
    }

    return StoryTextView(cameraEditController: cameraEditController);
  }
}

class StoryTextView extends StatelessWidget {
  final CameraEditScreenController cameraEditController;

  const StoryTextView({super.key, required this.cameraEditController});

  @override
  Widget build(BuildContext context) {
    final textController = Get.find<StoryTextViewController>();

    return ClipSmoothRect(
      radius: SmoothBorderRadius(cornerRadius: 15, cornerSmoothing: 1),
      child: Obx(() {
        final content = cameraEditController.content.value;
        final isTextStory = content.type == PostStoryContentType.storyText;
        final gradient = isTextStory
            ? cameraEditController.storyGradientColor[
                cameraEditController.selectedBgIndex.value]
            : content.bgGradient;

        return RepaintBoundary(
          key: textController.previewContainer,
          child: ColorFiltered(
            colorFilter:
                ColorFilter.matrix(cameraEditController.selectedFilter.value),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: isTextStory ? gradient : null,
                color: isTextStory ? null : blackPure(context),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (!isTextStory && (content.content ?? '').isNotEmpty)
                    Positioned.fill(
                      child: Image.file(
                        File(content.content!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (!isTextStory && gradient != null)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ...textController.texts.map(
                    (item) => _DraggableStoryText(
                      item: item,
                      selected: textController.selectedTextId.value == item.id,
                      onSelect: () => textController.selectText(item.id),
                      onDrag: (delta) =>
                          textController.updateOffset(item.id, delta),
                    ),
                  ),
                  if (textController.texts.isEmpty && isTextStory)
                    Center(
                      child: Text(
                        'Aa',
                        style: TextStyleCustom.unboundedSemiBold600(
                          color: whitePure(context).withValues(alpha: 0.55),
                          fontSize: AppRes.minFontSize + 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DraggableStoryText extends StatelessWidget {
  final StoryTextItem item;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onDrag;

  const _DraggableStoryText({
    required this.item,
    required this.selected,
    required this.onSelect,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20 + item.offset.dx,
      top: 120 + item.offset.dy,
      right: 20,
      child: GestureDetector(
        onTap: onSelect,
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: selected
              ? BoxDecoration(
                  border: Border.all(
                    color: whitePure(context).withValues(alpha: 0.7),
                  ),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: TextField(
            controller: item.controller,
            focusNode: item.focusNode,
            onTap: onSelect,
            maxLines: null,
            textAlign: TextAlign.center,
            cursorColor: whitePure(context),
            style: TextStyleCustom.unboundedSemiBold600(
              color: item.color,
              fontSize: item.fontSize,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              hintText: 'Aa',
              hintStyle: TextStyleCustom.unboundedSemiBold600(
                color: Colors.white54,
                fontSize: AppRes.minFontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
