import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:video_led_sync/config_page.dart';
import 'package:video_led_sync/esp_address_input.dart';
import 'package:video_led_sync/led_controller.dart';
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
  bool showVideoPlayer = false;

  File? videoFile;
  File? ledFile;
  DiscoveredDevice? selectedDevice;

  WebSocketChannel? websocketChannel;
  SerialPort? serialPort;

  Options options = const Options(showColorPreview: false);
  Color previewColor = const Color(0xFF000000);

  LedController? led;

  @override
  void initState() {
    super.initState();
  }

  Future<void> sendVideoPosition(Duration? duration) async {
    if (led == null) {
      return;
    }
    final ledValues = led!.getCurrentValues(duration ?? Duration.zero);

    setState(() {
      previewColor =
          Color.fromARGB(255, ledValues[0].r, ledValues[0].g, ledValues[0].b);
    });

    if (selectedDevice == null) return;

    final List<int> data = [ledValues[0].r, ledValues[0].g, ledValues[0].b, 42];
    if (websocketChannel != null) {
      await websocketChannel!.ready;

      websocketChannel!.sink.add(data);
    }

    if (serialPort != null) {
      serialPort!.write(Uint8List.fromList(data));
    }
  }

  void loadNewLedFile(File? file) {
    if (file == null) {
      led = null;
      return;
    }

    try {
      led = LedController.fromCSV(file);
    } catch (e) {
      print(e);
      setState(() {
        ledFile = null;
      });
      led = null;
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text("Fehler"),
          content: const Text(
              "Die Datei konnte nicht eingelesen werden. Bitte prüfe, ob du die richtige Datei ausgewählt hast"),
          actions: [
            CupertinoButton(
              child: const Text("Okay"),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        backgroundColor: showVideoPlayer
            ? (options.showColorPreview
                ? previewColor
                : const Color(0xFF000000))
            : const Color(0xFFFFFFFF),
        child: showVideoPlayer
            ? AppVideoPlayer(
                videoFile!,
                onVideoPosition: (position) => sendVideoPosition(position),
                onExit: () => setState(() {
                  showVideoPlayer = false;
                }),
              )
            : ConfigPage(
                options: options,
                onOptionsChanged: (options) => setState(() {
                  this.options = options;
                }),
                videoFile: videoFile,
                onVideoFilePicked: (filePicked) => setState(() {
                  videoFile = filePicked;
                }),
                onVideoStart: () => setState(() {
                  showVideoPlayer = true;
                }),
                ledFile: ledFile,
                onLedFilePicked: (filePicked) => setState(() {
                  ledFile = filePicked;
                  loadNewLedFile(filePicked);
                }),
                initialDevice: selectedDevice,
                onDeviceSelected: (device) => setState(() {
                  websocketChannel = null;
                  serialPort?.close();
                  serialPort?.dispose();
                  serialPort = null;

                  selectedDevice = device;
                  if (device != null &&
                      device.type == DeviceConnectionType.usb) {
                    print("USB: ${device.usbPort}");
                    serialPort = SerialPort(device.usbPort!);

                    final opened = serialPort!.openWrite();
                    print("serial port ${device.usbPort} opened: $opened");
                  }
                  if (device != null &&
                      device.type == DeviceConnectionType.wifi) {
                    websocketChannel = WebSocketChannel.connect(
                        Uri.parse("ws://${device.ipAddress!.address}:81"));
                  }
                }),
              ));
  }
}
