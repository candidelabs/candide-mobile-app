import 'dart:convert';

import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:candide_mobile_app/utils/extensions/bigint_extensions.dart';
import 'package:dio/dio.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/web3dart.dart';

class Bundler {

  static Future<UserOperation> signUserOperations(EthPrivateKey privateKey, EthereumAddress entryPoint, int chainId, UserOperation operation) async{
    UserOperation signedOperation = UserOperation.fromJson(operation.toJson());
    await signedOperation.sign(
      privateKey,
      entryPoint,
      BigInt.from(chainId),
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

  static Future<GasEstimate?> getUserOperationGasEstimates(UserOperation operation, int chainId) async {
    var bundlerEndpoint = Env.getBundlerUrlByChainId(chainId);
    try{
      var response = await Dio().post(
          "$bundlerEndpoint/jsonrpc/bundler",
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_estimateUserOperationGas",
            "params": [
              operation.toJson()
            ]
          })
      );
      //
      if ((response.data as Map).containsKey("error")){
        return null;
      }
      return GasEstimate(
        callGasLimit: BigInt.parse(response.data["result"]["callGasLimit"].replaceAll("0x", ""), radix: 16).scale(1.2),
        verificationGasLimit: BigInt.parse(response.data["result"]["verificationGasLimit"].replaceAll("0x", ""), radix: 16),
        preVerificationGas: BigInt.parse(response.data["result"]["preVerificationGas"].replaceAll("0x", ""), radix: 16),
        maxFeePerGas: BigInt.zero,
        maxPriorityFeePerGas: BigInt.zero,
      );
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }

}