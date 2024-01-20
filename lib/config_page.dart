import 'dart:io';
import 'package:path/path.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_led_sync/esp_address_input.dart';

class ConfigPage extends StatelessWidget {
  final File? file;
  final void Function(File? filePicked) onFilePicked;
  final void Function() onVideoStart;
  final void Function(DiscoveredDevice? device) onDeviceSelected;
  final DiscoveredDevice? initialDevice;

  const ConfigPage(
      {super.key,
      required this.onFilePicked,
      required this.file,
      required this.onVideoStart,
      required this.onDeviceSelected,
      this.initialDevice});

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
                      style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
                    )),
                CupertinoButton.filled(onPressed: file != null ? () => onVideoStart() : null, child: const Text("Video starten")),
              ],
            ),
            Container(
                margin: const EdgeInsets.only(top: 15),
                child: Text("Dateien", style: CupertinoTheme.of(context).textTheme.navTitleTextStyle)),
            CupertinoButton(
                child: Row(children: [
                  Container(margin: const EdgeInsets.only(right: 10), child: const Icon(CupertinoIcons.folder_open)),
                  Text(file != null ? basename(file!.path) : "Video öffnen...")
                ]),
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(initialDirectory: file?.path);
                  onFilePicked(result != null ? File(result.files.single.path!) : file);
                }),
            EspAddressInput(
              initialDevice: initialDevice,
              onDeviceSelected: onDeviceSelected,
            ),
          ],
        ));
  }
}
