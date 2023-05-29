import 'dart:convert';

import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:candide_mobile_app/utils/extensions/bigint_extensions.dart';
import 'package:candide_mobile_app/utils/utils.dart';
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
          bundlerEndpoint,
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_sendUserOperation",
            "params": [
              operation.toJson(),
              PersistentData.selectedAccount.entrypoint!.hexEip55,
            ]
          })
      );
      //
      if ((response.data as Map).containsKey("error")){
        return RelayResponse(status: "failed-to-submit", reason: response.data["error"]["message"]);
      }
      return RelayResponse(status: "pending", hash: response.data["result"]);
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return RelayResponse(status: "failed-to-submit", hash: null);
    }
  }

  static Future<GasEstimate?> getUserOperationGasEstimates(UserOperation operation, int chainId) async {
    var bundlerEndpoint = Env.getBundlerUrlByChainId(chainId);
    try{
      var response = await Dio().post(
          bundlerEndpoint,
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_estimateUserOperationGas",
            "params": [
              operation.toJson(),
              PersistentData.selectedAccount.entrypoint!.hexEip55,
            ]
          })
      );
      //
      if ((response.data as Map).containsKey("error")){
        return null;
      }
      return GasEstimate(
        callGasLimit: Utils.decodeBigInt(response.data["result"]["callGasLimit"]).scale(1.2),
        verificationGasLimit: Utils.decodeBigInt(response.data["result"]["verificationGas"]),
        basePreVerificationGas: Utils.decodeBigInt(response.data["result"]["preVerificationGas"]),
        preVerificationGas: BigInt.zero,
        maxFeePerGas: BigInt.zero,
        maxPriorityFeePerGas: BigInt.zero,
      );
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserOperationReceipt(String userOperationHash, int chainId) async {
    var bundlerEndpoint = Env.getBundlerUrlByChainId(chainId);
    try{
      var response = await Dio().post(
          bundlerEndpoint,
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_getUserOperationReceipt",
            "params": [
              userOperationHash,
            ]
          })
      );
      //
      if ((response.data as Map).containsKey("error")){
        return null;
      }
      return response.data["result"];
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }

}