import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:video_led_sync/config_page.dart';
import 'package:video_led_sync/esp_address_input.dart';
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
  DiscoveredDevice? selectedDevice;

  WebSocketChannel? websocketChannel;
  SerialPort? serialPort;

  @override
  void initState() {
    super.initState();
    // channel = WebSocketChannel.connect(Uri.parse("ws://192.168.179.40:81"));
  }

  Future<void> sendVideoPosition(Duration? duration) async {
    if (selectedDevice == null) return;

    final List<int> data = [255, (((duration?.inMilliseconds ?? 0) % 4200) / 4200 * 255).round(), 0, 42];
    if (websocketChannel != null) {
      await websocketChannel!.ready;

      websocketChannel!.sink.add(data);
    }

    if (serialPort != null) {
      serialPort!.write(Uint8List.fromList(data));
    }
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
                initialDevice: selectedDevice,
                onFilePicked: (filePicked) => setState(() {
                  videoFile = filePicked;
                }),
                onVideoStart: () => setState(() {
                  showVideoPlayer = true;
                }),
                onDeviceSelected: (device) => setState(() {
                  websocketChannel = null;
                  serialPort?.close();
                  serialPort?.dispose();
                  serialPort = null;

                  selectedDevice = device;
                  if (device != null && device.type == DeviceConnectionType.usb) {
                    print("USB: ${device.usbPort}");
                    // final config = SerialPortConfig()..baudRate = 115200;
                    serialPort = SerialPort(device.usbPort!);

                    final opened = serialPort!.openWrite();
                    print("serial port ${device.usbPort} opened: $opened");
                    // serialPort!.config = config;
                  }
                  if (device != null && device.type == DeviceConnectionType.wifi) {
                    websocketChannel = WebSocketChannel.connect(Uri.parse("ws://${device.ipAddress!.address}:81"));
                  }
                }),
              ));
  }
}
