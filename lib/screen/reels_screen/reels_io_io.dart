import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController? createLocalVideoController(String path) {
  if (path.isEmpty) return null;
  return VideoPlayerController.file(File(path));
}
