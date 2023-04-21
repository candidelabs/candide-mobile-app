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
    return [1100000, 1100000]; // same value so block.baseFee doesn't get invoked from EP https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/core/EntryPoint.sol#L594
  }

  @override
  Future<GasEstimate?> getGasEstimates(UserOperation userOp, {EthereumAddress? paymasterAddress}) async {
    UserOperation dummyOp = UserOperation.fromJson(userOp.toJson()); // copy userOp to a dummy one for any modifications related to estimates
    //
    /*if (paymasterAddress != null){
      dummyOp.paymasterAndData = bytesToHex(paymasterAddress.addressBytes + Uint8List.fromList(List<int>.filled(340, 1)), include0x: true);
    }*/
    dummyOp.callGasLimit = BigInt.parse("fffffff", radix: 16);
    dummyOp.preVerificationGas = BigInt.parse("0", radix: 16);
    dummyOp.verificationGasLimit = BigInt.parse("fffffff", radix: 16);
    dummyOp.maxFeePerGas = BigInt.zero;
    dummyOp.maxPriorityFeePerGas = BigInt.zero;
    dummyOp.signature = bytesToHex(Uint8List.fromList(List<int>.filled(65, 1)), include0x: true);
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
    gasEstimate.preVerificationGas = l1GasUsed * (l1BaseFee ~/ BigInt.from(networkFees[0]));
    if (paymasterAddress != null){
      gasEstimate.preVerificationGas += BigInt.from(84); // To accommodate for GnosisTransaction.approveAmount which would be 0 before estimation
    }
    //
    gasEstimate.maxFeePerGas = BigInt.from(networkFees[0]);
    gasEstimate.maxPriorityFeePerGas = BigInt.from(networkFees[1]);
    return gasEstimate;
  }
}