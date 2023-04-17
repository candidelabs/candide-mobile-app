import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/swap.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/services/balance_service.dart';
import 'package:dio/dio.dart';
import 'package:wallet_dart/contracts/account.dart';
import 'package:wallet_dart/wallet/account.dart';

class Explorer {

  static fetchAddressOverview({
    required Account account,
    List<TokenInfo>? additionalCurrencies,
    bool skipBalances = false,
  }) async {
    try{
      if (!skipBalances){
        var balances = await BalanceService.fetchBalances(account: account, additionalCurrencies: additionalCurrencies ?? []);
        await PersistentData.updateExplorerJson(account, balances);
      }
      //
      bool proxyDeployed = true;
      int nonce = 0;
      await Future.wait([
        Networks.selected().client.getCode(account.address).then((value) => proxyDeployed = value.isNotEmpty),
        IAccount.interface(address: account.address, client: Networks.selected().client).getNonce().then((value) => nonce = value.toInt()).catchError((e, st){
          return 0;
        }),
      ]);
      PersistentData.accountStatus = AccountStatus(
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