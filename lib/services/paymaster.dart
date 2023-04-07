import 'dart:convert';

import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/models/gas_estimators/source/paymaster_contract.g.dart';
import 'package:dio/dio.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/web3dart.dart';

class Paymaster {

  static Future<List<FeeToken>?> fetchPaymasterFees(int chainId) async {
    var paymasterEndpoint = Env.getPaymasterUrlByChainId(chainId);
    try{
      var response = await Dio().post("$paymasterEndpoint/jsonrpc/paymaster",
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_paymaster_approved_tokens",
          })
      );
      //
      List<FeeToken> result = [];
      for (String tokenData in response.data['result']){
        var _tokenData = jsonDecode(tokenData.replaceAll("'", '"'));
        TokenInfo? _token = TokenInfoStorage.getTokenByAddress(_tokenData["address"]);
        if (_token == null) continue;
        result.add(
            FeeToken(
                paymaster: EthereumAddress.fromHex(_tokenData["paymaster"]),
                token: _token,
                fee: BigInt.zero,
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
    var bundlerEndpoint = Env.getPaymasterUrlByChainId(chainId);
    try{
      var response = await Dio().post(
          "$bundlerEndpoint/jsonrpc/paymaster",
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_paymaster",
            "params": {
              "request": userOperation.toJson(),
              "token": tokenAddress,
            }
          })
      );
      //
      return response.data["result"];
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }

  static Future<BigInt?> getDerivedValue(EthereumAddress paymaster, int chainId, FeeToken feeToken, BigInt amount) async {
    Network network = Networks.getByChainId(chainId)!;
    try {
      BigInt result = await PaymasterContract(client: network.client, address: paymaster, chainId: chainId).getDerivedValue(EthereumAddress.fromHex(feeToken.token.address), amount);
      return result;
    } on Exception catch(e){
      print("Error occurred ${e.toString()}");
      return null;
    }
  }

}