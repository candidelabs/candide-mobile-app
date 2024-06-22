import 'dart:typed_data';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/paymaster/paymaster_response.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:candide_mobile_app/utils/extensions/bigint_extensions.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/crypto.dart';

class GasEstimator {

  static GasEstimator? _instance;

  GasEstimator();

  static GasEstimator instance() {
    if (_instance == null){
      _instance = GasEstimator();
      return _instance!;
    }
    return _instance!;
  }

  Future<(BigInt, BigInt)?> _getNetworkFeesFromMetaswap(Network network) async {
    try{
      var response = await Dio().get("https://gas-api.metaswap.codefi.network/networks/${network.chainId.toInt()}/suggestedGasFees");
      //
      BigInt suggestedMaxFeePerGas = Decimal.parse(response.data["medium"]["suggestedMaxFeePerGas"]).shift(9).toBigInt();
      BigInt suggestedMaxPriorityFeePerGas = Decimal.parse(response.data["medium"]["suggestedMaxPriorityFeePerGas"]).shift(9).toBigInt();
      //
      return (suggestedMaxFeePerGas, suggestedMaxPriorityFeePerGas);
    } on DioException catch(e){
      print("Error occurred ${e.type.toString()}");
      return null;
    }
  }

  Future<(BigInt, BigInt)?> _getNetworkFeesFromProvider(Network network) async {
    BigInt baseFee = (await network.client.getGasPrice()).getInWei;
    return (baseFee.scale(1.10), baseFee.scale(1.05));
  }

  Future<(BigInt, BigInt)?> getNetworkGasFees(Network network) async {
    int chainId = network.chainId.toInt();
    if (chainId == 11155111 || chainId == 10){
      return _getNetworkFeesFromProvider(network);
    }
    try{
      return _getNetworkFeesFromMetaswap(network);
    } on Exception catch (_) {
      return _getNetworkFeesFromProvider(network);
    }
  }

  Future<GasEstimate?> getGasEstimates(UserOperation userOp, Bundler bundler, PaymasterResponse? paymasterResponse) async {
    bool includesPaymaster = paymasterResponse != null && paymasterResponse.paymasterData.address != Constants.addressZero;
    GasEstimate? gasEstimate;
    UserOperation dummyOp = UserOperation.fromJson(userOp.toJson()); // copy userOp to a dummy one for any modifications related to estimates
    //
    var dummySignature = List<int>.filled(64, 1, growable: true);
    dummySignature.add(28);
    dummyOp.callGasLimit = BigInt.parse("fffff", radix: 16);
    dummyOp.preVerificationGas = BigInt.parse("0", radix: 16);
    dummyOp.verificationGasLimit = BigInt.parse("ffffff", radix: 16);
    dummyOp.paymasterAndData = paymasterResponse?.paymasterData.dummyPaymasterAndData ?? "0x";
    dummyOp.signature = bytesToHex(Uint8List.fromList(dummySignature), include0x: true);
    //
    gasEstimate = await bundler.estimateUserOperationGas(dummyOp);
    if (gasEstimate == null) return null;
    gasEstimate.maxFeePerGas = userOp.maxFeePerGas;
    gasEstimate.maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
    if (includesPaymaster){
      // To accommodate for the maximum of GnosisTransaction.paymaster + GnosisTransaction.approveAmount + GnosisTransaction.approveToken which would all be 0 before estimation
      gasEstimate.preVerificationGas += BigInt.from((512+320+320) - (128+80+80));
    }
    return gasEstimate;
  }
}