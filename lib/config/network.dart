import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class Networks {
  static List<Network> instances = [];

  static initialize(){
    instances.add(
      Network(
        name: "Goerli",
        color: const Color(0xffce2525),
        logo: SvgPicture.asset("assets/images/optimism.svg"),
        nativeCurrency: 'ETH',
        chainId: BigInt.from(5),
        explorerUrl: "https://goerli.etherscan.io",
      )
    );
  }

  static Network? get(String name) => instances.firstWhereOrNull((element) => element.name == name);
}

class Network{
  String name;
  Color color;
  Widget logo;
  String nativeCurrency;
  BigInt chainId;
  String explorerUrl;

  Network(
      {required this.name,
      required this.color,
      required this.logo,
      required this.nativeCurrency,
      required this.chainId,
      required this.explorerUrl});
}