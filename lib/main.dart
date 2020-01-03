import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
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

  HLSVideoPlayerState() {
    listener = () {
      SchedulerBinding.instance.addPostFrameCallback((_) => setState(() {}));
    };
  }

  @override
  void initState() {
    super.initState();
    //1.create & init player
    _videoController = VideoPlayerController.network('https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4');
    
    _videoController.initialize();
    _videoController.addListener(listener);
    _videoController.setLooping(true);
    _videoController.setVolume(1);
    _videoController.play();

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
      isShowControls = false;
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

  void onPressSpeedBtn() {
    startOneshotTimer();
  }

  void onPressQualityBtn() {
    startOneshotTimer();
  }

  void onPressOptionBtn() {
    startOneshotTimer();
  }

  void seekVideo(int seconds) {
    _videoController.seekTo(_videoController.value.position + Duration(seconds: seconds));
    startOneshotTimer();
  }

  void onPressBookmarkBtn() {
    startOneshotTimer();
  }

  void onPressFullScreenBtn() {
    startOneshotTimer();
  }

  Widget topBarWidgets() {
    double iconButtonHeight = MediaQuery.of(context).size.width * 0.1;

    return Center(
      child: Container(
        height: iconButtonHeight,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(),
            ),
            MaterialButton(
              padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
              minWidth: 0,
              onPressed: onPressSpeedBtn,
              child: Text("1.0 X",
                style: TextStyle(
                  color: controlColor,
                ),),
            ),
            MaterialButton(
              padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
              minWidth: 0,
              onPressed: onPressQualityBtn,
              child: Text("720P",
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
              onPressed: () {
                if (!_videoController.value.isPlaying)
                  _videoController.play();
                else
                  _videoController.pause();
                  
                startOneshotTimer();
              },
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
                    // _timer.cancel();
                    stopOneshotTimer();
                  },
                  onChangeEnd: (value) {
                    setState(() {
                      _videoController.seekTo(Duration(seconds: value.toInt()));
                    });
                    stopOneshotTimer();
                    // startTimer();
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

  bool isShowOverlay() {
    if (!isShowControls) return false;
    return isShowControls || !_videoController.value.isPlaying || _videoController.value.isBuffering;
  }

  bool isShowControl() {
    if (_videoController.value.isBuffering) return false;
    return isShowOverlay();
  }

  @override
  Widget build(BuildContext context) {
    double videoHeight = MediaQuery.of(context).size.width * 0.75;

    return Stack(
      children: [
        Container(
          height: videoHeight,
          child: VideoPlayer(_videoController)
        ),

        GestureDetector(
          onTap: () {
            isShowControls = !isShowControls;
            if (isShowControls)
              startOneshotTimer();
            else stopOneshotTimer();
          },
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
            topBarWidgets(),

            middleWidgets(),

            bottomWidgets()
          ]
        ): Container(
            height: MediaQuery.of(context).size.width * 0.75
        )
      ]
    );
  }
}
