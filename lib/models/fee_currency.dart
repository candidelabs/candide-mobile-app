import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:wallet_dart/wallet/user_operation.dart';
import 'package:web3dart/credentials.dart';

class FeeToken {
  EthereumAddress paymaster;
  TokenInfo token;
  BigInt fee;

  FeeToken({required this.paymaster, required this.token, required this.fee});
}

class FeeCurrencyUtils {
  static final BigInt costOfPost = BigInt.from(35000); // todo shouldn't be hardcoded

  static BigInt calculateFee(UserOperation op, bool isEther) {
    BigInt operationMaxEthCostUsingPaymaster = op.maxFeePerGas * (costOfPost + op.callGasLimit + (op.verificationGasLimit * BigInt.from(isEther ? 1 : 3)) + op.preVerificationGas);
    return operationMaxEthCostUsingPaymaster;
  }
}