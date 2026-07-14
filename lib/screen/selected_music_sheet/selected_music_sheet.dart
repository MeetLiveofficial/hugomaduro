import 'package:flutter/material.dart';
import 'package:krimson/screen/selected_music_sheet/selected_music_sheet_controller.dart';

class SelectedMusicSheet extends StatelessWidget {
  final SelectedMusic selectedMusic;
  final int totalVideoSecond;

  const SelectedMusicSheet({
    super.key,
    required this.selectedMusic,
    required this.totalVideoSecond,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(child: Text('SelectedMusicSheet')),
    );
  }
}
