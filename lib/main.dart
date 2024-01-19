import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:video_led_sync/config_page.dart';
import 'package:video_led_sync/video_player.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fvp/fvp.dart';

void main() {
  registerWith();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: "Video LED-Sync",
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isFullscreen = false;
  File? videoFile;
  bool showVideoPlayer = false;

  late WebSocketChannel channel;

  @override
  void initState() {
    super.initState();

    channel = WebSocketChannel.connect(Uri.parse("ws://192.168.179.40:81"));
  }

  Future<void> sendVideoPosition(Duration? duration) async {
    await channel.ready;

    final List<int> data2 = [255, (((duration?.inMilliseconds ?? 0) % 4200) / 4200 * 255).round(), 0, 42];
    channel.sink.add(data2);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        child: showVideoPlayer
            ? AppVideoPlayer(
                videoFile!,
                onVideoPosition: (position) => sendVideoPosition(position),
                onExit: () => setState(() {
                  showVideoPlayer = false;
                }),
              )
            : ConfigPage(
                file: videoFile,
                onFilePicked: (filePicked) => setState(() {
                  videoFile = filePicked;
                }),
                onVideoStart: () => setState(() {
                  showVideoPlayer = true;
                }),
              ));
  }
}
