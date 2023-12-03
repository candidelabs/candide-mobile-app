import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:candide_mobile_app/models/user_operation_receipt.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:http/http.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/web3dart.dart';

class Bundler {
  late JsonRPC jsonRpc;

  Bundler(String endpoint, Client client){
    jsonRpc = JsonRPC(endpoint, client);
  }

  static Future<UserOperation> signUserOperations(EthPrivateKey privateKey, EthereumAddress entryPoint, int chainId, UserOperation operation) async{
    UserOperation signedOperation = UserOperation.fromJson(operation.toJson());
    await signedOperation.sign(
      privateKey,
      entryPoint,
      BigInt.from(chainId),
    );
    return signedOperation;
  } // todo: doesn't belong to this file

  Future<BigInt?> getChainId() async {
    try{
      var response = await jsonRpc.call("eth_chainId", []);
      return Utils.decodeBigInt(response.result);
    } on RPCError catch(e){
      print("Error occurred (${e.errorCode}, ${e.message})");
      return null;
    } on Exception catch(e){
      print("Error occurred $e");
      return null;
    }
  }

  Future<List<EthereumAddress>?> getSupportedEntryPoints() async {
    try{
      var response = await jsonRpc.call("eth_supportedEntryPoints", []);
      return (response.result as List<dynamic>).map((e) => EthereumAddress.fromHex(e)).toList();
    } on RPCError catch(e){
      print("Error occurred (${e.errorCode}, ${e.message})");
      return null;
    } on Exception catch(e){
      print("Error occurred $e");
      return null;
    }
  }

  Future<RelayResponse?> sendUserOperation(UserOperation userOp) async{
    try{
      var response = await jsonRpc.call(
          "eth_sendUserOperation",
          [
            userOp.toJson(),
            PersistentData.selectedAccount.entrypoint!.hexEip55,
          ]
      );
      return RelayResponse(status: "pending", hash: response.result);
    } on RPCError catch(e){
      print("Error occurred (${e.errorCode}, ${e.message})");
      return RelayResponse(status: "failed-to-submit", reason: e.message, hash: null);
    } on Exception catch(e){
      print("Error occurred $e");
      return RelayResponse(status: "failed-to-submit", hash: null);
    }
  }

  Future<GasEstimate?> estimateUserOperationGas(UserOperation userOp) async {
    try{
      var response = await jsonRpc.call(
          "eth_estimateUserOperationGas",
          [
            userOp.toJson(),
            PersistentData.selectedAccount.entrypoint!.hexEip55,
          ]
      );
      return GasEstimate(
        callGasLimit: Utils.decodeBigInt(response.result["callGasLimit"], defaultsToZero: true)!,
        verificationGasLimit: Utils.decodeBigInt(response.result["verificationGasLimit"], defaultsToZero: true)!,
        preVerificationGas: Utils.decodeBigInt(response.result["preVerificationGas"], defaultsToZero: true)!,
        maxFeePerGas: BigInt.zero,
        maxPriorityFeePerGas: BigInt.zero,
      );
    } on RPCError catch(e){
      print("Error occurred (${e.errorCode}, ${e.message})");
      return null;
    } on Exception catch(e){
      print("Error occurred $e");
      return null;
    }
  }

  Future<UserOperationReceipt?> getUserOperationReceipt(String userOperationHash) async {
    try{
      var response = await jsonRpc.call(
          "eth_getUserOperationReceipt",
          [userOperationHash]
      );
      return UserOperationReceipt.fromMap(response.result);
    } on RPCError catch(e){
      print("Error occurred (${e.errorCode}, ${e.message})");
      return null;
    } on Exception catch(e){
      print("Error occurred $e");
      return null;
    }
  }
}