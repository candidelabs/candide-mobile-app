import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WCPeerIcon extends StatelessWidget {
  final List<String>? icons;
  const WCPeerIcon({Key? key, required this.icons}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget peerIcon;
    if (icons == null
        || icons!.isEmpty){
      peerIcon = SvgPicture.asset("assets/images/walletconnect.svg");
    }else{
      if (icons![0].endsWith(".svg")){
        peerIcon = SvgPicture.network(icons![0]);
      }else{
        peerIcon = Image.network(icons![0]);
      }
    }
    return peerIcon;
  }
}
