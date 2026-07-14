import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/model/post_story/music/music_model.dart';

class AudioDetailsScreen extends StatelessWidget {
  /// Call sites pass an [Rx] (e.g. from audio_sheet).
  final Rx<Music?>? music;

  const AudioDetailsScreen({super.key, this.music});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('AudioDetailsScreen')),
    );
  }
}
