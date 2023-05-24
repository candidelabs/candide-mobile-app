import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:wallet_dart/wallet/user_operation.dart';

class FeeToken {
  TokenInfo token;
  BigInt fee;
  BigInt paymasterFee;
  BigInt exchangeRate;

  FeeToken({required this.token, required this.fee, required this.paymasterFee, required this.exchangeRate});

  static final BigInt costOfPost = BigInt.from(45000); // todo shouldn't be hardcoded

  BigInt calculateETHFee(UserOperation op, Network network) {
    bool isEther = token.symbol == network.nativeCurrency && token.address == Constants.addressZeroHex;
    BigInt operationMaxEthCost = op.maxFeePerGas * (costOfPost + op.callGasLimit + (op.verificationGasLimit * BigInt.from(isEther ? 1 : 3)) + op.preVerificationGas);
    return operationMaxEthCost;
  }

  BigInt calculateFee(UserOperation op, Network network) {
    BigInt operationMaxEthCost = calculateETHFee(op, network);
    BigInt tokenFee = (operationMaxEthCost * exchangeRate) ~/ BigInt.from(10).pow(18);
    tokenFee += paymasterFee;
    return tokenFee;
  }
}