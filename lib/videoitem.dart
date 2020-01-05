import 'package:m3u/m3u.dart';
import 'package:video_player/video_player.dart';

class VideoItem {
  VideoItem({
    this.m3uItem,
    this.resoultion,
    this.videoUri,
  }) : videoController = null;
  
  final M3uGenericEntry m3uItem;
  final String resoultion;
  final String videoUri;

  VideoPlayerController videoController;
}