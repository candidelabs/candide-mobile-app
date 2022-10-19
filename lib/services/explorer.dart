import 'dart:convert';

import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/config/swap.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:dio/dio.dart';
import 'package:wallet_dart/contracts/wallet.dart';

class Explorer {

  static fetchAddressOverview({
      required String network,
      required String quoteCurrency,
      required String address,
      required List<String> currencyList}) async {
    try{
      var response = await Dio().post("${Env.explorerUri}/v1/address/$address", data: jsonEncode({
        "network": network,
        "quoteCurrency": quoteCurrency,
        "currencies": currencyList,
      }));
      await AddressData.updateExplorerJson(response.data);
      //
      bool proxyDeployed = true;
      bool managerDeployed = true;
      bool socialDeployed = true;
      await Future.wait([
        Constants.client.getCode(AddressData.wallet.walletAddress).then((value) => proxyDeployed = value.isNotEmpty),
        Constants.client.getCode(AddressData.wallet.moduleManager).then((value) => managerDeployed = value.isNotEmpty),
        Constants.client.getCode(AddressData.wallet.socialRecovery).then((value) => socialDeployed = value.isNotEmpty),
      ]);
      AddressData.walletStatus = WalletStatus(
        proxyDeployed: proxyDeployed,
        managerDeployed: managerDeployed,
        socialModuleDeployed: socialDeployed,
        nonce: proxyDeployed ? ((await CWallet.customInterface(AddressData.wallet.walletAddress).nonce()).toInt()) : 0,
      );
    } on DioError catch(e){
      print("Error occured ${e.type.toString()}");
      print(e.response?.statusMessage);
    }
  }

  static Future<GasEstimate?> fetchGasEstimate(String network) async {
    try{
      var response = await Dio().get("${Env.explorerUri}/v1/gas/estimator", queryParameters: {"network": network});
      //
      GasEstimate gasEstimate = GasEstimate(
        maxPriorityFeePerGas: response.data["maxPriorityFeePerGas"],
        maxFeePerGas: response.data["maxFeePerGas"],
      );
      //
      return gasEstimate;
    } on DioError catch(e){
      print("Error occured ${e.type.toString()}");
      return null;
    }
  }

  static Future<OptimalQuote?> fetchSwapQuote(String network, String baseCurrency, String quoteCurrency, BigInt value, String address) async {
    try{
      var response = await Dio().get("${Env.explorerUri}/v1/swap/quote",
        queryParameters: {
          "network": network,
          "baseCurrency": baseCurrency,
          "quoteCurrency": quoteCurrency,
          "value": value.toString(),
          "address": address,
        }
      );
      //
      if (response.data["quote"] == null) return null;
      var quote = response.data["quote"];
      OptimalQuote optimalQuote = OptimalQuote(
        amount: BigInt.parse(quote["amount"].toString()),
        rate: BigInt.parse(quote["rate"].toString()),
        transaction: quote["transaction"],
      );
      //
      return optimalQuote;
    } on DioError catch(e){
      print("Error occured ${e.type.toString()}");
      return null;
    }
  }

}