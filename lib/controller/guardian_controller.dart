import 'dart:typed_data';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/services/bundler.dart';
import 'package:candide_mobile_app/services/explorer.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/gas.dart';
import 'package:candide_mobile_app/models/relay_response.dart';
import 'package:wallet_dart/constants/constants.dart';
import 'package:wallet_dart/contracts/wallet.dart';
import 'package:wallet_dart/wallet/UserOperation.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:wallet_dart/wallet/wallet_helpers.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class GuardianController {

  static List<GnosisTransaction> buildDeploymentTransactions({
    required EthereumAddress walletAddress,
    required EthereumAddress socialModuleAddress,
    required Uint8List initCode,
    required Uint8List salt,
  }) {
    GnosisTransaction deploy = GnosisTransaction(
      id: "social-deploy",
      to: Constants.singletonFactoryAddress,
      value: BigInt.zero,
      data: hexToBytes(EncodeFunctionData.create2Deploy(initCode, salt)),
      type: GnosisTransactionType.execTransactionFromModule,
    );
    GnosisTransaction enable = GnosisTransaction(
      id: "social-enable",
      to: walletAddress,
      value: BigInt.zero,
      data: hexToBytes(EncodeFunctionData.enableModule(socialModuleAddress)),
      type: GnosisTransactionType.execTransactionFromModule,
    );
    //return [deploy];
    return [deploy, enable];
  }

  static List<GnosisTransaction> buildGrantTransactions({
    required WalletInstance instance,
    required bool socialModuleDeployed,
    required bool setup,
    //
    required String guardianAddress,
    required int threshold,
  }){
    //
    List<GnosisTransaction> transactions = [];
    //
    List<GnosisTransaction> deploymentTransactions = [];
    if (!socialModuleDeployed){
      deploymentTransactions = buildDeploymentTransactions(
        walletAddress: instance.walletAddress,
        socialModuleAddress: instance.socialRecovery,
        initCode: WalletHelpers.getSocialRecoveryInitCode(),
        salt: keccak256(Uint8List.fromList("${instance.salt}_socialRecovery".codeUnits)),
      );
    }
    //
    GnosisTransaction grantGuardianTransaction = GnosisTransaction(
      id: "social-grant",
      to: instance.socialRecovery,
      value: BigInt.zero,
      data: hexToBytes(
        setup ? EncodeFunctionData.setupSocialRecoveryModule(EthereumAddress.fromHex(guardianAddress), BigInt.from(threshold))
          : EncodeFunctionData.grantGuardian(EthereumAddress.fromHex(guardianAddress), BigInt.from(threshold))
      ),
      type: GnosisTransactionType.execTransactionFromModule,
    );
    //
    transactions.addAll(deploymentTransactions);
    transactions.add(grantGuardianTransaction);
    //
    return transactions;
  }

  static List<GnosisTransaction> buildRevokeTransactions({
    required WalletInstance instance,
    //
    required int guardianIndex,
    required int threshold,
  }){
    List<GnosisTransaction> transactions = [];
    //
    GnosisTransaction revokeGuardianTransaction = GnosisTransaction(
      id: "social-revoke",
      to: instance.socialRecovery,
      value: BigInt.zero,
      data: hexToBytes(EncodeFunctionData.revokeGuardian(BigInt.from(guardianIndex), BigInt.from(threshold))),
      type: GnosisTransactionType.execTransactionFromModule,
    );
    //
    transactions.add(revokeGuardianTransaction);
    //
    return transactions;
  }

  static Future<Map> buildRecoverOps({
    required EthereumAddress walletAddress,
    required String network,
    required String defaultCurrency,
    required String newOwner,
  }) async {
    int nonce = (await CWallet.customInterface(walletAddress).nonce()).toInt();
    //
    GasEstimate? gasEstimate;
    Map? paymasterStatus;
    await Future.wait([
      Bundler.fetchPaymasterStatus(walletAddress.hex, network).then((value) => paymasterStatus = value),
      Explorer.fetchGasEstimate(network).then((value) => gasEstimate = value),
    ]);
    //
    GasOverrides gasOverrides = GasOverrides.perform(gasEstimate!);
    //
    BigInt feeValue = BigInt.parse(paymasterStatus?["fees"][defaultCurrency] ?? '0');
    BigInt allowance = BigInt.parse(paymasterStatus?["allowances"][defaultCurrency] ?? '0');
    bool shouldApprovePaymaster = allowance < feeValue;
    //
    /*var approvePaymasterOp = shouldApprovePaymaster ? UserOperation.get(
        sender: walletAddress,
        nonce: nonce,
        verificationGas: gasOverrides.verificationGas,
        preVerificationGas: gasOverrides.preVerificationGas,
        maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
        maxFeePerGas: gasOverrides.maxFeePerGas,
        callData: EncodeFunctionData.erc20Approve(
          EthereumAddress.fromHex(CurrencyMetadata.metadata[defaultCurrency]!.address),
          EthereumAddress.fromHex(paymasterStatus?["address"]),
          feeValue
        )
    ) : null;*/
    //
    var grantOp = UserOperation.get(
      sender: walletAddress,
      nonce: nonce + (shouldApprovePaymaster ? 1 : 0),
      verificationGas: gasOverrides.verificationGas,
      preVerificationGas: gasOverrides.preVerificationGas,
      maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
      maxFeePerGas: gasOverrides.maxFeePerGas,
      callData: EncodeFunctionData.transferOwner(EthereumAddress.fromHex(newOwner))
    );
    //
    List<UserOperation> userOperations = [];
    /*if (approvePaymasterOp != null){
      userOperations.add(approvePaymasterOp);
    }*/
    userOperations.add(grantOp);
    return {
      "userOperations": userOperations,
      "fee": {"currency": defaultCurrency, "value": feeValue}
    };
  }

  static Future<Map> buildRevokeOps({
    required WalletInstance instance,
    required String network,
    required bool isDeployed,
    required int nonce,
    required String defaultCurrency,
    //
    required String guardianAddress,
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
    shouldApprovePaymaster = false; // todo check integration
    //
    /*var approvePaymasterOp = shouldApprovePaymaster ? UserOperation.get(
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
    ) : null;*/
    //
    var revokeOp = UserOperation.get(
        sender: instance.walletAddress,
        nonce: nonce + (shouldApprovePaymaster ? 1 : 0),
        verificationGas: gasOverrides.verificationGas,
        preVerificationGas: gasOverrides.preVerificationGas,
        maxPriorityFeePerGas: gasOverrides.maxPriorityFeePerGas,
        maxFeePerGas: gasOverrides.maxFeePerGas,
        //callData: EncodeFunctionData.revokeGuardian(EthereumAddress.fromHex(guardianAddress))
    );
    //
    List<UserOperation> userOperations = [];
    /*if (approvePaymasterOp != null){
      userOperations.add(approvePaymasterOp);
    }*/ // todo check integration
    userOperations.add(revokeOp);
    return {
      "userOperations": userOperations,
      "fee": {"currency": defaultCurrency, "value": feeValue}
    };
  }
}