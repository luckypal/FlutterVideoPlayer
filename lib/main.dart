import 'package:flutter/material.dart';
import 'package:gplayer/gplayer.dart';
import 'dart:async';
import 'package:sprintf/sprintf.dart';

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
                VideoPlayer(),
              ],
            ),
          ),
        )
      )
    );
  }
}

class VideoPlayer extends StatefulWidget {
  VideoPlayer({Key key}) : super(key: key);

  @override
  VideoPlayerState createState() => VideoPlayerState();
}

class VideoPlayerState extends State<VideoPlayer> {
  final Color controlColor = Color(0xFFF2622A);

  Timer _timer;
  GPlayer player;
  double currentVideoPosition = 0;

  @override
  void initState() {
    super.initState();
    //1.create & init player
    player = GPlayer(
      uri: 'http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4',
      backgroudColor: Colors.grey,
      looping: true,
      )
      ..init()
      ..addListener((_) {
      });

    startTimer();
  }

  @override
  void dispose() {
    player?.dispose();
    _timer.cancel();
    super.dispose();
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(() {
        this.setState((){
          player.currentPosition.then((value) {
            currentVideoPosition = value.inSeconds.toDouble();
          });
        });
      }),
    );
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
              onPressed: () {
              },
              child: Text("1.0 X",
                style: TextStyle(
                  color: controlColor,
                ),),
            ),
            MaterialButton(
              padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
              minWidth: 0,
              onPressed: () {
              },
              child: Text("720P",
                style: TextStyle(
                  color: controlColor,
                ),),
            ),
            IconButton(
              padding: EdgeInsets.all(0),
              icon: Icon(Icons.more_vert),
              color: this.controlColor,
              onPressed: () {
              },
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
              onPressed: () {
              },
            ),
            IconButton(
              padding: EdgeInsets.all(0),
              icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow),
              color: Colors.white,
              iconSize: buttonHeight,
              onPressed: () {
                if (!player.isPlaying)
                  player.start();
                else
                  player.pause();
              },
            ),
            IconButton(
              padding: EdgeInsets.all(0),
              icon: Icon(Icons.rotate_right),
              color: Colors.white,
              iconSize: buttonHeight,
              onPressed: () {
              },
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
            IconButton(
              splashColor: Colors.pink,
              padding: EdgeInsets.all(0),
              icon: Icon(Icons.bookmark_border),
              color: this.controlColor,
              iconSize: buttonHeight,
              onPressed: () {
              },
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
                  max: player.duration.inSeconds.toDouble(),
                  onChanged: (value) {
                    currentVideoPosition = value;
                  },
                  onChangeStart: (value) {
                    // _timer.cancel();
                  },
                  onChangeEnd: (value) {
                    setState(() {
                      player.seekTo(value.toInt() * 1000);
                    });
                    // startTimer();
                  },
                  value: currentVideoPosition
                ),
              ),
            ),
            Text(
              getTimeString(player.duration.inSeconds.toDouble()),
              style: TextStyle(
                color: controlColor,
              ),
            ),
            IconButton(
              padding: EdgeInsets.all(0),
              icon: Icon(Icons.zoom_out_map),
              color: this.controlColor,
              iconSize: buttonHeight,
              onPressed: () {
              },
            ),
          ],
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double videoHeight = MediaQuery.of(context).size.width * 0.75;

    return Stack(
      children: [
        Container(
          color: Colors.black,
          height: videoHeight,
          child: player.display,
        ),

        Container(
          height: MediaQuery.of(context).size.width * 0.75,
          child: Container(
            color: Colors.black45,
            height: MediaQuery.of(context).size.width * 0.75,
          ),
        ),

        topBarWidgets(),

        middleWidgets(),

        bottomWidgets()
      ]
    );
  }
}
