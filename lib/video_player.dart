import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme, ThemeData;
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';

class AppVideoPlayer extends StatefulWidget {
  final File file;

  final void Function(Duration? position) onVideoPosition;
  final void Function() onExit;

  const AppVideoPlayer(this.file,
      {super.key, required this.onVideoPosition, required this.onExit});

  @override
  State<StatefulWidget> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  late VideoPlayerController controller;
  late ChewieController chewieController;

  @override
  void initState() {
    controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.

        setState(() {});

        Timer.periodic(const Duration(milliseconds: 10), (timer) async {
          if (controller.value.isPlaying) {
            widget.onVideoPosition(await controller.position);
          }
        });
      })
      ..setLooping(true);
    chewieController = ChewieController(
        videoPlayerController: controller,
        allowFullScreen: false,
        allowPlaybackSpeedChanging: false,
        looping: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (value) async {
        if (value is! RawKeyUpEvent) return;

        if (value.logicalKey == LogicalKeyboardKey.escape) {
          widget.onExit();
        }
        if (value.logicalKey == LogicalKeyboardKey.f11) {
          await windowManager
              .setFullScreen(!(await windowManager.isFullScreen()));
        }
        if (value.logicalKey == LogicalKeyboardKey.space) {
          if (chewieController.isPlaying) {
            chewieController.pause();
          } else {
            chewieController.play();
          }
        }
      },
      autofocus: true,
      child: Center(
        child: controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: Theme(
                    data:
                        ThemeData.dark().copyWith(platform: TargetPlatform.iOS),
                    child: Chewie(
                      controller: chewieController,
                    )))
            : Container(),
      ),
    );
  }
}
