import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/models/gas.dart';

class FeeToken {
  TokenInfo token;
  BigInt fee;
  BigInt paymasterFee;
  BigInt exchangeRate;

  FeeToken({required this.token, required this.fee, required this.paymasterFee, required this.exchangeRate});

  static final BigInt costOfPost = BigInt.from(45000); // todo shouldn't be hardcoded

  BigInt calculateETHFee(GasEstimate gasEstimate, Network network, bool withPaymaster) {
    BigInt operationMaxEthCost = gasEstimate.maxFeePerGas * (costOfPost + gasEstimate.callGasLimit + (gasEstimate.verificationGasLimit * BigInt.from(!withPaymaster ? 1 : 3)) + gasEstimate.preVerificationGas);
    return operationMaxEthCost;
  }

  BigInt calculateFee(GasEstimate gasEstimate, Network network, bool withPaymaster) {
    BigInt operationMaxEthCost = calculateETHFee(gasEstimate, network, withPaymaster);
    BigInt tokenFee = (operationMaxEthCost * exchangeRate) ~/ BigInt.from(10).pow(18);
    tokenFee += paymasterFee;
    return tokenFee;
  }
}