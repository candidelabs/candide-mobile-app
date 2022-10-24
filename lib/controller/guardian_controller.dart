import 'dart:typed_data';

import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:wallet_dart/constants/constants.dart';
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
}