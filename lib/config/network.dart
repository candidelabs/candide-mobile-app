import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:magic_sdk/magic_sdk.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class Networks {
  static List<Network> instances = [];
  static final Map<int, Network> _instancesMap = {};

  static initialize(){
    instances.addAll(
      [
        Network(
          name: "Görli",
          testnetData: _TestnetData(testnetForChainId: 1),
          color: const Color(0xff4d99eb),
          logo: SvgPicture.asset("assets/images/optimism.svg"),
          nativeCurrency: 'ETH',
          chainId: BigInt.from(5),
          explorerUrl: "https://goerli.etherscan.io",
          //
          coinGeckoAssetPlatform: "ethereum",
          candideBalances: EthereumAddress.fromHex("0xdc1e0B26F8D92243A28087172b941A169C2B4354"),
          //
          safeSingleton: EthereumAddress.fromHex("0x23e4fd58F38cD9c75957a182DB90bB449879A6A3"),
          proxyFactory: EthereumAddress.fromHex("0xb73Eb505Abc30d0e7e15B73A492863235B3F4309"),
          fallbackHandler: EthereumAddress.fromHex("0x9a77CD4a3e2B849f70616c82A9c69BdA1C2296ff"),
          socialRecoveryModule: EthereumAddress.fromHex("0xCbf67d131Fa0775c5d18676c58de982c349aFC0b"),
          entrypoint: EthereumAddress.fromHex("0x0576a174D229E3cFA37253523E645A78A0C91B57"),
          multiSendCall: EthereumAddress.fromHex("0x40A2aCCbd92BCA938b02010E17A5b8929b49130D"),
          //
          ensRegistryWithFallback: EthereumAddress.fromHex("0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e"),
          //
          client: Web3Client(Env.goerliRpcEndpoint, Client()),
          //
          features: [
            "deposit-simple",
            /*"deposit-fiat",*/
            "transfer",
            "swap",
            "social-recovery"
          ],
        ),
        Network(
          name: "Optimism Goerli",
          testnetData: _TestnetData(testnetForChainId: 10),
          color: const Color.fromARGB(255, 255, 137, 225),
          logo: SvgPicture.asset("assets/images/optimism.svg"),
          nativeCurrency: 'ETH',
          chainId: BigInt.from(420),
          explorerUrl: "https://goerli-optimism.etherscan.io",
          //
          coinGeckoAssetPlatform: "optimistic-ethereum",
          candideBalances: EthereumAddress.fromHex("0x97A8c45e8Da6608bAbf09eb1222292d7B389B1a1"),
          //
          safeSingleton: EthereumAddress.fromHex("0x23e4fd58F38cD9c75957a182DB90bB449879A6A3"),
          proxyFactory: EthereumAddress.fromHex("0xb73Eb505Abc30d0e7e15B73A492863235B3F4309"),
          fallbackHandler: EthereumAddress.fromHex("0x9a77CD4a3e2B849f70616c82A9c69BdA1C2296ff"),
          socialRecoveryModule: EthereumAddress.fromHex("0xCbf67d131Fa0775c5d18676c58de982c349aFC0b"),
          entrypoint: EthereumAddress.fromHex("0x0576a174D229E3cFA37253523E645A78A0C91B57"),
          multiSendCall: EthereumAddress.fromHex("0x40A2aCCbd92BCA938b02010E17A5b8929b49130D"),
          //
          client: Web3Client(Env.optimismGoerliRpcEndpoint, Client()),
          //
          features: [
            "deposit-simple",
            /*"deposit-fiat",*/
            "transfer",
            /*"swap",*/
            "social-recovery"
          ],
        ),
        /*Network(
          name: "Optimism",
          testnetData: null,
          color: const Color(0xfff01a37),
          logo: SvgPicture.asset("assets/images/optimism.svg"),
          nativeCurrency: 'ETH',
          chainId: BigInt.from(10),
          explorerUrl: "https://optimism.etherscan.io",
          //
          coinGeckoAssetPlatform: "optimistic-ethereum",
          candideBalances: EthereumAddress.fromHex("0x82998037a1C25D374c421A620db6D9ff26Fb50b5"),
          //
          safeSingleton: EthereumAddress.fromHex("0x23e4fd58F38cD9c75957a182DB90bB449879A6A3"),
          proxyFactory: EthereumAddress.fromHex("0xb73Eb505Abc30d0e7e15B73A492863235B3F4309"),
          fallbackHandler: EthereumAddress.fromHex("0x9a77CD4a3e2B849f70616c82A9c69BdA1C2296ff"),
          socialRecoveryModule: EthereumAddress.fromHex("0xCbf67d131Fa0775c5d18676c58de982c349aFC0b"),
          entrypoint: EthereumAddress.fromHex("0x0576a174D229E3cFA37253523E645A78A0C91B57"),
          //
          client: Web3Client(Env.optimismRpcEndpoint, Client()),
          //
          features: [
            "deposit-simple",
            "deposit-fiat",
            "transfer",
            "swap",
            "social-recovery"
          ],
        ),*/
      ]
    );
    for (Network network in instances){
      _instancesMap[network.chainId.toInt()] = network;
    }
  }

  static Network? getByName(String name) => instances.firstWhereOrNull((element) => element.name == name);
  static Network? getByChainId(int chainId) => _instancesMap[chainId];
  static Network selected() => _instancesMap[PersistentData.selectedAccount.chainId]!;
}

class Network{
  String name;
  _TestnetData? testnetData;
  Color color;
  Widget logo;
  String nativeCurrency;
  BigInt chainId;
  String explorerUrl;
  String coinGeckoAssetPlatform;
  EthereumAddress candideBalances;
  EthereumAddress proxyFactory;
  EthereumAddress safeSingleton;
  EthereumAddress fallbackHandler;
  EthereumAddress socialRecoveryModule;
  EthereumAddress entrypoint;
  EthereumAddress multiSendCall;
  EthereumAddress? ensRegistryWithFallback;
  Web3Client client;
  Magic? magicInstance;
  List<String> features;

  String get normalizedName => name.replaceAll("ö", "oe");

  Network(
      {required this.name,
      this.testnetData,
      required this.color,
      required this.logo,
      required this.nativeCurrency,
      required this.chainId,
      required this.explorerUrl,
      required this.coinGeckoAssetPlatform,
      required this.candideBalances,
      required this.proxyFactory,
      required this.safeSingleton,
      required this.fallbackHandler,
      required this.socialRecoveryModule,
      required this.entrypoint,
      required this.multiSendCall,
      this.ensRegistryWithFallback,
      required this.client,
      required this.features});
}

class _TestnetData {
  int testnetForChainId;

  _TestnetData({required this.testnetForChainId});
}