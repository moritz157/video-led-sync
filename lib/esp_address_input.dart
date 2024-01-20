import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:multicast_dns/multicast_dns.dart';

class EspAddressInput extends StatefulWidget {
  final DiscoveredDevice? initialDevice;
  final void Function(DiscoveredDevice? device) onDeviceSelected;

  const EspAddressInput({super.key, required this.onDeviceSelected, this.initialDevice});

  @override
  State<StatefulWidget> createState() => _EspAddressInputState();
}

class _EspAddressInputState extends State<EspAddressInput> {
  final textController = TextEditingController();
  List<DiscoveredDevice> availableDevices = [];
  bool scanning = false;
  DiscoveredDevice? selectedDevice;

  @override
  void initState() {
    selectedDevice = widget.initialDevice;
    findDevices();
    super.initState();
  }

  Future<void> findDevices() async {
    setState(() {
      scanning = true;
      availableDevices = [];
      availableDevices = [
        ...availableDevices,
        ...SerialPort.availablePorts
            .map((p) => SerialPort(p))
            .where((p) => (p.description ?? "").contains("CP2102"))
            .map((p) => DiscoveredDevice(p.description ?? "USB-Device", DeviceConnectionType.usb, usbPort: p.name))
            .toList()
      ];
      print(availableDevices);
    });

    // --- WIFI ---
    const String name = '_videoledsync._tcp.local';
    final MDnsClient client = MDnsClient();
    await client.start();

    await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(name))) {
      await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))) {
        final String bundleId = ptr.domainName;
        print('Dart observatory instance found at '
            '${srv.target}:${srv.port} for "$bundleId".');

        // Resolve the IP with this line
        await for (final IPAddressResourceRecord ip
            in client.lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(srv.target))) {
          print('IP: ${ip.address.toString()}');
          if (availableDevices.indexWhere((d) => d.ipAddress?.address == ip.address.address) == -1) {
            setState(() {
              availableDevices.add(DiscoveredDevice(srv.name.split(".")[0], DeviceConnectionType.wifi, ipAddress: ip.address));
            });
          }
        }
      }
    }
    client.stop();
    setState(() {
      scanning = false;
    });

    print('Done. $availableDevices');

    print("Initial device: $selectedDevice");
  }

  isSelected(DiscoveredDevice d) {
    return selectedDevice != null && d.type == selectedDevice!.type && d.name == selectedDevice!.name;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Verfügbare Geräte", style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
            CupertinoButton(onPressed: scanning ? null : () => findDevices(), child: const Text("Scannen"))
          ],
        ),
        ...availableDevices
            .map((e) => CupertinoListTile(
                  title: Text(e.name),
                  subtitle: Text(e.ipAddress?.address ?? e.usbPort ?? ""),
                  leading: Icon(
                    isSelected(e)
                        ? CupertinoIcons.checkmark
                        : (e.type == DeviceConnectionType.wifi ? CupertinoIcons.wifi : CupertinoIcons.bolt),
                    color: isSelected(e) ? CupertinoColors.activeBlue : CupertinoColors.inactiveGray,
                  ),
                  onTap: () {
                    widget.onDeviceSelected(isSelected(e) ? null : e);
                    setState(() {
                      selectedDevice = isSelected(e) ? null : e;
                    });
                  },
                ))
            .toList()
      ],
    );
  }
}

class DiscoveredDevice {
  final String name;
  final DeviceConnectionType type;
  final InternetAddress? ipAddress;
  final String? usbPort;

  const DiscoveredDevice(this.name, this.type, {this.ipAddress, this.usbPort});
}

enum DeviceConnectionType { wifi, usb }
