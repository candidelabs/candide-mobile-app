import 'dart:convert';
import 'dart:typed_data';

import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:dio/dio.dart';
import 'package:magic_sdk/magic_sdk.dart';
import 'package:wallet_dart/wallet/UserOperation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class Bundler {
  static Future<Map?> fetchPaymasterStatus(String address, String network) async {
    try{
      var response = await Dio().get("${Env.legacyBundlerUri}/v1/paymaster/status", queryParameters: {
        "address": address,
        "network": network,
      });
      //
      return response.data;
    } on DioError catch(e){
      print("Error occured ${e.type.toString()}");
      return null;
    }
  }

  static Future<List<UserOperation>?> requestPaymasterSignature(List<UserOperation> userOperations, String network) async {
    try{
      var response = await Dio().post(
        "${Env.legacyBundlerUri}/v1/paymaster/sign",
        data: jsonEncode({
          "network": network,
          "userOperations": userOperations.map((e) => e.toJson()).toList()
        })
      );

      //
      return (response.data["userOperations"] as List).map((e) => UserOperation.fromJson(e)).toList();
    } on DioError catch(e){
      print("Error occured ${e.type.toString()}");
      return null;
    }
  }

  static bool verifyUserOperationsWithPaymaster(List<UserOperation> userOperations, List<UserOperation> userOperationsWithPaymaster){
    if (userOperations.length != userOperationsWithPaymaster.length) return false;
    for (int i=0; i < userOperations.length; i++){
      if (userOperations[i].sender.hex != userOperationsWithPaymaster[i].sender.hex
          || userOperations[i].nonce != userOperationsWithPaymaster[i].nonce
          || userOperations[i].initCode != userOperationsWithPaymaster[i].initCode
          || userOperations[i].callData != userOperationsWithPaymaster[i].callData
          || userOperations[i].callGas != userOperationsWithPaymaster[i].callGas
          || userOperations[i].verificationGas != userOperationsWithPaymaster[i].verificationGas
          || userOperations[i].preVerificationGas != userOperationsWithPaymaster[i].preVerificationGas
          || userOperations[i].maxFeePerGas != userOperationsWithPaymaster[i].maxFeePerGas
          || userOperations[i].maxPriorityFeePerGas != userOperationsWithPaymaster[i].maxPriorityFeePerGas){
        return false;
      }
    }
    return true;
  }

  static Future<List<UserOperation>> signUserOperations(Credentials signer, String network, List<UserOperation> userOperations) async{
    List<UserOperation> signedOperations = [];
    for (UserOperation operation in userOperations){
      UserOperation signedOperation = UserOperation.fromJson(operation.toJson());
      await signedOperation.sign(
        signer,
        Networks.get(network)!.chainId,
        overrideRequestId: await getRequestId(operation, network)
      );
      signedOperations.add(signedOperation);
    }
    return signedOperations;
  }

  static Future<List<UserOperation>?> signUserOperationsAsGuardian(Credentials credentials, String network, List<UserOperation> userOperations) async{
    List<UserOperation> signedOperations = [];
    for (UserOperation operation in userOperations){
      UserOperation signedOperation = UserOperation.fromJson(operation.toJson());
      await signedOperation.signAsGuardian(credentials, Networks.get(network)!.chainId);
      signedOperations.add(signedOperation);
    }
    return signedOperations;
  }

  static Future<List<UserOperation>?> signUserOperationsAsMagicLink(String network, List<UserOperation> userOperations) async{
    var magic = Magic.instance;
    try{
      var isLoggedIn = await magic.user.isLoggedIn();
      if (!isLoggedIn) return null;
      var metadata = await magic.user.getMetadata();
      if (metadata.publicAddress == null) return null;
    } on Exception catch (e) {
      print(e);
      return null;
    }
    final credentials = MagicCredential(magic.provider);
    await credentials.getAccount();
    List<UserOperation> signedOperations = [];
    for (UserOperation operation in userOperations){
      UserOperation signedOperation = UserOperation.fromJson(operation.toJson());
      await signedOperation.signAsGuardian(credentials, Networks.get(network)!.chainId, isMagicLink: true);
      signedOperations.add(signedOperation);
    }
    return signedOperations;
  }

  static Future<RelayResponse?> relayUserOperations(List<UserOperation> userOperations, String network) async{
    try{
      var response = await Dio().post(
          "${Env.bundlerUri}/jsonrpc/bundler",
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_sendUserOperation",
            "params": [
              userOperations.map((e) => e.toJson()).toList()
            ]
          })
      );
      //
      //RelayResponse relayResponse = RelayResponse(status: response.data["status"], hash: response.data["hash"] ?? "");
      return RelayResponse(status: "SUCCESS", hash: ""); // todo real output
    } on DioError catch(e){
      print("Error occured ${e.type.toString()}");
      return null;
    }
  }

  static Future<List<FeeCurrency>?> fetchPaymasterFees() async {
    try{
      var response = await Dio().post("${Env.bundlerUri}/jsonrpc/paymaster",
        data: jsonEncode({
          "jsonrpc": "2.0",
          "id": 1,
          "method": "eth_paymaster_approved_tokens",
        })
      );
      //
      List<FeeCurrency> result = [];
      for (String tokenData in response.data['result']){
        var _tokenData = jsonDecode(tokenData.replaceAll("'", '"'));
        CurrencyMetadata? _currency = CurrencyMetadata.findByAddress(_tokenData["address"]);
        if (_currency == null) continue;
        result.add(FeeCurrency(currency: _currency, fee: BigInt.parse(_tokenData["price"])));
      }
      return result;
    } on DioError catch(e){
      print("Error occured ${e.type.toString()}");
      return null;
    }
  }

  static Future<String?> getPaymasterSignature(UserOperation userOperation) async{
    try{
      var response = await Dio().post(
          "${Env.bundlerUri}/jsonrpc/paymaster",
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_paymaster",
            "params": [
              userOperation.toJson()
            ]
          })
      );
      //
      return response.data["result"];
    } on DioError catch(e){
      print("Error occured ${e.type.toString()}");
      return null;
    }
  }


  static Future<Uint8List?> getRequestId(UserOperation userOperation, String network, {bool returnHash=false}) async{
    try{
      var response = await Dio().post(
          "${Env.bundlerUri}/jsonrpc/bundler",
          data: jsonEncode({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_getRequestId",
            "params": [
              userOperation.toJson()
            ]
          })
      );
      //
      return hexToBytes(response.data["result"]);
    } on DioError catch(e){
      print("Error occured ${e.type.toString()}");
      return null;
    }
  }
}