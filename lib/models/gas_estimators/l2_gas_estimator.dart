import 'dart:typed_data';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/gas_estimators/gas_estimator.dart';
import 'package:candide_mobile_app/models/gas_estimators/source/ovm_gas_oracle.g.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/extensions/bigint_extensions.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:wallet_dart/contracts/factories/EntryPoint.g.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/web3dart.dart';

class L2GasEstimator extends GasEstimator {
  EthereumAddress ovmGasOracle;

  L2GasEstimator({required this.ovmGasOracle, required super.chainId});

  @override
  Future<List<BigInt>?> getNetworkGasFees() async {
    //;
    if (chainId == 420){
      BigInt baseFee = (await Networks.selected().client.getGasPrice()).getInWei;
      return [baseFee.scale(1.10), baseFee.scale(1.05)];
    }
    try{
      var response = await Dio().get("https://gas-api.metaswap.codefi.network/networks/$chainId/suggestedGasFees");
      //
      BigInt suggestedMaxFeePerGas = Decimal.parse(response.data["medium"]["suggestedMaxFeePerGas"]).shift(9).toBigInt();
      BigInt suggestedMaxPriorityFeePerGas = Decimal.parse(response.data["medium"]["suggestedMaxPriorityFeePerGas"]).shift(9).toBigInt();
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
    dummyOp.callGasLimit = BigInt.parse("fffffff", radix: 16);
    dummyOp.preVerificationGas = BigInt.parse("0", radix: 16);
    dummyOp.verificationGasLimit = BigInt.parse("fffffff", radix: 16);
    dummyOp.maxFeePerGas = BigInt.zero;
    dummyOp.maxPriorityFeePerGas = BigInt.zero;
    dummyOp.signature = bytesToHex(Uint8List.fromList(List<int>.filled(65, 1)), include0x: true);
    //
    if (prevEstimate == null){
      List<BigInt> networkFees = await getNetworkGasFees() ?? [BigInt.zero, BigInt.zero];
      gasEstimate = await Bundler.getUserOperationGasEstimates(dummyOp, chainId);
      if (gasEstimate == null) return null;
      gasEstimate.maxFeePerGas = networkFees[0];
      gasEstimate.maxPriorityFeePerGas = networkFees[1];
    }else{
      gasEstimate = prevEstimate.copy();
    }
    //
    if (gasEstimate.l1Fee == BigInt.zero || (gasEstimate.l1FeeWithPaymaster == BigInt.zero && includesPaymaster)){
      Web3Client client = Networks.getByChainId(chainId)!.client;
      OVMGasOracle gasOracle = OVMGasOracle(address: ovmGasOracle, client: client);
      late BigInt l1Fee;
      //
      if (includesPaymaster){
        dummyOp.paymasterAndData = bytesToHex(Uint8List.fromList(List<int>.filled(176, 1)), include0x: true);
      }
      //
      EntryPoint entryPoint = EntryPoint(address: Constants.addressZero, client: client);
      var callData = entryPoint.self.function("handleOps").encodeCall([
        [dummyOp.toList()],
        EthereumAddress.fromHex("0xffffffffffffffffffffffffffffffffffffffff")
      ]);
      //
      l1Fee = await gasOracle.getL1Fee(callData);
      if (includesPaymaster){
        gasEstimate.l1FeeWithPaymaster = l1Fee;
      }else{
        gasEstimate.l1Fee = l1Fee;
      }
    }
    BigInt l1Fee = includesPaymaster ? gasEstimate.l1FeeWithPaymaster : gasEstimate.l1Fee;
    BigInt _l1Fee = l1Fee ~/ gasEstimate.maxFeePerGas;
    if (_l1Fee == BigInt.zero) _l1Fee = BigInt.from(7500);
    gasEstimate.preVerificationGas = gasEstimate.basePreVerificationGas + _l1Fee;
    //
    return gasEstimate;
  }
}