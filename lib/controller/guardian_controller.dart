import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class GuardianController {

  static GnosisTransaction buildSetupTransaction({
    required EthereumAddress accountAddress,
    required EthereumAddress socialModuleAddress,
  }) {
    GnosisTransaction enable = GnosisTransaction(
      id: "social-enable",
      to: accountAddress,
      value: BigInt.zero,
      data: hexToBytes(EncodeFunctionData.enableModule(socialModuleAddress)),
      type: GnosisTransactionType.execTransactionFromEntrypoint,
      suggestedGasLimit: BigInt.from(50000),
    );
    return enable;
  }

  static List<GnosisTransaction> buildGrantTransactions({
    required Account account,
    required bool socialModuleEnabled,
    //
    required List<EthereumAddress> guardians,
    required int threshold,
  }){
    //
    if (guardians.isEmpty) return [];
    //
    List<GnosisTransaction> transactions = [];
    //
    EthereumAddress socialRecoveryModuleAddress = Networks.getByChainId(account.chainId)!.socialRecoveryModule;
    if (account.socialRecoveryModule != null){
      socialRecoveryModuleAddress = account.socialRecoveryModule!;
    }
    if (!socialModuleEnabled){
      GnosisTransaction enableModuleTransaction = buildSetupTransaction(
        accountAddress: account.address,
        socialModuleAddress: socialRecoveryModuleAddress,
      );
      transactions.add(enableModuleTransaction);
    }
    //
    for (EthereumAddress guardian in guardians){
      GnosisTransaction grantGuardianTransaction = GnosisTransaction(
        id: "social-grant",
        to: socialRecoveryModuleAddress,
        value: BigInt.zero,
        data: hexToBytes(
          EncodeFunctionData.grantGuardian(account.address, guardian, BigInt.from(threshold))
        ),
        type: GnosisTransactionType.execTransactionFromEntrypoint,
        suggestedGasLimit: BigInt.from(100000),
      );
      //
      transactions.add(grantGuardianTransaction);
    }
    //
    return transactions;
  }

  static List<GnosisTransaction> buildRevokeTransactions({
    required Account account,
    //
    required EthereumAddress previousGuardian,
    required EthereumAddress guardian,
    required int threshold,
  }){
    List<GnosisTransaction> transactions = [];
    //
    EthereumAddress socialRecoveryModuleAddress = Networks.getByChainId(account.chainId)!.socialRecoveryModule;
    if (account.socialRecoveryModule != null){
      socialRecoveryModuleAddress = account.socialRecoveryModule!;
    }
    GnosisTransaction revokeGuardianTransaction = GnosisTransaction(
      id: "social-revoke",
      to: socialRecoveryModuleAddress,
      value: BigInt.zero,
      data: hexToBytes(EncodeFunctionData.revokeGuardian(account.address, previousGuardian, guardian, BigInt.from(threshold))),
      type: GnosisTransactionType.execTransactionFromEntrypoint,
      suggestedGasLimit: BigInt.from(100000),
    );
    //
    transactions.add(revokeGuardianTransaction);
    //
    return transactions;
  }
}