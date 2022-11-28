import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/controller/transaction_confirm_controller.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/screens/components/summary_table.dart';
import 'package:candide_mobile_app/screens/components/token_fee_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransactionReviewSheet extends StatefulWidget {
  final String? modalId;
  final Widget leading;
  final String? currency;
  final BigInt? value;
  final Batch batch;
  final TransactionActivity transactionActivity;
  final Map<String, String> tableEntriesData;
  final VoidCallback? onBack;
  const TransactionReviewSheet({Key? key, this.modalId, required this.leading, required this.batch, required this.transactionActivity, required this.tableEntriesData, this.onBack, this.currency, this.value}) : super(key: key);

  @override
  State<TransactionReviewSheet> createState() => _TransactionReviewSheetState();
}

class _TransactionReviewSheetState extends State<TransactionReviewSheet> {
  String errorMessage = "";
  final _errors = {
    "balance": "Insufficient balance",
    "fee": "Insufficient balance to cover network fee",
  };
  //
  FeeCurrency? selectDefaultFeeCurrency(List<FeeCurrency> feeCurrencies){
    FeeCurrency? result;
    BigInt maxQuoteBalance = BigInt.from(-1);
    for (FeeCurrency feeCurrency in feeCurrencies){
      CurrencyBalance? currencyBalance = AddressData.currencies.firstWhereOrNull((element) => element.currency == feeCurrency.currency.symbol);
      if (currencyBalance == null) continue;
      if (feeCurrency.fee > currencyBalance.balance) continue;
      if (feeCurrency.currency.symbol == widget.currency){
        if (feeCurrency.fee + (widget.value ?? BigInt.zero) > currencyBalance.balance) continue;
      }
      if (currencyBalance.currentBalanceInQuote > maxQuoteBalance){
        result = feeCurrency;
        maxQuoteBalance = currencyBalance.currentBalanceInQuote;
      }
    }
    return result;
  }

  void validateFeeBalance(){
    errorMessage = "";
    BigInt fee = widget.batch.getFee();
    if (widget.currency != null){
      if (widget.currency == widget.batch.feeCurrency!.currency.symbol){
        if ((widget.value ?? BigInt.zero) + fee > AddressData.getCurrencyBalance(widget.currency!)){
          errorMessage = _errors["fee"]!;
        }
      }else{
        if ((widget.value ?? BigInt.zero) > AddressData.getCurrencyBalance(widget.currency!)){
          errorMessage = _errors["balance"]!;
        }else{
          if (AddressData.getCurrencyBalance(widget.batch.feeCurrency!.currency.symbol) < fee){
            errorMessage = _errors["fee"]!;
          }
        }
      }
    }else{
      if (AddressData.getCurrencyBalance(widget.batch.feeCurrency!.currency.symbol) < fee){
        errorMessage = _errors["fee"]!;
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    FeeCurrency? feeCurrency = selectDefaultFeeCurrency(widget.batch.feeCurrencies);
    if (feeCurrency != null){
      widget.batch.changeFeeCurrency(feeCurrency);
      validateFeeBalance();
    }else{
      errorMessage = _errors["fee"]!;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints){
        return SingleChildScrollView(
          controller: Get.find<ScrollController>(tag: widget.modalId ?? "transaction_review_modal"),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 10,),
                  Row(
                    children: [
                      SizedBox(width: widget.onBack != null ? 5 : 0,),
                      widget.onBack != null ? IconButton(
                        onPressed: (){
                           widget.onBack!();
                        },
                        icon: const Icon(Icons.arrow_back),
                      ) : const SizedBox.shrink(),
                      Spacer(flex: widget.onBack != null ? 2 : 1,),
                      Text("Review", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                      Spacer(flex: widget.onBack != null ? 3 : 1,),
                    ],
                  ),
                  const SizedBox(height: 25,),
                  widget.leading,
                  const SizedBox(height: 15,),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: Get.width * 0.03),
                    child: SummaryTable(
                      entries: [
                        for (MapEntry entry in widget.tableEntriesData.entries)
                          SummaryTableEntry(
                            title: entry.key,
                            titleStyle: null,
                            value: entry.value,
                            valueStyle: entry.key == "Network" ? TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Networks.get(SettingsData.network)!.color) : null,
                          )
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: Get.width * 0.03),
                    child: TokenFeeSelector(
                      batch: widget.batch,
                      onFeeCurrencyChange: (FeeCurrency feeCurrency){
                        validateFeeBalance();
                      },
                    ),
                  ),
                  const Spacer(),
                  errorMessage.isNotEmpty ? Container(
                    margin: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    width: double.maxFinite,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: Colors.red,
                        )
                    ),
                    child: Center(
                        child: Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red),)
                    ),
                  ) : const SizedBox.shrink(),
                  SizedBox(height: errorMessage.isNotEmpty ? 5 : 0,),
                  ElevatedButton(
                    onPressed: errorMessage.isEmpty ? (){
                      TransactionConfirmController.onPressConfirm(widget.batch, widget.transactionActivity);
                    } : null,
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all(Size(Get.width * 0.9, 40)),
                      shape: MaterialStateProperty.all(const BeveledRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(7),
                        ),
                      )),
                    ),
                    child: Text("Confirm", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),),
                  ),
                  const SizedBox(height: 25,),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
