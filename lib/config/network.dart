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
          "ETH": CurrencyMetadata(
            address: Constants.addressZeroHex,
            name: "Ethereum",
            symbol: "ETH",
            decimals: 18,
            logo: SvgPicture.asset("assets/images/ethereum.svg"),
          ),
          "WETH": CurrencyMetadata(
            address: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
            name: "Wrapped Ethereum",
            symbol: "WETH",
            decimals: 18,
            logo: SvgPicture.asset("assets/images/optimism.svg"),
          ),
          "UNI": CurrencyMetadata(
            address: "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984",
            name: "Uniswap",
            symbol: "UNI",
            decimals: 18,
            logo: SvgPicture.asset("assets/images/uniswap.svg", color: const Color(0xFFFF007A),),
          ),
          "CTT": CurrencyMetadata(
            address: "0xFaaFfdCBF13f879EA5D5594C4aEBcE0F5dE733ca",
            name: "Candide Test Token",
            symbol: "CTT",
            decimals: 18,
            logo: SvgPicture.asset("assets/images/fee-coin2.svg",),
          ),
          "USDT": CurrencyMetadata(
            address: "0xFaaFfdCBF13f879EA5D5594C4aEBcE0F5dE733ca",
            name: "Tether",
            symbol: "USDT",
            displaySymbol: "\$",
            decimals: 6,
            logo: SvgPicture.asset("assets/images/fee-coin.svg"),
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

  CurrencyMetadata? currency(String symbol) => currencies[symbol];

}

class CurrencyMetadata{
  String address;
  String name;
  String symbol;
  late String displaySymbol;
  int decimals;
  Widget logo;
  //
  static Map<String, CurrencyMetadata> metadata = {};

  CurrencyMetadata({
    required this.address,
    required this.name,
    required this.symbol,
    String? displaySymbol,
    required this.decimals,
    required this.logo
  }){
    if (displaySymbol == null){
      this.displaySymbol = symbol;
    }else{
      this.displaySymbol = displaySymbol;
    }
    metadata[symbol] = this;
  }

  static CurrencyMetadata? findByAddress(String address){
    for (MapEntry<String, CurrencyMetadata> entry in metadata.entries){
      CurrencyMetadata metadata = entry.value;
      if (metadata.address.toLowerCase() == address.toLowerCase()){
        return metadata;
      }
    }
    return null;
  }
}