import 'dart:typed_data';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/gas_estimators/gas_estimator.dart';
import 'package:candide_mobile_app/models/gas_estimators/source/ovm_gas_oracle.g.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:wallet_dart/contracts/factories/EntryPoint.g.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/web3dart.dart';

class L2GasEstimator extends GasEstimator {
  EthereumAddress ovmGasOracle;

  L2GasEstimator({required this.ovmGasOracle, required super.chainId});

  @override
  Future<List<int>?> getNetworkGasFees() async {
    return [1100000, 1000000];
  }

  @override
  Future<GasEstimate?> getGasEstimates(UserOperation userOp, {required bool includesPaymaster}) async {
    UserOperation dummyOp = UserOperation.fromJson(userOp.toJson()); // copy userOp to a dummy one for any modifications related to estimates
    //
    if (includesPaymaster){
      dummyOp.paymasterAndData = bytesToHex(Uint8List.fromList(List<int>.filled(150, 1)));
    }
    dummyOp.signature = bytesToHex(Uint8List.fromList(List<int>.filled(65, 1)));
    //
    List<int> networkFees = await getNetworkGasFees() ?? [0, 0];
    GasEstimate? gasEstimate = await Bundler.getUserOperationGasEstimates(dummyOp, chainId);
    if (gasEstimate == null) return null;
    //
    Web3Client client = Networks.getByChainId(chainId)!.client;
    OVMGasOracle gasOracle = OVMGasOracle(address: ovmGasOracle, client: client);
    late BigInt l1GasUsed;
    late BigInt l1BaseFee;
    EntryPoint entryPoint = EntryPoint(address: Constants.addressZero, client: client);
    var callData = entryPoint.self.function("handleOps").encodeCall([
      [dummyOp.toList()],
      dummyOp.sender
    ]);
    await Future.wait([
      gasOracle.getL1GasUsed(callData).then((value) => l1GasUsed = value),
      gasOracle.l1BaseFee().then((value) => l1BaseFee = value),
    ]);
    //
    var totalGas = (gasEstimate.callGasLimit + gasEstimate.preVerificationGas + gasEstimate.verificationGasLimit);
    var totalCost = ((l1GasUsed * l1BaseFee) + BigInt.from(totalGas * networkFees[0]));
    var newFee = totalCost / BigInt.from(totalGas);
    //
    gasEstimate.maxFeePerGas = newFee.toInt();
    gasEstimate.maxPriorityFeePerGas = newFee.toInt() + 100000;
    return gasEstimate;
  }
}