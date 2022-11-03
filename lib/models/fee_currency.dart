import 'package:candide_mobile_app/config/network.dart';
import 'package:wallet_dart/wallet/user_operation.dart';

class FeeCurrency {
  CurrencyMetadata currency;
  BigInt fee;
  BigInt conversion;

  FeeCurrency({required this.currency, required this.fee, required this.conversion});
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