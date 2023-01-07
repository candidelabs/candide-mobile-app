import 'dart:convert';

import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/swap.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:dio/dio.dart';
import 'package:wallet_dart/contracts/wallet.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';

class Explorer {

  static fetchAddressOverview({
      required WalletInstance wallet,
      String? quoteCurrency,
      List<String>? currencyList}) async {
    try{
      if (currencyList != null && currencyList.isNotEmpty){
        var response = await Dio().post("${Env.explorerUri}/v1/address/${wallet.walletAddress.hexEip55}", data: jsonEncode({
          "network": Networks.getByChainId(wallet.chainId)!.name,
          "quoteCurrency": quoteCurrency ?? "USDT",
          "currencies": currencyList,
        }));
        await AddressData.updateExplorerJson(wallet, response.data);
      }
      //
      bool proxyDeployed = true;
      int nonce = 0;
      await Future.wait([
        Constants.client.getCode(wallet.walletAddress).then((value) => proxyDeployed = value.isNotEmpty),
        IWallet.interface(address: wallet.walletAddress, client: Constants.client).nonce().then((value) => nonce = value.toInt()),
      ]);
      AddressData.walletStatus = WalletStatus(
        proxyDeployed: proxyDeployed,
        nonce: nonce,
      );
    } on DioError catch(e){
      print("Error occured ${e.type.toString()}");
      print(e.response?.statusMessage);
    }
  }

  static Future<OptimalQuote?> fetchSwapQuote(String network, TokenInfo baseCurrency, TokenInfo quoteCurrency, BigInt value, String address) async {
    try{
      var response = await Dio().get("${Env.explorerUri}/v1/swap/quote",
        queryParameters: {
          "network": network,
          "baseCurrency": baseCurrency.symbol,
          "quoteCurrency": quoteCurrency.symbol,
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