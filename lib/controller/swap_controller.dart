import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/swap.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/models/gnosis_transaction.dart';
import 'package:candide_mobile_app/utils/constants.dart';
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
    bool shouldApproveRouter = baseCurrency.symbol != Networks.selected().nativeCurrency && baseCurrency.address != Constants.addressZeroHex;
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
    ) : null;
    //
    GnosisTransaction swapTransaction = GnosisTransaction(
      id: "swap",
      to: EthereumAddress.fromHex(optimalQuote.transaction["to"].toString()),
      value: BigInt.parse(optimalQuote.transaction["value"]),
      data: hexToBytes(optimalQuote.transaction["data"]),
      type: GnosisTransactionType.execTransactionFromEntrypoint,
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