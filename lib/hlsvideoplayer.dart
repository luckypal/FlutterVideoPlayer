import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hlsvideoplayer/videoitem.dart';
import 'package:video_player/video_player.dart';
import 'package:sprintf/sprintf.dart';
import 'package:wakelock/wakelock.dart';

class HLSVideoPlayer extends StatefulWidget {
  HLSVideoPlayer({
    Key key,
    this.playList,
    this.controller,
    @required this.isFullScreenScreen,
  }): super(key: key);

  int curPlaylistIndex = -1;
  final List<VideoItem> playList;
  HLSVideoPlayerController controller;
  final bool isFullScreenScreen;

  @override
  HLSVideoPlayerState createState() => HLSVideoPlayerState();
}

class HLSVideoPlayerState extends State<HLSVideoPlayer> {
  final Color controlColor = Color(0xFFF2622A);

  @override
  void initState() {
    super.initState();
    
    startTimer();
    startOneshotTimer();
  }

  @override
  void deactivate() {
    widget.controller.videoController.setVolume(1.0);
    super.deactivate();
  }

  @override
  void dispose() {
    if (!widget.isFullScreenScreen) {
      widget.controller.videoController.dispose();
      widget.controller.timer.cancel();
      stopOneshotTimer();
    }
    super.dispose();
  }
  

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    widget.controller.timer = new Timer.periodic(
      oneSec,
      (Timer timer) =>
        setState(() {
          // if (!widget.controller.isActive) {
            // widget.controller.videoController.play();
          // }
          this.setState((){
            widget.controller.currentVideoPosition = widget.controller.videoController.value.position.inSeconds.toDouble();
          });
      }),
    );
  }

  void startOneshotTimer() {
    stopOneshotTimer();

    var future = new Future.delayed(const Duration(seconds: 4));
    widget.controller.autoHideControls = future.asStream().listen((data) {
      setState(() {
        widget.controller.isShowControls = false;
      });
      widget.controller.autoHideControls.cancel();
      widget.controller.autoHideControls = null;
    });
  }

  void stopOneshotTimer() {
    widget.controller.isShowQualityList = false;
    widget.controller.isShowSpeedList = false;

    if (widget.controller.autoHideControls != null)
      widget.controller.autoHideControls.cancel();
  }

  String getTimeString(double second) {
    int hours = (second ~/ 3600).toInt();
    int mins = (second % 3600 ~/ 60).toInt();
    int seconds = (second % 60).toInt();

    String returnValue = "";
    if (hours > 0)
      returnValue += sprintf("%02i:", [hours]);

    returnValue += sprintf("%02i:", [mins]);
    returnValue += sprintf("%02i", [seconds]);

    return returnValue;
  }

  Widget getDropdownWidgets(List items, String suffix, bool isShow, Function onPressItem) {
    List<Widget> widgets = <Widget>[];
    double itemHeight = MediaQuery.of(context).size.width * 0.14;
    double widgetHeight = MediaQuery.of(context).size.width * 0.3;

    double innerHeight = (26 * items.length).toDouble();

    items.forEach((item) {
      MaterialButton button = MaterialButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        height: 0,
        padding: EdgeInsets.fromLTRB(7, 5, itemHeight, 5),
        minWidth: 0,
        onPressed: () {onPressItem(item);},
        child: Text(item.toString() + suffix,
          style: TextStyle(
            color: controlColor,
          )
        )
      );

      widgets.add(button);
    });

    return AnimatedContainer(
      height: isShow ? min(widgetHeight, innerHeight) : 0,
      color: Colors.black54,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: widgets,
        )
      ),
      duration: Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  void onPressOverlay() {
    setState(() {
      if (!widget.controller.isShowQualityList
        && !widget.controller.isShowSpeedList)
        widget.controller.isShowControls = !widget.controller.isShowControls;

      if (widget.controller.isShowControls)
        startOneshotTimer();
      else stopOneshotTimer();
    });
  }

  void onPressSpeedBtn() {
    startOneshotTimer();
    setState(() {
      widget.controller.isShowSpeedList = !widget.controller.isShowSpeedList;
    });
  }

  void onPressQualityBtn() {
    stopOneshotTimer();
    setState(() {
      widget.controller.isShowQualityList = !widget.controller.isShowQualityList;
    });
  }

  void onSetQuality(String quality) {
    int index = -1, i = 0;
    widget.controller.playList.forEach((item) {
      if (item.resoultion == quality)
        index = i;
      else i ++;
    });

    if (widget.controller.curPlaylistIndex == index) {
      startOneshotTimer();
      return;
    }

    setState(() async {
      widget.controller.isAutoSelectedQuality = false;
      int oldIndex = widget.controller.curPlaylistIndex;
      double curPosition = widget.controller.currentVideoPosition;

      widget.controller.curPlaylistIndex = index;
      widget.controller.isShowQualityList = false;
      widget.controller.videoController.pause();
      widget.playList [oldIndex].videoController = widget.controller.videoController;

      VideoItem curPlayItem = widget.playList [index];
      if (curPlayItem.videoController != null) {
        widget.controller.videoController = curPlayItem.videoController;
      } else {
        widget.controller.videoController = VideoPlayerController.network(curPlayItem.videoUri);
        await widget.controller.videoController.initialize();
        await widget.controller.videoController.setLooping(true);
      }
      await widget.controller.videoController.initialize();
      await widget.controller.videoController.setLooping(true);
      await widget.controller.videoController.play();
      await widget.controller.videoController.seekTo(Duration(seconds: curPosition.toInt()));
      await widget.controller.videoController.setSpeed(widget.controller.videoSpeed);
      startOneshotTimer();
    });
  }

  void onSetSpeed(double speed) {
    widget.controller.videoController.setSpeed(speed);

    setState(() {
      widget.controller.videoSpeed = speed;
      widget.controller.isShowSpeedList = false;
      startOneshotTimer();
    });
  }

  void onPressOptionBtn() {
    startOneshotTimer();
  }

  void seekVideo(int seconds) {
    widget.controller.videoController.seekTo(widget.controller.videoController.value.position + Duration(seconds: seconds));
    startOneshotTimer();
  }

  void onPressPlayBtn() {
    if (!widget.controller.videoController.value.isPlaying)
      widget.controller.videoController.play();
    else
      widget.controller.videoController.pause();
      
    startOneshotTimer();
  }

  void onPressBookmarkBtn() {
    startOneshotTimer();
  }

  void onPressFullScreenBtn() {
    startOneshotTimer();
    setState(() {
      enterFullScreen();
    });
  }

  void enterFullScreen() {
    if (!widget.controller.isFullScreen) {
      widget.controller.isFullScreen = true;
      pushFullScreenWidget();
    } else {
      widget.controller.isFullScreen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  bool isShowOverlay() {
    if (!widget.controller.isShowControls) return false;
    return widget.controller.isShowControls
          || !widget.controller.videoController.value.isPlaying
          || widget.controller.videoController.value.isBuffering;
  }

  bool isShowControl() {
    if (widget.controller.videoController.value.isBuffering) return false;
    return isShowOverlay();
  }

  Widget topBarWidgets() {
    return Align(
      alignment: Alignment.topRight,
      child: Column(
        children: [
          Row(
            children: <Widget>[
              Expanded(
                child: Container(),
              ),
              MaterialButton(
                padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                minWidth: 0,
                onPressed: onPressSpeedBtn,
                child: Text(widget.controller.videoSpeed.toString() + " X",
                  style: TextStyle(
                    color: controlColor,
                  ),),
              ),
              MaterialButton(
                padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                minWidth: 0,
                onPressed: onPressQualityBtn,
                child: Text(getVideoQualityString(),
                  style: TextStyle(
                    color: controlColor,
                  ),),
              ),
              MaterialButton(
                padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                minWidth: 0,
                onPressed: onPressOptionBtn,
                child: Icon(
                  Icons.more_vert,
                  color: controlColor,
                ),
              ),
            ]
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Container(),
              ),
              getDropdownWidgets(widget.controller.videoSpeeds, " X", widget.controller.isShowSpeedList, onSetSpeed),
              getDropdownWidgets(widget.controller.videoQualities, "P", widget.controller.isShowQualityList, onSetQuality)
            ]
          )
        ],
      ),
    );
  }

  getVideoQualityString() {
    String quality = widget.controller.videoQualities [widget.controller.curPlaylistIndex];
    if (widget.controller.isAutoSelectedQuality)
      return "Auto (" + quality + ")";
    return quality;
  }

  Widget middleWidgets() {
    double buttonHeight = MediaQuery.of(context).size.width * 0.1;

    return Container(
      height: MediaQuery.of(context).size.width * 0.75,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              padding: EdgeInsets.all(0),
              icon: Icon(Icons.rotate_left),
              color: Colors.white,
              iconSize: buttonHeight,
              onPressed: () {seekVideo(-10);},
            ),
            IconButton(
              padding: EdgeInsets.all(0),
              icon: Icon(widget.controller.videoController.value.isPlaying ? Icons.pause : Icons.play_arrow),
              color: Colors.white,
              iconSize: buttonHeight,
              onPressed: onPressPlayBtn,
            ),
            IconButton(
              padding: EdgeInsets.all(0),
              icon: Icon(Icons.rotate_right),
              color: Colors.white,
              iconSize: buttonHeight,
              onPressed: () {seekVideo(10);},
            ),
          ],
        )
      ),
    );
  }

  Widget bottomWidgets() {
    double buttonHeight = MediaQuery.of(context).size.width * 0.07;

    return Container(
      height: MediaQuery.of(context).size.width * 0.75,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          children: <Widget>[
            MaterialButton(
              padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
              minWidth: 0,
              onPressed: onPressBookmarkBtn,
              child: Icon(
                Icons.bookmark_border,
                color: controlColor,
              ),
            ),
            Text(
              getTimeString(widget.controller.currentVideoPosition),
              style: TextStyle(
                color: controlColor,
              ),
            ),
            Expanded(
              child: Container(
                height: buttonHeight,
                child: Slider(
                  activeColor: controlColor,
                  inactiveColor: Colors.grey,
                  min: 0.0,
                  max: widget.controller.videoController.value.initialized ? widget.controller.videoController.value.duration.inSeconds.toDouble() : 0,
                  onChanged: (value) {
                    widget.controller.currentVideoPosition = value;
                  },
                  onChangeStart: (value) {
                    stopOneshotTimer();
                  },
                  onChangeEnd: (value) {
                    widget.controller.videoController.seekTo(Duration(seconds: value.toInt()));
                    stopOneshotTimer();
                  },
                  value: widget.controller.currentVideoPosition
                ),
              ),
            ),
            Text(
              getTimeString(widget.controller.videoController.value.initialized ? widget.controller.videoController.value.duration.inSeconds.toDouble() : 0),
              style: TextStyle(
                color: controlColor,
              ),
            ),
            MaterialButton(
              padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
              minWidth: 0,
              onPressed: onPressFullScreenBtn,
              child: Icon(
                Icons.zoom_out_map,
                color: controlColor,
              ),
            ),
          ],
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double videoHeight = width * 0.75;
    double borderRadius = width * 0.03;

    return ClipRRect(
      borderRadius:  BorderRadius.only(
        bottomLeft: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius)
      ),
      child: Stack(
        children: [
          Container(
            height: videoHeight,
            child: VideoPlayer(widget.controller.videoController)
          ),

          GestureDetector(
            onTap: onPressOverlay,
            child: AnimatedContainer(
              height: MediaQuery.of(context).size.width * 0.75,
              color: isShowOverlay() ? Colors.black45 : Colors.transparent,
              duration: Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
              child: widget.controller.videoController.value.isBuffering ? Center(
                child: CircularProgressIndicator(),
              ) : null,
            )
          ),

          isShowControl() ?
          Stack(
            children: [
              bottomWidgets(),
              middleWidgets(),
              topBarWidgets(),
            ]
          ): Container(
              height: MediaQuery.of(context).size.width * 0.75
          )
        ]
      )
    );
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: HLSVideoPlayer(controller: widget.controller, isFullScreenScreen: true),
      ),
    );
  }

  Future<dynamic> pushFullScreenWidget() async {
    // final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final TransitionRoute<Null> route = PageRouteBuilder<Null>(
      settings: RouteSettings(isInitialRoute: false),
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    SystemChrome.setEnabledSystemUIOverlays([]);
    // if (isAndroid) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    // }

    widget.controller.isFullScreen = true;
      Wakelock.enable();

    await Navigator.of(context, rootNavigator: true).push(route);
    widget.controller.isFullScreen = false;

    Wakelock.disable();

    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
}

class HLSVideoPlayerController {
  HLSVideoPlayerController({
    this.curPlaylistIndex,
    this.playList,
    this.videoController,
  }) : assert(videoController != null,
            'You must provide a controller to play a video') {
    _initialize();
  }

  int curPlaylistIndex = -1;
  final List<VideoItem> playList;
  VideoPlayerController videoController;
  Timer timer; //Used for updating slider.
  StreamSubscription<dynamic> autoHideControls;
  double currentVideoPosition = 0;
  bool isShowControls = true;

  bool isShowQualityList = false;
  List<String> videoQualities = [];
  bool isAutoSelectedQuality = true;

  bool isShowSpeedList = false;
  double videoSpeed = 1;
  List<double> videoSpeeds = [0.5, 1, 2];

  bool isFullScreen = false;
  // bool isActive = true;
  
  Future _initialize() async {
    videoQualities = [];
    playList.forEach((item) {
      videoQualities.add(item.resoultion);
    });
  }
}
