import 'package:get/get.dart';
import 'package:krimson/model/post_story/music/music_model.dart';

class SelectedMusic {
  Music? music;
  int? audioStartMS;
  String? downloadedURL;
  int? totalVideoSecond;

  SelectedMusic(
    this.music, [
    this.audioStartMS,
    this.downloadedURL,
    this.totalVideoSecond,
  ]);
}

class SelectedMusicSheetController extends GetxController {}
