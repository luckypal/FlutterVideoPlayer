import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'dart:math';
import 'package:sprintf/sprintf.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(App());

class App extends StatelessWidget {
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
                HLSVideoPlayer(),
              ],
            ),
          ),
        )
      )
    );
  }
}

class HLSVideoPlayer extends StatefulWidget {
  HLSVideoPlayer({Key key}) : super(key: key);

  @override
  HLSVideoPlayerState createState() => HLSVideoPlayerState();
}

class HLSVideoPlayerState extends State<HLSVideoPlayer> {
  final Color controlColor = Color(0xFFF2622A);

  Timer _timer; //Used for updating slider.
  StreamSubscription<dynamic> autoHideControls;
  VideoPlayerController _videoController;
  VoidCallback listener;
  double currentVideoPosition = 0;
  bool isShowControls = true;

  bool isShowQualityList = false;
  int videoQuality = 0;
  List<int> videoQualities = [];

  bool isShowSpeedList = false;
  double videoSpeed = 1;
  List<double> videoSpeeds = [];

  HLSVideoPlayerState() {
    listener = () {
      // SchedulerBinding.instance.addPostFrameCallback((_) => setState(() {}));
    };
  }

  @override
  void initState() {
    super.initState();
    //1.create & init player
    _videoController = VideoPlayerController.network('https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4');
    
    _videoController.initialize();
    // _videoController.addListener(listener);
    _videoController.setLooping(true);
    _videoController.setVolume(1);
    _videoController.play();

    videoQualities = [240, 360, 480, 720, 960];
    videoQuality = 720;
    
    videoSpeeds = [0.5, 1, 2];
    _videoController.setSpeed(videoSpeed);

    startTimer();
    startOneshotTimer();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _timer.cancel();
    stopOneshotTimer();
    super.dispose();
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(() {
        this.setState((){
          currentVideoPosition = _videoController.value.position.inSeconds.toDouble();
        });
      }),
    );
  }

  void startOneshotTimer() {
    stopOneshotTimer();

    var future = new Future.delayed(const Duration(seconds: 4));
    autoHideControls = future.asStream().listen((data) {
      setState(() {
        isShowControls = false;
      });
      autoHideControls.cancel();
      autoHideControls = null;
    });
  }

  void stopOneshotTimer() {
    if (autoHideControls != null)
      autoHideControls.cancel();
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
      if (!isShowQualityList)
        isShowControls = !isShowControls;
      isShowQualityList = false;

      if (isShowControls)
        startOneshotTimer();
      else stopOneshotTimer();
    });
  }

  void onPressSpeedBtn() {
    startOneshotTimer();
    setState(() {
      isShowSpeedList = !isShowSpeedList;
    });
  }

  void onPressQualityBtn() {
    stopOneshotTimer();
    setState(() {
      isShowQualityList = !isShowQualityList;
    });
  }

  void onSetQuality(int quality) {
    setState(() {
      videoQuality = quality;
      isShowQualityList = false;
      startOneshotTimer();
    });
  }

  void onSetSpeed(double speed) {
    _videoController.setSpeed(speed);

    setState(() {
      videoSpeed = speed;
      isShowSpeedList = false;
      startOneshotTimer();
    });
  }

  void onPressOptionBtn() {
    startOneshotTimer();
  }

  void seekVideo(int seconds) {
    _videoController.seekTo(_videoController.value.position + Duration(seconds: seconds));
    startOneshotTimer();
  }

  void onPressPlayBtn() {
    if (!_videoController.value.isPlaying)
      _videoController.play();
    else
      _videoController.pause();
      
    startOneshotTimer();
  }

  void onPressBookmarkBtn() {
    startOneshotTimer();
  }

  void onPressFullScreenBtn() {
    startOneshotTimer();
  }

  bool isShowOverlay() {
    if (!isShowControls) return false;
    return isShowControls || !_videoController.value.isPlaying || _videoController.value.isBuffering;
  }

  bool isShowControl() {
    if (_videoController.value.isBuffering) return false;
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
                child: Text(videoSpeed.toString() + " X",
                  style: TextStyle(
                    color: controlColor,
                  ),),
              ),
              MaterialButton(
                padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                minWidth: 0,
                onPressed: onPressQualityBtn,
                child: Text(videoQuality.toString() + "P",
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
              getDropdownWidgets(videoSpeeds, " X", isShowSpeedList, onSetSpeed),
              getDropdownWidgets(videoQualities, "P", isShowQualityList, onSetQuality)
            ]
          )
        ],
      ),
    );
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
              icon: Icon(_videoController.value.isPlaying ? Icons.pause : Icons.play_arrow),
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
              getTimeString(currentVideoPosition),
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
                  max: _videoController.value.initialized ? _videoController.value.duration.inSeconds.toDouble() : 0,
                  onChanged: (value) {
                    currentVideoPosition = value;
                  },
                  onChangeStart: (value) {
                    stopOneshotTimer();
                  },
                  onChangeEnd: (value) {
                    _videoController.seekTo(Duration(seconds: value.toInt()));
                    stopOneshotTimer();
                  },
                  value: currentVideoPosition
                ),
              ),
            ),
            Text(
              getTimeString(_videoController.value.initialized ? _videoController.value.duration.inSeconds.toDouble() : 0),
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
            child: VideoPlayer(_videoController)
          ),

          GestureDetector(
            onTap: onPressOverlay,
            child: AnimatedContainer(
              height: MediaQuery.of(context).size.width * 0.75,
              color: isShowOverlay() ? Colors.black45 : Colors.transparent,
              duration: Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
              child: _videoController.value.isBuffering ? Center(
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
}
