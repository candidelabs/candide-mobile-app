import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class WCPeerIcon extends StatelessWidget {
  final WalletConnect connector;
  const WCPeerIcon({Key? key, required this.connector}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget peerIcon;
    if (connector.session.peerMeta == null
        || connector.session.peerMeta!.icons == null
        || connector.session.peerMeta!.icons!.isEmpty){
      peerIcon = SvgPicture.asset("assets/images/walletconnect.svg");
    }else{
      if (connector.session.peerMeta!.icons![0].endsWith(".svg")){
        peerIcon = SvgPicture.network(connector.session.peerMeta!.icons![0]);
      }else{
        peerIcon = Image.network(connector.session.peerMeta!.icons![0]);
      }
    }
    return peerIcon;
  }
}
