import 'dart:typed_data';

import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/gas_estimators/gas_estimator.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:dio/dio.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class L1GasEstimator extends GasEstimator {

  L1GasEstimator({required super.chainId});

  @override
  Future<List<int>?> getNetworkGasFees() async {
    if (chainId == 11155111) return [1510000000, 1500000000];
    try{
      var response = await Dio().get("https://gas-api.metaswap.codefi.network/networks/$chainId/suggestedGasFees");
      //
      int suggestedMaxFeePerGas = (double.parse(response.data["medium"]["suggestedMaxFeePerGas"]) * 1000).ceil();
      int suggestedMaxPriorityFeePerGas = (double.parse(response.data["medium"]["suggestedMaxPriorityFeePerGas"]) * 1000).ceil();
      suggestedMaxFeePerGas = EtherAmount.fromUnitAndValue(EtherUnit.mwei, suggestedMaxFeePerGas).getInWei.toInt();
      suggestedMaxPriorityFeePerGas = EtherAmount.fromUnitAndValue(EtherUnit.mwei, suggestedMaxPriorityFeePerGas).getInWei.toInt();
      //
      return [suggestedMaxFeePerGas, suggestedMaxPriorityFeePerGas];
    } on DioError catch(e){
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }

  @override
  Future<GasEstimate?> getGasEstimates(UserOperation userOp, {GasEstimate? prevEstimate, bool includesPaymaster = false}) async {
    GasEstimate? gasEstimate;
    UserOperation dummyOp = UserOperation.fromJson(userOp.toJson()); // copy userOp to a dummy one for any modifications related to estimates
    //
    dummyOp.callGasLimit = BigInt.parse("ffffffffffffff", radix: 16);
    dummyOp.preVerificationGas = BigInt.parse("0", radix: 16);
    dummyOp.verificationGasLimit = BigInt.parse("ffffffffffff", radix: 16);
    dummyOp.maxFeePerGas = BigInt.zero;
    dummyOp.maxPriorityFeePerGas = BigInt.zero;
    dummyOp.signature = bytesToHex(Uint8List.fromList(List<int>.filled(65, 1)), include0x: true);
    //
    if (prevEstimate == null){
      List<int> networkFees = await getNetworkGasFees() ?? [0, 0];
      gasEstimate = await Bundler.getUserOperationGasEstimates(dummyOp, chainId);
      if (gasEstimate == null) return null;
      gasEstimate.maxFeePerGas = BigInt.from(networkFees[0]);
      gasEstimate.maxPriorityFeePerGas = BigInt.from(networkFees[1]);
    }else{
      gasEstimate = prevEstimate.copy();
    }
    if (includesPaymaster){
      gasEstimate.preVerificationGas += BigInt.from(84); // To accommodate for GnosisTransaction.approveAmount which would be 0 before estimation
      gasEstimate.preVerificationGas += BigInt.from(2496); // to accommodate for paymasterAndData (156 bytes * 16)
    }
    gasEstimate.preVerificationGas += BigInt.from(1260);
    return gasEstimate;
  }
}