import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/services/paymaster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

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

  static bool _hasWebsocketsChannel(int chainId){
    var wssEndpoint = Env.getWebsocketsNodeUrlByChainId(chainId).trim();
    if (wssEndpoint == "-" || wssEndpoint == "") return false;
    return true;
  }

  static void initialize(){
    instances.addAll(
      [
        Network(
          name: "Optimism",
          testnetData: null,
          visible: true,
          color: const Color.fromARGB(255, 255, 4, 32),
          logo: SvgPicture.asset("assets/images/optimism.svg"),
          extendedLogo: SvgPicture.asset("assets/images/optimism-wordmark-red.svg"),
          chainId: BigInt.from(10),
          explorers: {"etherscan":"https://optimistic.etherscan.io/{data}", "jiffyscan":"https://www.jiffyscan.xyz/{data}?network=optimism"},
          //
          nativeCurrency: 'ETH',
          nativeCurrencyAddress: EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'),
          candideBalances: EthereumAddress.fromHex("0x82998037a1C25D374c421A620db6D9ff26Fb50b5"),
          //
          safeSingleton: EthereumAddress.fromHex("0x3A0a17Bcc84576b099373ab3Eed9702b07D30402"),
          proxyFactory: EthereumAddress.fromHex("0xb73Eb505Abc30d0e7e15B73A492863235B3F4309"),
          fallbackHandler: EthereumAddress.fromHex("0x2a15DE4410d4c8af0A7b6c12803120f43C42B820"),
          socialRecoveryModule: EthereumAddress.fromHex("0xbc1920b63F35FdeD45382e2295E645B5c27fD2DA"),
          entrypoint: EthereumAddress.fromHex("0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"),
          multiSendCall: EthereumAddress.fromHex("0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B"),
          //
          client: Web3Client(
            Env.optimismRpcEndpoint,
            Client(),
            socketConnector: _hasWebsocketsChannel(10) ? () {
              return IOWebSocketChannel.connect(Env.optimismWebsocketsRpcEndpoint).cast<String>();
            } : null,
          ),
          bundler: Bundler(Env.optimismBundlerEndpoint, Client()),
          paymaster: Paymaster(Env.optimismPaymasterEndpoint, Client()),
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
          name: "Sepolia",
          testnetData: _TestnetData(testnetForChainId: 1),
          visible: false,
          color: const Color.fromARGB(255, 70, 127, 188),
          chainId: BigInt.from(11155111),
          explorers: {"etherscan":"https://sepolia.etherscan.io/{data}", "jiffyscan":"https://www.jiffyscan.xyz/{data}?network=sepolia"},
          //
          nativeCurrency: 'ETH',
          nativeCurrencyAddress: EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'),
          candideBalances: EthereumAddress.fromHex("0xA6Fc0C988E80D40cC7D1261aCc5348606E825E63"),
          //
          safeSingleton: EthereumAddress.fromHex("0x3A0a17Bcc84576b099373ab3Eed9702b07D30402"),
          proxyFactory: EthereumAddress.fromHex("0xb73Eb505Abc30d0e7e15B73A492863235B3F4309"),
          fallbackHandler: EthereumAddress.fromHex("0x2a15DE4410d4c8af0A7b6c12803120f43C42B820"),
          socialRecoveryModule: EthereumAddress.fromHex("0x831153c6b9537d0fF5b7DB830C2749DE3042e776"),
          entrypoint: EthereumAddress.fromHex("0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"),
          multiSendCall: EthereumAddress.fromHex("0x40A2aCCbd92BCA938b02010E17A5b8929b49130D"),
          //
          ensRegistryWithFallback: EthereumAddress.fromHex("0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e"),
          //
          client: Web3Client(
            Env.sepoliaRpcEndpoint,
            Client(),
            socketConnector: _hasWebsocketsChannel(11155111) ? () {
              return IOWebSocketChannel.connect(Env.sepoliaWebsocketsRpcEndpoint).cast<String>();
            } : null,
          ),
          bundler: Bundler(Env.sepoliaBundlerEndpoint, Client()),
          paymaster: Paymaster(Env.sepoliaPaymasterEndpoint, Client()),
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
              "hardware-wallet": false,
            },
          },
        ),
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
  Map<String, String> explorers;
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
  Web3Client client;
  Bundler bundler;
  Paymaster paymaster;
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
      required this.explorers,
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
      required this.client,
      required this.bundler,
      required this.paymaster,
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