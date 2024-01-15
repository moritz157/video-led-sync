import 'dart:async';
import 'dart:html';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late VideoPlayerController _controller;
  bool isFullscreen = false;

  late WebSocketChannel channel;

  @override
  void initState() {
    super.initState();

    channel = WebSocketChannel.connect(Uri.parse("ws://localhost:8000"));

    _controller = VideoPlayerController.networkUrl(Uri.parse(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.

        setState(() {});

        Timer.periodic(const Duration(milliseconds: 10), (timer) async {
          if (isFullscreen != (document.fullscreenElement != null)) {
            setState(() {
              isFullscreen = document.fullscreenElement != null;
            });
          }
          if (_controller.value.isPlaying) {
            // print(await _controller.position);
            sendVideoPosition(await _controller.position);
          }
        });
        // _controller.addListener(() {
        //   _controller.position.then((value) => print(value));
        // });
      })
      ..setLooping(true);
  }

  Future<void> sendVideoPosition(Duration? duration) async {
    await channel.ready;
    // channel.sink
    //     .add(((duration?.inMilliseconds ?? 0) / 4200 * 255).round().toString());
    channel.sink.add(ByteData(2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !isFullscreen
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(widget.title),
              actions: [
                IconButton(
                    onPressed: () {
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                          overlays: []);
                      if (kIsWeb) {
                        document.documentElement?.requestFullscreen();
                        // document.documentElement?.onFullscreenChange.capture((event) {print(event.)})
                      }
                    },
                    icon: const Icon(Icons.fullscreen)),
                IconButton(
                    onPressed: () {
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                          overlays: SystemUiOverlay.values);
                      if (kIsWeb) {
                        document.exitFullscreen();
                      }
                    },
                    icon: const Icon(Icons.fullscreen_exit))
              ],
            )
          : null,
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : Container(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
