import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hlsvideoplayer/videoitem.dart';
import 'package:video_player/video_player.dart';
import 'package:m3u/m3u.dart';
// import 'package:media_notification_control/media_notification.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:connectivity/connectivity.dart';

import 'hlsvideoplayer.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  String sampleUrl;

  App({ Key key }) : super(key: key) {
    sampleUrl = "https://d9nq9lwzqhczf.cloudfront.net/1df51bf8-c868-47ef-b53a-5ba0010fa6ed/hls/video-3.m3u8?Expires=1613556544&Signature=S53CqJfhLVYWb6wpmJ3YRmPxtLwgA1TtDUq2XHzRcdHehLHun7N5i0eevcG~NWVCVkZ5R4OXag6v11omuTTP~yfSqYpeWplaFdwSx55XdgcnAsoSkBeRziokt~yBM8cmNUHjL2gmWAN4tEsK2qctpmhHx3Na29JchP~4Iz3z~UyM10wmhgTidpqGo6~V-cZovujhBSpbnjSJ-Ubl0kib2PYy47iS2B5ntEebak~oxNSWmlD6XG8XUuUnSL9ISL-GURSll~xRv7Ro1lprBrBYn5nOs-pv6wKWwI5maBNEeA9pcDzrBBsJzhElkCEybnIfMfm0FpKlUtzdPfWBaETTMQ__&Key-Pair-Id=APKAIIGAWAHJPV7RP5MA";
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HLS video player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              children: <Widget>[
                VideoContainer(
                  playlistUrl: sampleUrl
                )
              ],
            ),
          ),
        )
      )
    );
  }
}

class VideoContainer extends StatefulWidget {
  VideoContainer({
    Key key,
    @required this.playlistUrl
  }) : super(key: key);

  final String playlistUrl;

  @override
  _VideoContainerState createState() => _VideoContainerState();
}

class LifecycleEventHandler extends WidgetsBindingObserver {
  LifecycleEventHandler({this.resumeCallBack, this.suspendingCallBack, this.detachedCallBack});

  final AsyncCallback resumeCallBack;
  final AsyncCallback suspendingCallBack;
  final AsyncCallback detachedCallBack;

  @override
  Future<Null> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        await suspendingCallBack();
        print("inactive");
        break;
      case AppLifecycleState.paused:
        await suspendingCallBack();
        print("paused");
        break;
      case AppLifecycleState.detached:
        print("detached");
        await detachedCallBack();
        break;
      case AppLifecycleState.resumed:
        print("resume");
        await resumeCallBack();
        break;
    }
  }
}

class _VideoContainerState extends State<VideoContainer>
    with SingleTickerProviderStateMixin {
  // AnimationController _controller;

  List<VideoItem> playList = [];
  HLSVideoPlayerController videoPlayerController;
  
  @override
  void initState() {
    super.initState();
    // _controller = AnimationController(vsync: this);
    new HttpClient().getUrl(Uri.parse(widget.playlistUrl))
    .then((HttpClientRequest request) => request.close())
    .then((HttpClientResponse response) => response.transform(new Utf8Decoder()).listen((playlistContent) {      
      M3uParser.parse(playlistContent)
      .then((List<M3uGenericEntry> list) {
        initVideoPlayerController(list);
      });
    }));

    
    WidgetsBinding.instance.addObserver(
      new LifecycleEventHandler(
        resumeCallBack: () {
          // videoPlayerController.isActive = true;
          this.hideNotification();
        },
        suspendingCallBack: () {
          // videoPlayerController.isActive = false;
          this.showNotification("HLS Video Player", "Motivational Video for getting things DONE!");
        },
        detachedCallBack: () {
          this.hideNotification();
        })
    );
    
    MediaNotification.setListener('pause', () {
      setState(() => videoPlayerController.videoController.pause());
    });

    MediaNotification.setListener('play', () {
      setState(() => videoPlayerController.videoController.play());
    });
    
    MediaNotification.setListener('next', () {
      
    });

    MediaNotification.setListener('prev', () {
      
    });

    MediaNotification.setListener('select', () {
      
    });
  }
  
  Future<void> hideNotification() async {
    try {
      await MediaNotification.hideNotification();
      // setState(() => status = 'hidden');
  } on PlatformException {

    }
  }

  Future<void> showNotification(title, author) async {
    try {
      await MediaNotification.showNotification(title: title, author: author, isPlaying: videoPlayerController.videoController.value.isPlaying);
      // setState(() => status = 'play');
    } on PlatformException {

    }
  }

  initVideoPlayerController(List<M3uGenericEntry> list) async {
    Uri uri = Uri.parse(widget.playlistUrl);
    String path = uri.origin + uri.path;
    String directory = path.substring(0, path.lastIndexOf("/") + 1);

    List<VideoItem> pList = [];

    list.forEach((item) {
      if (item.title == "") return;

      String resolution = "";
      var attributes = item.title.split(",");
      attributes.forEach((attr) {
        const String RESOLUTION = "RESOLUTION=";
        if (attr.startsWith(RESOLUTION))
          resolution = attr.substring(RESOLUTION.length, attr.length);
      });

      pList.add(new VideoItem(
        m3uItem: item,
        resoultion: resolution,
        videoUri: directory + item.link
      ));
    });

    int index = 0;
    var connectivityResult = await (Connectivity().checkConnectivity());
    switch (connectivityResult) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.none: index = 0; break;
      case ConnectivityResult.mobile: index = pList.length - 1; break;
    }
    VideoPlayerController videoPlayerController;
    videoPlayerController = VideoPlayerController.network(pList [index].videoUri);
    videoPlayerController.initialize();
    videoPlayerController.setLooping(true);
    videoPlayerController.play();

    setState(() {
      playList = pList;
        
      this.videoPlayerController = new HLSVideoPlayerController(
        curPlaylistIndex: index,
        playList: playList,
        videoController: videoPlayerController
      );
    });
  }

  @override
  void dispose() {
    this.hideNotification();
    super.dispose();
    // _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: playList.length == 0 ?
        CircularProgressIndicator()
        : HLSVideoPlayer(
          playList: playList,
          controller: videoPlayerController,
          isFullScreenScreen: false,
        ),
    );
  }
}
