import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/bundler.dart';
import 'package:candide_mobile_app/controller/explorer.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:wallet_dart/wallet/UserOperation.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:wallet_dart/wallet/wallet_helpers.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class SendHook {
  static Future<Map> buildOps({
    required WalletInstance instance,
    required String network,
    required bool isDeployed,
    required int nonce,
    required String defaultCurrency,
    //
    required String sendCurrency,
    required String toAddress,
    required BigInt value,
  }) async {
    GasEstimate? gasEstimate;
    Map? paymasterStatus;
    await Future.wait([
      Bundler.fetchPaymasterStatus(instance.walletAddress.hex, network).then((value) => paymasterStatus = value),
      Explorer.fetchGasEstimate(network).then((value) => gasEstimate = value),
    ]);
    //
    GasOverrides gasOverrides = GasOverrides.perform(gasEstimate!);
    //
    BigInt feeValue = BigInt.parse(paymasterStatus?["fees"][defaultCurrency] ?? '0');
    BigInt allowance = BigInt.parse(paymasterStatus?["allowances"][defaultCurrency] ?? '0');
    bool shouldApprovePaymaster = allowance < feeValue;
    //shouldApprovePaymaster = false; // todo delete
    //
    var approvePaymasterOp = shouldApprovePaymaster ? UserOperation.get(
      sender: instance.walletAddress,
      nonce: nonce,
      verificationGas: gasOverrides.verificationGas,
      preVerificationGas: gasOverrides.preVerificationGas,
      maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
      maxFeePerGas: gasOverrides.maxFeePerGas,
      initCode: isDeployed ? UserOperation.nullCode : bytesToHex(WalletHelpers.getInitCode(EthereumAddress.fromHex(instance.initOwner), []), include0x: true),
      callData: EncodeFunctionData.erc20Approve(
        EthereumAddress.fromHex(CurrencyMetadata.metadata[defaultCurrency]!.address),
        EthereumAddress.fromHex(paymasterStatus?["address"]),
        feeValue
      )
    ) : null;
    //
    var sendOp = UserOperation.get(
      sender: instance.walletAddress,
      nonce: nonce + (shouldApprovePaymaster ? 1 : 0),
      verificationGas: gasOverrides.verificationGas,
      preVerificationGas: gasOverrides.preVerificationGas,
      maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
      maxFeePerGas: gasOverrides.maxFeePerGas,
      //initCode: isDeployed ? UserOperation.nullCode : bytesToHex(WalletHelpers.getInitCode(EthereumAddress.fromHex(instance.initOwner), []), include0x: true), // todo delete but also think what if the first send operation is gas paid with eth
      callData: sendCurrency == Networks.get(network)!.nativeCurrency ?
        EncodeFunctionData.executeUserOp(EthereumAddress.fromHex(toAddress), value, hexToBytes(UserOperation.nullCode)) :
        EncodeFunctionData.erc20Transfer(EthereumAddress.fromHex(CurrencyMetadata.metadata[sendCurrency]!.address), EthereumAddress.fromHex(toAddress), value),
    );
    //
    List<UserOperation> userOperations = [];
    if (approvePaymasterOp != null){
      userOperations.add(approvePaymasterOp);
    }
    userOperations.add(sendOp);
    return {
      "userOperations": userOperations,
      "fee": {"currency": defaultCurrency, "value": feeValue}
    };
  }
}