import 'dart:io';
import 'package:path/path.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_led_sync/esp_address_input.dart';

class ConfigPage extends StatelessWidget {
  final File? videoFile;
  final void Function(File? filePicked) onVideoFilePicked;

  final File? ledFile;
  final void Function(File? filePicked) onLedFilePicked;

  final void Function() onVideoStart;
  final void Function(DiscoveredDevice? device) onDeviceSelected;
  final DiscoveredDevice? initialDevice;
  final Options options;
  final void Function(Options options) onOptionsChanged;

  const ConfigPage(
      {super.key,
      required this.onVideoFilePicked,
      required this.videoFile,
      required this.onLedFilePicked,
      required this.ledFile,
      required this.onVideoStart,
      required this.onDeviceSelected,
      this.initialDevice,
      required this.options,
      required this.onOptionsChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    margin: const EdgeInsets.only(top: 15),
                    child: Text(
                      "Video LED-Sync",
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .navLargeTitleTextStyle,
                    )),
                CupertinoButton.filled(
                    onPressed: videoFile != null ? () => onVideoStart() : null,
                    child: const Text("Video starten")),
              ],
            ),
            Container(
                margin: const EdgeInsets.only(top: 15),
                child: Text("Dateien",
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .navTitleTextStyle)),
            CupertinoButton(
                child: Row(children: [
                  Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: const Icon(CupertinoIcons.videocam)),
                  Text(videoFile != null
                      ? basename(videoFile!.path)
                      : "Video öffnen...")
                ]),
                onPressed: () async {
                  final result = await FilePicker.platform
                      .pickFiles(initialDirectory: videoFile?.path);
                  onVideoFilePicked(result != null
                      ? File(result.files.single.path!)
                      : videoFile);
                }),
            CupertinoButton(
                child: Row(children: [
                  Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: const Icon(CupertinoIcons.lightbulb)),
                  Text(ledFile != null
                      ? basename(ledFile!.path)
                      : "LED-Animation öffnen...")
                ]),
                onPressed: () async {
                  final result = await FilePicker.platform
                      .pickFiles(initialDirectory: ledFile?.path);
                  onLedFilePicked(result != null
                      ? File(result.files.single.path!)
                      : ledFile);
                }),
            Container(
                margin: const EdgeInsets.only(top: 15, bottom: 10),
                child: Text("Optionen",
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .navTitleTextStyle)),
            Row(
              children: [
                CupertinoSwitch(
                    value: options.showColorPreview,
                    onChanged: (value) =>
                        onOptionsChanged(Options(showColorPreview: value))),
                Container(
                    margin: const EdgeInsets.only(left: 10),
                    child: Text("Farbvorschau als Hintergrundfarbe anzeigen",
                        style: CupertinoTheme.of(context).textTheme.textStyle))
              ],
            ),
            EspAddressInput(
              initialDevice: initialDevice,
              onDeviceSelected: onDeviceSelected,
            ),
          ],
        ));
  }
}

class Options {
  final bool showColorPreview;

  const Options({this.showColorPreview = false});
}
