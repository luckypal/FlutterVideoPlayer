import 'package:m3u/m3u.dart';

class VideoItem {
  VideoItem({
    this.m3uItem,
    this.resoultion,
    this.videoUri,
  });
  
  final M3uGenericEntry m3uItem;
  final String resoultion;
  final String videoUri;
}