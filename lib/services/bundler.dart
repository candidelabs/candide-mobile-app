import 'dart:convert';
import 'dart:typed_data';

import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:dio/dio.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class Bundler {

  static Future<UserOperation> signUserOperations(Credentials signer, String network, UserOperation operation) async{
    List<Uint8List> requestIds = (await getRequestIds([operation]))!;
    UserOperation signedOperation = UserOperation.fromJson(operation.toJson());
    await signedOperation.sign(
      signer,
      Networks.getByName(network)!.chainId,
      overrideRequestId: requestIds[0],
    );
    return signedOperation;
  }

  static Future<RelayResponse?> relayUserOperation(UserOperation operation, String network) async{
    try{
      var response = await Dio().post(
          "${Env.bundlerUri}/jsonrpc/bundler",
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_sendUserOperation",
            "params": [
              [operation.toJson()]
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

  static Future<List<FeeToken>?> fetchPaymasterFees() async {
    try{
      var response = await Dio().post("${Env.bundlerUri}/jsonrpc/paymaster",
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
        result.add(FeeToken(token: _token, fee: BigInt.zero, conversion: _tokenData["tokenToEthPrice"].runtimeType == String ? BigInt.parse(_tokenData["tokenToEthPrice"]) : BigInt.from(_tokenData["tokenToEthPrice"])));
      }
      return result;
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }

  static Future<List<GasEstimate>?> getOperationsGasFees(List<UserOperation> userOperations) async{
    try{
      var response = await Dio().post(
          "${Env.bundlerUri}/jsonrpc/bundler",
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_getOperationsGasValues",
            "params": {
              "request": userOperations.map((e) => e.toJson()).toList(),
            }
          })
      );
      //
      List<GasEstimate> result = [];
      for (var op in response.data["result"]){
        GasEstimate estimate = GasEstimate(
          callGas: op["callGas"],
          preVerificationGas: op["preVerificationGas"],
          verificationGas: op["verificationGas"],
          maxPriorityFeePerGas: op["maxPriorityFeePerGas"],
          maxFeePerGas: op["maxFeePerGas"]
        );
        result.add(estimate);
      }
      return result;
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }

  static Future<List<String>?> getPaymasterSignature(List<UserOperation> userOperations, String tokenAddress) async{
    try{
      var response = await Dio().post(
          "${Env.bundlerUri}/jsonrpc/paymaster",
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_paymaster",
            "params": {
              "request": userOperations.map((e) => e.toJson()).toList(),
              "token": tokenAddress,
            }
          })
      );
      //
      return (response.data["result"] as List<dynamic>).cast<String>();
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }


  static Future<List<Uint8List>?> getRequestIds(List<UserOperation> userOperations) async{
    try{
      var response = await Dio().post(
          "${Env.bundlerUri}/jsonrpc/bundler",
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_getRequestIds",
            "params": {
              "request": userOperations.map((e) => e.toJson()).toList(),
            }
          })
      );
      //
      List<Uint8List> result = [];
      for (String requestId in response.data["result"]){
        result.add(hexToBytes(requestId));
      }
      return result;
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }
}