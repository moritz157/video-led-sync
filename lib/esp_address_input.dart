import 'package:flutter/cupertino.dart';

class EspAddressInput extends StatefulWidget {
  const EspAddressInput({super.key});

  @override
  State<StatefulWidget> createState() => _EspAddressInputState();
}

class _EspAddressInputState extends State<EspAddressInput> {
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: textController,
    );
  }
}
