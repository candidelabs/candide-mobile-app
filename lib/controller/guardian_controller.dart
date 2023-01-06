import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:wallet_dart/contracts/social_module.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class GuardianController {

  static GnosisTransaction buildSetupTransaction({
    required EthereumAddress walletAddress,
    required EthereumAddress socialModuleAddress,
  }) {
    GnosisTransaction enable = GnosisTransaction(
      id: "social-enable",
      to: walletAddress,
      value: BigInt.zero,
      data: hexToBytes(EncodeFunctionData.enableModule(socialModuleAddress)),
      type: GnosisTransactionType.execTransactionFromModule,
    );
    return enable;
  }

  static List<GnosisTransaction> buildGrantTransactions({
    required WalletInstance instance,
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
        walletAddress: instance.walletAddress,
        socialModuleAddress: ISocialModule.address,
      );
      transactions.add(enableModuleTransaction);
    }
    //
    for (EthereumAddress guardian in guardians){
      GnosisTransaction grantGuardianTransaction = GnosisTransaction(
        id: "social-grant",
        to: ISocialModule.address,
        value: BigInt.zero,
        data: hexToBytes(
          EncodeFunctionData.grantGuardian(instance.walletAddress, guardian, BigInt.from(threshold))
        ),
        type: GnosisTransactionType.execTransactionFromModule,
      );
      //
      transactions.add(grantGuardianTransaction);
    }
    //
    return transactions;
  }

  static List<GnosisTransaction> buildRevokeTransactions({
    required WalletInstance instance,
    //
    required EthereumAddress previousGuardian,
    required EthereumAddress guardian,
    required int threshold,
  }){
    List<GnosisTransaction> transactions = [];
    //
    GnosisTransaction revokeGuardianTransaction = GnosisTransaction(
      id: "social-revoke",
      to: ISocialModule.address,
      value: BigInt.zero,
      data: hexToBytes(EncodeFunctionData.revokeGuardian(instance.walletAddress, previousGuardian, guardian, BigInt.from(threshold))),
      type: GnosisTransactionType.execTransactionFromModule,
    );
    //
    transactions.add(revokeGuardianTransaction);
    //
    return transactions;
  }
}