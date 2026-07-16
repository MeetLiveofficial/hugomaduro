import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/functions/generate_color.dart';
import 'package:krimson/utilities/app_res.dart';

class StoryTextItem {
  StoryTextItem({
    required this.id,
    required this.controller,
    required this.focusNode,
    this.offset = Offset.zero,
    this.fontSize = AppRes.minFontSize,
    Color? color,
  }) : color = color ?? GenerateColor.instance.fontColor.last;

  final int id;
  final TextEditingController controller;
  final FocusNode focusNode;
  Offset offset;
  double fontSize;
  Color color;
}

class StoryTextViewController extends GetxController {
  final GlobalKey previewContainer = GlobalKey();
  final RxList<StoryTextItem> texts = <StoryTextItem>[].obs;
  final RxInt selectedTextId = (-1).obs;
  final RxInt selectedFontColorIndex =
      (GenerateColor.instance.fontColor.length - 1).obs;

  int _nextId = 0;

  @override
  void onClose() {
    for (final item in texts) {
      item.controller.dispose();
      item.focusNode.dispose();
    }
    super.onClose();
  }

  void addTextField({String initialText = ''}) {
    final item = StoryTextItem(
      id: _nextId++,
      controller: TextEditingController(text: initialText),
      focusNode: FocusNode(),
      color: GenerateColor
          .instance.fontColor[selectedFontColorIndex.value.clamp(
        0,
        GenerateColor.instance.fontColor.length - 1,
      )],
    );
    texts.add(item);
    selectedTextId.value = item.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      item.focusNode.requestFocus();
    });
  }

  void selectText(int id) {
    selectedTextId.value = id;
  }

  void updateOffset(int id, Offset delta) {
    final index = texts.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final item = texts[index];
    item.offset += delta;
    texts.refresh();
  }

  void changeSelectedFontColor() {
    final colors = GenerateColor.instance.fontColor;
    selectedFontColorIndex.value =
        (selectedFontColorIndex.value + 1) % colors.length;
    final selected = texts.firstWhereOrNull((e) => e.id == selectedTextId.value);
    if (selected == null) return;
    selected.color = colors[selectedFontColorIndex.value];
    texts.refresh();
  }

  void deleteSelectedText() {
    final id = selectedTextId.value;
    final index = texts.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final item = texts.removeAt(index);
    item.controller.dispose();
    item.focusNode.dispose();
    selectedTextId.value = texts.isEmpty ? -1 : texts.last.id;
  }
}
