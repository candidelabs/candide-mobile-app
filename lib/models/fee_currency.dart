import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/credentials.dart';

class FeeToken {
  EthereumAddress paymaster;
  TokenInfo token;
  BigInt fee;
  BigInt conversion;

  FeeToken({required this.paymaster, required this.token, required this.fee, required this.conversion});
}

class FeeCurrencyUtils {
  static BigInt calculateFee(UserOperation op, BigInt conversion, bool isEther) {
    BigInt operationMaxEthCostUsingPaymaster = BigInt.from(op.maxFeePerGas) * (BigInt.from(op.callGasLimit) + (BigInt.from(op.verificationGasLimit) * BigInt.from(isEther ? 1 : 3)) + BigInt.from(op.preVerificationGas));
    BigInt tokenToEthPrice = operationMaxEthCostUsingPaymaster * (conversion ~/ BigInt.from(10).pow(18));
    return tokenToEthPrice;
  }
}