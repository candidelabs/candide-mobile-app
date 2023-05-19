import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:wallet_dart/wallet/user_operation.dart';

class FeeToken {
  TokenInfo token;
  BigInt fee;
  BigInt exchangeRate;

  FeeToken({required this.token, required this.fee, required this.exchangeRate});
}

class FeeCurrencyUtils {
  static final BigInt costOfPost = BigInt.from(45000); // todo shouldn't be hardcoded

  static BigInt calculateFee(UserOperation op, BigInt exchangeRate, bool isEther) {
    BigInt operationMaxEthCostUsingPaymaster = op.maxFeePerGas * (costOfPost + op.callGasLimit + (op.verificationGasLimit * BigInt.from(isEther ? 1 : 3)) + op.preVerificationGas);
    BigInt tokenToEthPrice = (operationMaxEthCostUsingPaymaster * exchangeRate) ~/ BigInt.from(10).pow(18);
    return tokenToEthPrice;
  }
}