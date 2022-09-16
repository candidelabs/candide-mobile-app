import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/swap.dart';
import 'package:candide_mobile_app/controller/bundler.dart';
import 'package:candide_mobile_app/controller/explorer.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:wallet_dart/wallet/UserOperation.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:wallet_dart/wallet/wallet_helpers.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class SwapHook {
  static Future<List<UserOperation>> buildOps({
    required WalletInstance instance,
    required String network,
    required bool isDeployed,
    required int nonce,
    required String defaultCurrency,
    //
    required String baseCurrency,
    required BigInt baseCurrencyValue,
    //
    required GasEstimate gasEstimate,
    required Map paymasterStatus,
    required OptimalQuote optimalQuote,
  }) async {
    //
    GasOverrides gasOverrides = GasOverrides.perform(gasEstimate);
    //
    BigInt feeValue = BigInt.parse(paymasterStatus["fees"][defaultCurrency] ?? '0');
    BigInt allowance = BigInt.parse(paymasterStatus["allowances"][defaultCurrency] ?? '0');
    bool shouldApprovePaymaster = allowance < feeValue;
    bool shouldApproveRouter = baseCurrency != Networks.get(network)!.nativeCurrency;
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
            EthereumAddress.fromHex(paymasterStatus["address"]),
            feeValue
        )
    ) : null;
    //
    var approveRouterOp = shouldApproveRouter ? UserOperation.get(
        sender: instance.walletAddress,
        nonce: nonce + (shouldApprovePaymaster ? 1 : 0),
        verificationGas: gasOverrides.verificationGas,
        preVerificationGas: gasOverrides.preVerificationGas,
        maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
        maxFeePerGas: gasOverrides.maxFeePerGas,
        initCode: (isDeployed || shouldApprovePaymaster) ? UserOperation.nullCode : bytesToHex(WalletHelpers.getInitCode(EthereumAddress.fromHex(instance.initOwner), []), include0x: true),
        callData: EncodeFunctionData.erc20Approve(
            EthereumAddress.fromHex(CurrencyMetadata.metadata[baseCurrency]!.address),
            EthereumAddress.fromHex(optimalQuote.transaction["to"].toString()),
            baseCurrencyValue
        )
    ) : null;
    //
    var swapOp = UserOperation.get(
      sender: instance.walletAddress,
      nonce: nonce + (shouldApprovePaymaster ? 1 : 0) + (shouldApproveRouter ? 1 : 0),
      verificationGas: gasOverrides.verificationGas,
      preVerificationGas: gasOverrides.preVerificationGas,
      maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
      maxFeePerGas: gasOverrides.maxFeePerGas,
      callData: EncodeFunctionData.executeUserOp(
        EthereumAddress.fromHex(optimalQuote.transaction["to"].toString()),
        BigInt.parse(optimalQuote.transaction["value"]),
        hexToBytes(optimalQuote.transaction["data"]),
      )
    );
    //
    List<UserOperation> userOperations = [];
    if (approvePaymasterOp != null){
      userOperations.add(approvePaymasterOp);
    }
    if (approveRouterOp != null){
      userOperations.add(approveRouterOp);
    }
    userOperations.add(swapOp);
    return userOperations;
  }
}