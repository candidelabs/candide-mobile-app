import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/models/gas_estimators/gas_estimator.dart';
import 'package:candide_mobile_app/models/gas_estimators/l1_gas_estimator.dart';
import 'package:candide_mobile_app/models/gas_estimators/l2_gas_estimator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:magic_sdk/magic_sdk.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class Networks {
  static const List<int> DEFAULT_HIDDEN_NETWORKS = [5, 420];
  static List<Network> instances = [];
  static final Map<int, Network> _instancesMap = {};

  static void configureVisibility(){
    final hiddenNetworks = PersistentData.loadHiddenNetworks();
    for (final Network network in instances){
      if (hiddenNetworks.contains(network.chainId.toInt())){
        network.visible = false;
      }else{
        network.visible = true;
      }
    }
  }

  static void initialize(){
    instances.addAll(
      [
        Network(
          name: "Optimism",
          testnetData: null,
          visible: true,
          color: const Color(0xfff01a37),
          logo: SvgPicture.asset("assets/images/optimism.svg"),
          extendedLogo: SvgPicture.asset("assets/images/optimism-wordmark-red.svg"),
          chainId: BigInt.from(10),
          explorerUrl: "https://optimistic.etherscan.io",
          //
          coinGeckoAssetPlatform: "optimistic-ethereum",
          nativeCurrency: 'ETH',
          nativeCurrencyAddress: EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'),
          candideBalances: EthereumAddress.fromHex("0x82998037a1C25D374c421A620db6D9ff26Fb50b5"),
          //
          safeSingleton: EthereumAddress.fromHex("0x3A0a17Bcc84576b099373ab3Eed9702b07D30402"),
          proxyFactory: EthereumAddress.fromHex("0xb73Eb505Abc30d0e7e15B73A492863235B3F4309"),
          fallbackHandler: EthereumAddress.fromHex("0x017062a1dE2FE6b99BE3d9d37841FeD19F573804"),
          socialRecoveryModule: EthereumAddress.fromHex("0xbc1920b63F35FdeD45382e2295E645B5c27fD2DA"),
          entrypoint: EthereumAddress.fromHex("0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"),
          multiSendCall: EthereumAddress.fromHex("0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B"),
          //
          gasEstimator: L2GasEstimator(chainId: 10, ovmGasOracle: EthereumAddress.fromHex("0x420000000000000000000000000000000000000F")),
          //
          client: Web3Client(Env.optimismRpcEndpoint, Client()),
          //
          features: {
            "deposit": {
              "deposit-address": true,
              "deposit-fiat": false,
            },
            "transfer": {
              "basic": true
            },
            "swap": {
              "basic": false
            },
            "social-recovery": {
              "family-and-friends": true,
              "magic-link": false,
              "hardware-wallet": true,
            },
          },
        ),
        Network(
          name: "Optimism Goerli",
          testnetData: _TestnetData(testnetForChainId: 10),
          visible: false,
          color: const Color.fromARGB(255, 255, 137, 225),
          chainId: BigInt.from(420),
          explorerUrl: "https://goerli-optimism.etherscan.io",
          //
          coinGeckoAssetPlatform: "optimistic-ethereum",
          nativeCurrency: 'ETH',
          nativeCurrencyAddress: EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'),
          candideBalances: EthereumAddress.fromHex("0x97A8c45e8Da6608bAbf09eb1222292d7B389B1a1"),
          //
          safeSingleton: EthereumAddress.fromHex("0x3A0a17Bcc84576b099373ab3Eed9702b07D30402"),
          proxyFactory: EthereumAddress.fromHex("0xb73Eb505Abc30d0e7e15B73A492863235B3F4309"),
          fallbackHandler: EthereumAddress.fromHex("0x017062a1dE2FE6b99BE3d9d37841FeD19F573804"),
          socialRecoveryModule: EthereumAddress.fromHex("0x831153c6b9537d0fF5b7DB830C2749DE3042e776"),
          entrypoint: EthereumAddress.fromHex("0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"),
          multiSendCall: EthereumAddress.fromHex("0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B"),
          //
          gasEstimator: L2GasEstimator(chainId: 420, ovmGasOracle: EthereumAddress.fromHex("0x420000000000000000000000000000000000000F")),
          //
          client: Web3Client(Env.optimismGoerliRpcEndpoint, Client()),
          //
          features: {
            "deposit": {
              "deposit-address": true,
              "deposit-fiat": false,
            },
            "transfer": {
              "basic": true
            },
            "swap": {
              "basic": false
            },
            "social-recovery": {
              "family-and-friends": true,
              "magic-link": true,
              "hardware-wallet": false,
            },
          },
        ),
        Network(
          name: "Görli",
          testnetData: _TestnetData(testnetForChainId: 1),
          visible: false,
          color: const Color(0xff4d99eb),
          chainId: BigInt.from(5),
          explorerUrl: "https://goerli.etherscan.io",
          //
          coinGeckoAssetPlatform: "ethereum",
          nativeCurrency: 'ETH',
          nativeCurrencyAddress: EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'),
          candideBalances: EthereumAddress.fromHex("0xdc1e0B26F8D92243A28087172b941A169C2B4354"),
          //
          safeSingleton: EthereumAddress.fromHex("0x3A0a17Bcc84576b099373ab3Eed9702b07D30402"),
          proxyFactory: EthereumAddress.fromHex("0xb73Eb505Abc30d0e7e15B73A492863235B3F4309"),
          fallbackHandler: EthereumAddress.fromHex("0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4"),
          socialRecoveryModule: EthereumAddress.fromHex("0x831153c6b9537d0fF5b7DB830C2749DE3042e776"),
          entrypoint: EthereumAddress.fromHex("0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"),
          multiSendCall: EthereumAddress.fromHex("0x40A2aCCbd92BCA938b02010E17A5b8929b49130D"),
          //
          ensRegistryWithFallback: EthereumAddress.fromHex("0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e"),
          //
          gasEstimator: L1GasEstimator(chainId: 5),
          //
          client: Web3Client(Env.goerliRpcEndpoint, Client()),
          //
          features: {
            "deposit": {
              "deposit-address": true,
              "deposit-fiat": false,
            },
            "transfer": {
              "basic": true
            },
            "swap": {
              "basic": true
            },
            "social-recovery": {
              "family-and-friends": true,
              "magic-link": true,
              "hardware-wallet": false,
            },
          },
        ),
        /*Network(
          name: "Sepolia",
          testnetData: _TestnetData(testnetForChainId: 1),
          visible: true,
          color: Colors.green,
          nativeCurrency: 'ETH',
          chainId: BigInt.from(11155111),
          explorerUrl: "https://sepolia.etherscan.io",
          //
          coinGeckoAssetPlatform: "ethereum",
          candideBalances: EthereumAddress.fromHex("0xa5d1be20e7b73651416cc04c86d6e4f79a012960"),
          //
          safeSingleton: EthereumAddress.fromHex("0x3A0a17Bcc84576b099373ab3Eed9702b07D30402"),
          proxyFactory: EthereumAddress.fromHex("0xb73Eb505Abc30d0e7e15B73A492863235B3F4309"),
          fallbackHandler: EthereumAddress.fromHex("0x017062a1dE2FE6b99BE3d9d37841FeD19F573804"),
          socialRecoveryModule: EthereumAddress.fromHex("0x831153c6b9537d0fF5b7DB830C2749DE3042e776"),
          entrypoint: EthereumAddress.fromHex("0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"),
          multiSendCall: EthereumAddress.fromHex("0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B"),
          //
          gasEstimator: L1GasEstimator(chainId: 11155111),
          //
          client: Web3Client(Env.sepoliaRpcEndpoint, Client()),
          //
          features: {
            "deposit": {
              "deposit-address": true,
              "deposit-fiat": false,
            },
            "transfer": {
              "basic": true
            },
            "swap": {
              "basic": false
            },
            "social-recovery": {
              "family-and-friends": true,
              "magic-link": false,
              "hardware-wallet": true,
            },
          },
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
  Widget? logo;
  Widget? extendedLogo;
  BigInt chainId;
  String explorerUrl;
  String coinGeckoAssetPlatform;
  String nativeCurrency;
  EthereumAddress nativeCurrencyAddress;
  EthereumAddress candideBalances;
  EthereumAddress proxyFactory;
  EthereumAddress safeSingleton;
  EthereumAddress fallbackHandler;
  EthereumAddress socialRecoveryModule;
  EthereumAddress entrypoint;
  EthereumAddress multiSendCall;
  EthereumAddress? ensRegistryWithFallback;
  GasEstimator gasEstimator;
  Web3Client client;
  Magic? magicInstance;
  Map<String, dynamic> features;
  //
  bool visible;

  String get normalizedName => name.replaceAll("ö", "oe");

  Network(
      {required this.name,
      this.testnetData,
      required this.color,
      this.logo,
      this.extendedLogo,
      required this.chainId,
      required this.explorerUrl,
      required this.coinGeckoAssetPlatform,
      required this.nativeCurrency,
      required this.nativeCurrencyAddress,
      required this.candideBalances,
      required this.proxyFactory,
      required this.safeSingleton,
      required this.fallbackHandler,
      required this.socialRecoveryModule,
      required this.entrypoint,
      required this.multiSendCall,
      this.ensRegistryWithFallback,
      required this.gasEstimator,
      required this.client,
      required this.features,
      this.visible=true});

  bool isFeatureEnabled(String feature){
    if (!feature.contains(".")){
      feature = "$feature.basic";
    }
    var paths = feature.split(".");
    var tempMap = features;
    for (String feature in paths.sublist(0, paths.length-1)){
      tempMap = tempMap[feature];
    }
    if (tempMap[paths.last] is! bool){
      return false;
    }
    return tempMap[paths.last];
  }

}

class _TestnetData {
  int testnetForChainId;

  _TestnetData({required this.testnetForChainId});
}