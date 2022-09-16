import 'package:candide_mobile_app/utils/constants.dart';
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
        currencies: {
          "UNI": CurrencyMetadata(
            address: "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984",
            name: "Uniswap",
            symbol: "UNI",
            decimals: 18,
            logo: SvgPicture.asset("assets/images/uniswap.svg", color: const Color(0xFFFF007A),),
          ),
          "ETH": CurrencyMetadata(
            address: Constants.addressZero,
            name: "Ethereum",
            symbol: "ETH",
            decimals: 18,
            logo: SvgPicture.asset("assets/images/ethereum.svg"),
          ),
        }
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
  Map<String, CurrencyMetadata> currencies;

  Network(
      {required this.name,
      required this.color,
      required this.logo,
      required this.nativeCurrency,
      required this.chainId,
      required this.currencies});

  CurrencyMetadata? currency(String name) => currencies[name];

}

class CurrencyMetadata{
  String address;
  String name;
  String symbol;
  int decimals;
  Widget logo;
  //
  static Map<String, CurrencyMetadata> metadata = {};

  CurrencyMetadata({
    required this.address,
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.logo
  }){
    metadata[symbol] = this;
  }
}