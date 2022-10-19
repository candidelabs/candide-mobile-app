import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class SendController {
  static GnosisTransaction buildTransaction({
    required String sendCurrency,
    required String to,
    required BigInt value,
  }){
    bool erc20Transfer = sendCurrency != Networks.get(SettingsData.network)!.nativeCurrency;
    //
    GnosisTransaction transaction = GnosisTransaction(
      id: "transfer",
      to: !erc20Transfer ? EthereumAddress.fromHex(to) : EthereumAddress.fromHex(CurrencyMetadata.metadata[sendCurrency]!.address),
      value: !erc20Transfer ? value : BigInt.zero,
      data: !erc20Transfer ?
        Constants.nullCodeBytes : hexToBytes(EncodeFunctionData.erc20Transfer(EthereumAddress.fromHex(to), value)),
      type: GnosisTransactionType.execTransactionFromModule,
    );
    return transaction;
  }
}