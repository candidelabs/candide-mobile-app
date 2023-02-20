import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:wallet_dart/wallet/account.dart';
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
    if (!socialModuleEnabled){
      GnosisTransaction enableModuleTransaction = buildSetupTransaction(
        accountAddress: account.address,
        socialModuleAddress: Networks.getByChainId(account.chainId)!.socialRecoveryModule,
      );
      transactions.add(enableModuleTransaction);
    }
    //
    for (EthereumAddress guardian in guardians){
      GnosisTransaction grantGuardianTransaction = GnosisTransaction(
        id: "social-grant",
        to: Networks.getByChainId(account.chainId)!.socialRecoveryModule,
        value: BigInt.zero,
        data: hexToBytes(
          EncodeFunctionData.grantGuardian(account.address, guardian, BigInt.from(threshold))
        ),
        type: GnosisTransactionType.execTransactionFromEntrypoint,
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
    GnosisTransaction revokeGuardianTransaction = GnosisTransaction(
      id: "social-revoke",
      to: Networks.getByChainId(account.chainId)!.socialRecoveryModule,
      value: BigInt.zero,
      data: hexToBytes(EncodeFunctionData.revokeGuardian(account.address, previousGuardian, guardian, BigInt.from(threshold))),
      type: GnosisTransactionType.execTransactionFromEntrypoint,
    );
    //
    transactions.add(revokeGuardianTransaction);
    //
    return transactions;
  }
}