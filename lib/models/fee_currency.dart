import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:wallet_dart/wallet/user_operation.dart';

class FeeToken {
  TokenInfo token;
  BigInt fee;
  BigInt conversion;

  FeeToken({required this.token, required this.fee, required this.conversion});
}

class FeeCurrencyUtils {
  static BigInt calculateFee(List<UserOperation> userOps, BigInt conversion, bool isEther) {
    BigInt fee = BigInt.zero;
    for (UserOperation op in userOps){
      BigInt operationMaxEthCostUsingPaymaster = BigInt.from(op.maxFeePerGas) * (BigInt.from(op.callGas) + (BigInt.from(op.verificationGas) * BigInt.from(isEther ? 1 : 3)) + BigInt.from(op.preVerificationGas));
      BigInt tokenToEthPrice = operationMaxEthCostUsingPaymaster * (conversion ~/ BigInt.from(10).pow(18));
      fee = fee + tokenToEthPrice;
    }
    return fee;
  }
}