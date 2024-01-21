import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_led_sync/config_page.dart';
import 'package:video_led_sync/esp_address_input.dart';
import 'package:video_led_sync/led_controller.dart';
import 'package:video_led_sync/video_player.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fvp/fvp.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  registerWith();
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
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
    loadStoredPreferences();
    super.initState();
  }

  loadStoredPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      options =
          Options(showColorPreview: prefs.getBool("showColorPreview") ?? false);
    });

    if (prefs.containsKey("videoFilePath")) {
      final file = File(prefs.getString("videoFilePath") ?? "");
      if (await file.exists()) {
        setState(() {
          videoFile = file;
        });
      } else {
        print("Could not read stored videoFile");
        setState(() {
          videoFile = null;
        });

        prefs.remove("videoFilePath");
      }
    }
    if (prefs.containsKey("ledFilePath")) {
      try {
        final file = File(prefs.getString("ledFilePath") ?? "");
        led = LedController.fromCSV(file);
        setState(() {
          ledFile = file;
        });
      } catch (e) {
        print("Could not read stored ledFile");
        setState(() {
          ledFile = null;
        });
        led = null;
        prefs.remove("ledFilePath");
      }
    }
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

    if (selectedDevice == null) {
      return;
    }

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
                onOptionsChanged: (options) async {
                  setState(() {
                    this.options = options;
                  });
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setBool("showColorPreview", options.showColorPreview);
                },
                videoFile: videoFile,
                onVideoFilePicked: (filePicked) async {
                  setState(() {
                    videoFile = filePicked;
                  });
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  if (filePicked != null) {
                    prefs.setString("videoFilePath", filePicked.path);
                  } else {
                    prefs.remove("videoFilePath");
                  }
                },
                onVideoStart: () => setState(() {
                  showVideoPlayer = true;
                }),
                ledFile: ledFile,
                onLedFilePicked: (filePicked) async {
                  setState(() {
                    ledFile = filePicked;
                    loadNewLedFile(filePicked);
                  });
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  if (filePicked != null) {
                    prefs.setString("ledFilePath", filePicked.path);
                  } else {
                    prefs.remove("ledFilePath");
                  }
                },
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

                    final opened = serialPort!.openReadWrite();
                    if (opened) {
                      final config = serialPort!.config..baudRate = 115200;
                      serialPort!.config = config;
                    }
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
