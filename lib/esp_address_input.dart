import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:multicast_dns/multicast_dns.dart';

class EspAddressInput extends StatefulWidget {
  const EspAddressInput({super.key});

  @override
  State<StatefulWidget> createState() => _EspAddressInputState();
}

class _EspAddressInputState extends State<EspAddressInput> {
  final textController = TextEditingController();
  List<DiscoveredDevice> availableDevices = [];
  bool scanning = false;

  @override
  void initState() {
    findDevices();
    super.initState();
  }

  Future<void> findDevices() async {
    setState(() {
      scanning = true;
    });
    const String name = '_videoledsync._tcp.local';
    final MDnsClient client = MDnsClient();
    availableDevices = [];
    // Start the client with default options.
    await client.start();

    // Get the PTR record for the service.
    await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(name))) {
      // Use the domainName from the PTR record to get the SRV record,
      // which will have the port and local hostname.
      // Note that duplicate messages may come through, especially if any
      // other mDNS queries are running elsewhere on the machine.
      await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))) {
        // Domain name will be something like "io.flutter.example@some-iphone.local._dartobservatory._tcp.local"
        final String bundleId = ptr.domainName; //.substring(0, ptr.domainName.indexOf('@'));
        print('Dart observatory instance found at '
            '${srv.target}:${srv.port} for "$bundleId".');

        // Resolve the IP with this line
        await for (final IPAddressResourceRecord ip
            in client.lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(srv.target))) {
          print('IP: ${ip.address.toString()}');
          if (availableDevices.indexWhere((d) => d.ipAddress.address == ip.address.address) == -1) {
            setState(() {
              availableDevices.add(DiscoveredDevice(srv.name.split(".")[0], ip.address));
            });
          }
        }
      }
    }
    client.stop();
    setState(() {
      scanning = false;
    });

    print('Done.');
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
                  subtitle: Text(e.ipAddress.address),
                  leading: Icon(CupertinoIcons.wifi),
                ))
            .toList()
      ],
    );
  }
}

class DiscoveredDevice {
  final String name;
  final InternetAddress ipAddress;

  const DiscoveredDevice(this.name, this.ipAddress);
}
