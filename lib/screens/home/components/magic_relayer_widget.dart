import 'package:candide_mobile_app/config/env.dart';
import 'package:flutter/material.dart';
import 'package:magic_sdk/magic_sdk.dart';

class MagicRelayerWidget extends StatefulWidget {
  const MagicRelayerWidget({Key? key}) : super(key: key);

  @override
  State<MagicRelayerWidget> createState() => _MagicRelayerWidgetState();
}

class _MagicRelayerWidgetState extends State<MagicRelayerWidget> {
  late Magic instance;

  @override
  void initState() {
    Magic.instance = Magic(
      Env.magicApiKey,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Magic.instance.relayer;
  }
}
