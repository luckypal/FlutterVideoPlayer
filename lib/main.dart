import 'package:flutter/material.dart';
import 'package:gplayer/gplayer.dart';

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

  GPlayer player;

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
      ..addListener((params) {
        setState(() {
        });
      });
  }

  @override
  void dispose() {
    player?.dispose();
    super.dispose();
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
              icon: Icon(Icons.pause),
              color: Colors.white,
              iconSize: buttonHeight,
              onPressed: () {
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
              "0.49",
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
                  max: 15.0,
                  onChanged: (value) {
                  },
                  value: 5,
                ),
              ),
            ),
            Text(
              "1.49",
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
    double buttonHeight = MediaQuery.of(context).size.width * 0.07;

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
