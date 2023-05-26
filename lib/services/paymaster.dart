import 'dart:convert';

import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/models/paymaster/fee_token.dart';
import 'package:candide_mobile_app/models/paymaster/paymaster_data.dart';
import 'package:candide_mobile_app/models/paymaster/paymaster_response.dart';
import 'package:candide_mobile_app/models/paymaster/sponsor_data.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:dio/dio.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/web3dart.dart';

class Paymaster {

  static Future<PaymasterResponse?> fetchPaymasterFees(int chainId) async {
    List<FeeToken> result = [];
    TokenInfo? _ethereum = TokenInfoStorage.getTokenByAddress(Constants.addressZeroHex);
    result.add(FeeToken(
        token: _ethereum!,
        fee: BigInt.zero,
        paymasterFee: BigInt.zero,
        exchangeRate: BigInt.parse("1000000000000000000")
    ));
    //
    var paymasterEndpoint = Env.getPaymasterUrlByChainId(chainId);
    //
    PaymasterResponse paymasterResponse = PaymasterResponse(
        tokens: result,
        paymasterData: PaymasterData(
          paymaster: Constants.addressZero,
          eventTopic: "0x",
        ),
        sponsorData: SponsorData(
          sponsored: false,
          sponsorMeta: null,
        )
    );
    if (paymasterEndpoint.trim().isEmpty || paymasterEndpoint.trim() == "-") return paymasterResponse;
    try{
      var response = await Dio().post(paymasterEndpoint,
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "pm_getApprovedTokens",
          })
      );
      //
      EthereumAddress paymasterAddress = Constants.addressZero;
      String eventTopic = "0x";
      for (Map tokenData in response.data['result']){
        paymasterAddress = EthereumAddress.fromHex(tokenData["paymaster"]);
        if (tokenData.containsKey("sponsoredEventTopic")){
          eventTopic = tokenData["sponsoredEventTopic"];
        }
        TokenInfo? _token = TokenInfoStorage.getTokenByAddress(tokenData["address"]);
        if (_token == null) continue;
        result.add(
            FeeToken(
              token: _token,
              fee: BigInt.zero,
              paymasterFee: tokenData["fee"].runtimeType == String ? BigInt.parse(tokenData["fee"]) : BigInt.from(tokenData["fee"]),
              exchangeRate: tokenData["exchangeRate"].runtimeType == String ? BigInt.parse(tokenData["exchangeRate"]) : BigInt.from(tokenData["exchangeRate"])
            )
        );
      }
      paymasterResponse.tokens = result;
      paymasterResponse.paymasterData.paymaster = paymasterAddress;
      paymasterResponse.paymasterData.eventTopic = eventTopic;
      return paymasterResponse;
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