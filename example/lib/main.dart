import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _progress = "0";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Progress $_progress',
              style: Theme.of(context).textTheme.headline4,
            ),
            InkWell(
                child: Icon(
                  Icons.cancel,
                  size: 55,
                ),
                onTap: () {
                  VideoCompress.cancelCompression();
                })
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var startTime = DateTime.now();
          var file;
          var originalSize = 0;
          var originalWidth = 0;
          var originalHeigth = 0;

          final picker = ImagePicker();
          PickedFile pickedFile =
          await picker.getVideo(source: ImageSource.gallery);
          file = File(pickedFile.path);
          if (file == null) {
            return;
          }

          originalSize = await file.length();
          var a = await FlutterVideoInfo().getVideoInfo(pickedFile.path);
          originalWidth = a.width;
          originalHeigth = a.height;

          await VideoCompress.setLogLevel(0);
          final infoFuture = VideoCompress.compressVideo(
            file.path,
            width: 640,
            height: 640,
            deleteOrigin: false,
            includeAudio: true,
          );
          var _subscription =
          VideoCompress.compressProgress$.subscribe((progress) {
            setState(() {
              _progress = '${progress.toInt().toString()}%';
            });
          });
          final info = await infoFuture;
          _subscription.unsubscribe();
          var conversionTime =
          DateTimeRange(start: startTime, end: DateTime.now());
          setState(() {
            _progress = "0";
          });
          print(info.path);
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                  info: info,
                  originalSize: originalSize,
                  originalWidth: originalWidth,
                  originalHeigth: originalHeigth,
                  duration: conversionTime)));
        },
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final MediaInfo info;
  final int originalSize;
  final int originalWidth;
  final int originalHeigth;
  final DateTimeRange duration;

  VideoPlayerScreen(
      {Key key,
      this.info,
      this.originalSize,
      this.originalWidth,
      this.originalHeigth,
      this.duration})
      : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compressed Video'),
      ),
      // Use a FutureBuilder to display a loading spinner while waiting for the
      // VideoPlayerController to finish initializing.
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the VideoPlayerController has finished initialization, use
            // the data it provides to limit the aspect ratio of the video.
            return Stack(
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  // Use the VideoPlayer widget to display the video.
                  child: VideoPlayer(_controller),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      color: Color.fromRGBO(100, 100, 100, 0.5),
                      width: MediaQuery.of(context).size.width,
                      height: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                              'Video length ${(widget.info.duration / 1000).toInt()} Seconds'),
                          Text(
                            'Original size: ${(widget.originalSize / 1000000).toString()}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Original width: ${(widget.originalWidth).toString()}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Original height: ${(widget.originalHeigth).toString()}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Converted size: ${(widget.info.filesize / 1000000).toString()}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Converted width: ${(widget.info.width).toString()}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Converted height: ${(widget.info.height).toString()}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Conversion duration: ${(widget.duration.duration.inSeconds).toString()}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            );
          } else {
            // If the VideoPlayerController is still initializing, show a
            // loading spinner.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Wrap the play or pause in a call to `setState`. This ensures the
          // correct icon is shown.
          setState(() {
            // If the video is playing, pause it.
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              // If the video is paused, play it.
              _controller.play();
            }
          });
        },
        // Display the correct icon depending on the state of the player.
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _controller.dispose();

    super.dispose();
  }

  @override
  void initState() {
    // Create and store the VideoPlayerController. The VideoPlayerController
    // offers several different constructors to play videos from assets, files,
    // or the internet.
    _controller = VideoPlayerController.file(File(widget.info.path));

    // Initialize the controller and store the Future for later use.
    _initializeVideoPlayerFuture = _controller.initialize();

    // Use the controller to loop the video.
    _controller.setLooping(true);

    super.initState();
  }
}