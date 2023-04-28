import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/swap.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:wallet_dart/wallet/encode_function_data.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class SwapController {
  static List<GnosisTransaction> buildTransactions({
    required TokenInfo baseCurrency,
    required BigInt baseCurrencyValue,
    //
    required OptimalQuote optimalQuote,
  }){
    List<GnosisTransaction> transactions = [];
    bool shouldApproveRouter = baseCurrency.address.toLowerCase() != Networks.selected().nativeCurrencyAddress.hex.toLowerCase();
    //
    GnosisTransaction? approveRouterTransaction = shouldApproveRouter ? GnosisTransaction(
      id: "approve-router",
      to: EthereumAddress.fromHex(baseCurrency.address),
      value: BigInt.zero,
      data: hexToBytes(EncodeFunctionData.erc20Approve(
        EthereumAddress.fromHex(optimalQuote.transaction["to"].toString()),
        baseCurrencyValue
      )),
      type: GnosisTransactionType.execTransactionFromEntrypoint,
      suggestedGasLimit: BigInt.from(50000),
    ) : null;
    //
    GnosisTransaction swapTransaction = GnosisTransaction(
      id: "swap",
      to: EthereumAddress.fromHex(optimalQuote.transaction["to"].toString()),
      value: BigInt.parse(optimalQuote.transaction["value"]),
      data: hexToBytes(optimalQuote.transaction["data"]),
      type: GnosisTransactionType.execTransactionFromEntrypoint,
      suggestedGasLimit: BigInt.from(150000),
    );
    //
    if (approveRouterTransaction != null){
      transactions.add(approveRouterTransaction);
    }
    transactions.add(swapTransaction);
    //
    return transactions;
  }
}