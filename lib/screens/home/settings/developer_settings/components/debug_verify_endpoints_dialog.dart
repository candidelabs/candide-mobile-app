import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/config/top_tokens.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/services/balance_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:web3dart/credentials.dart';

class VerifyEndpointsDialog extends StatefulWidget {
  final Network network;
  const VerifyEndpointsDialog({Key? key, required this.network}) : super(key: key);

  @override
  State<VerifyEndpointsDialog> createState() => _VerifyEndpointsDeialogState();
}

class _VerifyEndpointsDeialogState extends State<VerifyEndpointsDialog> {
  Map<String, List<dynamic>> endpoints = { // endpoint: [status, chain-dependent]
    "ethereum-node-endpoints": ["scheduled", true],
    "bundler-endpoints": ["scheduled", true],
    "paymaster-endpoints": ["scheduled", true],
    "coingecko": ["scheduled", false],
    "cryptocompare": ["scheduled", false],
  };

  Future<bool> verifyBundlerEndpoint() async {
    try{
      var chainId = await widget.network.bundler.getChainId();
      //
      if (chainId == null) return false;
      if (chainId == widget.network.chainId){
        var supportedEntryPoints = await widget.network.bundler.getSupportedEntryPoints();
        if (supportedEntryPoints == null) return false;
        if (supportedEntryPoints.contains(widget.network.entrypoint)) return true;
      }
      return false;
    } on DioException {
      return false;
    }
  }

  Future<bool> verifyEthereumEndpoint() async {
    try{
      BigInt chainId = await widget.network.client.getChainId();
      if (chainId == widget.network.chainId){
        await widget.network.client.getBlockNumber();
        return true;
      }
      //
      return false;
    } on DioException {
      return false;
    }
  }

  Future<bool> verifyPaymasterEndpoint() async {
    try{
      var supportedTokens = await widget.network.paymaster.supportedERC20Tokens(TokenInfoStorage.getNativeTokenForNetwork(widget.network));
      //
      if (supportedTokens.tokens.length == 1) return false;
      return true;
    } on Exception {
      return false;
    }
  }

  Future<bool> verifyCoingeckoEndpoint() async {
    try{
      int chainId = widget.network.chainId.toInt();
      if (widget.network.testnetData != null){
        chainId = widget.network.testnetData!.testnetForChainId;
      }
      EthereumAddress tokenAddress = TopTokens.getChainTokens(chainId)[1];
      var response = await Dio().get("https://api.coingecko.com/api/v3/simple/token_price/${widget.network.coinGeckoAssetPlatform}?contract_addresses=$tokenAddress&vs_currencies=eth");
      return response.data.toString().toLowerCase().contains(tokenAddress.hex.toLowerCase());
    } on DioException {
      return false;
    }
  }

  Future<bool> verifyEndpoint(String name) async {
    if (name == "ethereum-node-endpoints"){
      return await verifyEthereumEndpoint();
    }else if (name == "bundler-endpoints"){
      return await verifyBundlerEndpoint();
    }else if (name == "paymaster-endpoints"){
      return await verifyPaymasterEndpoint();
    }else if (name == "coingecko"){
      return await verifyCoingeckoEndpoint();
    }else if (name == "cryptocompare"){
      return (await BalanceService.getETHUSDPrice()) > 0;
    }
    return false;
  }

  void startVerifying() async {
    for (MapEntry entry in endpoints.entries){
      setState(() {
        entry.value[0] = "pending";
      });
      bool status = await verifyEndpoint(entry.key);
      if (!mounted) return;
      setState(() {
        entry.value[0] = status ? "success" : "failed";
      });
    }
  }

  @override
  void initState() {
    startVerifying();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // contentPadding: EdgeInsets.symmetric(horizontal: 10),
      title: Text("Verify Endpoints", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (MapEntry<String, List<dynamic>> endpoint in endpoints.entries)
            _VerifyEndpointItem(
              name: endpoint.key.replaceAll("-", " ").capitalizeFirst!,
              networkName: endpoint.value[1] ? widget.network.name : null,
              status: endpoint.value[0],
            ),
        ],
      ),
    );
  }
}

class _VerifyEndpointItem extends StatelessWidget {
  final String name;
  final String? networkName;
  final String status;
  const _VerifyEndpointItem({Key? key, required this.name, required this.status, this.networkName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget leading;
    if (status != "pending"){
      IconData leadingIconData = PhosphorIcons.timer;
      Color leadingColor = Colors.white;
      if (status == "success"){
        leadingIconData = PhosphorIcons.checkBold;
        leadingColor = Colors.green;
      }else if (status == "failed"){
        leadingIconData = PhosphorIcons.xBold;
        leadingColor = Colors.red;
      }
      leading = Icon(
        leadingIconData,
        size: 20,
        color: leadingColor,
      );
      if (status == "scheduled"){
        leading = const SizedBox(width: 20,);
      }
    }else{
      leading = Transform.scale(
        scale: 0.75,
        child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2,)
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10,),
          RichText(
            text: TextSpan(
              text: name,
              children: [
                if (networkName != null)
                  TextSpan(
                    text: "\n$networkName",
                    style: const TextStyle(color: Colors.grey, fontSize: 11)
                  )
              ]
            ),
          ),
        ],
      ),
    );
  }
}
