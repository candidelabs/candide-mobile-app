import 'dart:convert';
import 'dart:typed_data';

import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:dio/dio.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class Bundler {

  static Future<UserOperation> signUserOperations(EthPrivateKey privateKey, int chainId, UserOperation operation) async{
    Uint8List userOpHash = (await getUserOperationHash(operation, chainId))!;
    UserOperation signedOperation = UserOperation.fromJson(operation.toJson());
    await signedOperation.sign(
      privateKey,
      BigInt.from(chainId),
      overrideRequestId: userOpHash,
    );
    return signedOperation;
  }

  static Future<RelayResponse?> relayUserOperation(UserOperation operation, int chainId) async{
    var bundlerEndpoint = Env.getBundlerUrlByChainId(chainId);
    try{
      var response = await Dio().post(
          "$bundlerEndpoint/jsonrpc/bundler",
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_sendUserOperation",
            "params": [
              operation.toJson()
            ]
          })
      );
      //
      //print(response.data);
      if ((response.data as Map).containsKey("error")){
        if (response.data["error"]["data"]["status"] == "failed-to-submit"){
          return RelayResponse(status: "failed-to-submit", hash: response.data["error"]["data"]["txHash"]);
        }
        return RelayResponse(status: "failed", hash: response.data["error"]["data"]["txHash"]);
      }
      return RelayResponse(status: response.data["result"]["status"], hash: response.data["result"]["txHash"]);
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return RelayResponse(status: "failed-to-submit", hash: null);
    }
  }

  static Future<List<FeeToken>?> fetchPaymasterFees(int chainId) async {
    var bundlerEndpoint = Env.getBundlerUrlByChainId(chainId);
    try{
      var response = await Dio().post("$bundlerEndpoint/jsonrpc/paymaster",
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
            conversion: _tokenData["tokenToEthPrice"].runtimeType == String ? BigInt.parse(_tokenData["tokenToEthPrice"]) : BigInt.from(_tokenData["tokenToEthPrice"])
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
    var bundlerEndpoint = Env.getBundlerUrlByChainId(chainId);
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


  static Future<Uint8List?> getUserOperationHash(UserOperation userOperation, int chainId) async{
    var bundlerEndpoint = Env.getBundlerUrlByChainId(chainId);
    try{
      var response = await Dio().post(
          "$bundlerEndpoint/jsonrpc/bundler",
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_getUserOpHash",
            "params": {
              "request": userOperation.toJson(),
            }
          })
      );
      //
      String? requestId = response.data["result"];
      if (requestId == null) return null;
      return hexToBytes(requestId);
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }
}