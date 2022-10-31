import 'package:candide_mobile_app/config/network.dart';
import 'package:wallet_dart/wallet/user_operation.dart';

class FeeCurrency {
  CurrencyMetadata currency;
  BigInt fee;

  FeeCurrency({required this.currency, required this.fee});
}

class FeeCurrencyUtils {
  static BigInt calculateFee(List<UserOperation> userOps) {
    BigInt fee = BigInt.zero;
    for (UserOperation op in userOps){
      BigInt opFee = BigInt.from(op.maxFeePerGas) * (BigInt.from(op.callGas) + (BigInt.from(op.verificationGas) * BigInt.from(3)) + BigInt.from(op.preVerificationGas));
      fee = fee + opFee;
    }
    return fee;
  }

  static BigInt calculateEtherFee(List<UserOperation> userOps) {
    BigInt fee = BigInt.zero;
    for (UserOperation op in userOps){
      BigInt opFee = BigInt.from(op.maxFeePerGas) * (BigInt.from(op.callGas) + BigInt.from(op.verificationGas) + BigInt.from(op.preVerificationGas));
      fee = fee + opFee;
    }
    return fee;
  }
}