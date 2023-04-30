import 'dart:convert';

import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:dio/dio.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/web3dart.dart';

class Paymaster {

  static Future<List<FeeToken>?> fetchPaymasterFees(int chainId) async {
    var paymasterEndpoint = Env.getPaymasterUrlByChainId(chainId);
    try{
      var response = await Dio().post(paymasterEndpoint,
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "pm_getApprovedTokens",
          })
      );
      //
      List<FeeToken> result = [];
      //
      TokenInfo? _ethereum = TokenInfoStorage.getTokenByAddress(Networks.selected().nativeCurrencyAddress.hexEip55);
      result.add(FeeToken(
        paymaster: Constants.addressZero,
        token: _ethereum!,
        fee: BigInt.zero,
        exchangeRate: BigInt.parse("1000000000000000000")
      ));
      //
      print(response.data);
      for (Map tokenData in response.data['result']){
        TokenInfo? _token = TokenInfoStorage.getTokenByAddress(tokenData["address"]);
        if (_token == null) continue;
        result.add(
            FeeToken(
              paymaster: EthereumAddress.fromHex(tokenData["paymaster"]),
              paymasterEventTopic: tokenData["paymasterEventTopic"],
              token: _token,
              fee: BigInt.zero,
              exchangeRate: tokenData["exchangeRate"].runtimeType == String ? BigInt.parse(tokenData["exchangeRate"]) : BigInt.from(tokenData["exchangeRate"])
            )
        );
      }
      return result;
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }


  static Future<String?> getPaymasterData(UserOperation userOperation, String tokenAddress, int chainId) async{
    var paymasterEndpoint = Env.getPaymasterUrlByChainId(chainId);
    try{
      var response = await Dio().post(
          paymasterEndpoint,
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "pm_sponsorUserOperation",
            "params": {
              "request": userOperation.toJson(),
              "token_address": tokenAddress,
            }
          })
      );
      //
      return response.data["result"];
    } on DioError catch(e){
      print("${e.message}");
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }

}