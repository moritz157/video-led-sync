import 'dart:io';
import 'package:path/path.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_led_sync/esp_address_input.dart';

class ConfigPage extends StatelessWidget {
  final File? file;
  final void Function(File? filePicked) onFilePicked;
  final void Function() onVideoStart;

  const ConfigPage({super.key, required this.onFilePicked, required this.file, required this.onVideoStart});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                margin: const EdgeInsets.only(top: 15),
                child: Text(
                  "Video LED-Sync",
                  style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
                )),
            CupertinoButton(
                child: Row(children: [
                  Container(margin: const EdgeInsets.only(right: 10), child: const Icon(CupertinoIcons.folder_open)),
                  Text(file != null ? basename(file!.path) : "Video öffnen...")
                ]),
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(initialDirectory: file?.path);
                  onFilePicked(result != null ? File(result.files.single.path!) : file);
                }),
            // EspAddressInput()
            CupertinoButton.filled(child: const Text("Video starten"), onPressed: file != null ? () => onVideoStart() : null)
          ],
        ));
  }
}
