import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/controller/transaction_confirm_controller.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/paymaster/fee_token.dart';
import 'package:candide_mobile_app/screens/components/summary_table.dart';
import 'package:candide_mobile_app/screens/home/components/transaction/token_fee_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:info_popup/info_popup.dart';

class TransactionReviewSheet extends StatefulWidget {
  final String? modalId;
  final Widget leading;
  final TokenInfo? currency;
  final BigInt? value;
  final Batch batch;
  final TransactionActivity transactionActivity;
  final Map<String, String> tableEntriesData;
  final VoidCallback? onBack;
  final bool showRejectButton;
  final List<List<String>?> confirmCheckboxes;
  const TransactionReviewSheet({
    Key? key,
    this.modalId,
    required this.leading,
    required this.batch,
    required this.transactionActivity,
    required this.tableEntriesData,
    this.onBack,
    this.currency,
    this.value,
    this.showRejectButton = false,
    this.confirmCheckboxes = const []
  }) : super(key: key);

  @override
  State<TransactionReviewSheet> createState() => _TransactionReviewSheetState();
}

class _TransactionReviewSheetState extends State<TransactionReviewSheet> {
  String errorMessage = "";
  final _errors = {
    "balance": "Insufficient balance",
    "fee": "Insufficient balance to cover network fee",
  };
  List<bool> confirmedCheckBoxes = [];
  //
  FeeToken? selectDefaultFeeCurrency(List<FeeToken> feeCurrencies){
    FeeToken? result;
    double maxQuoteBalance = -1;
    for (FeeToken feeCurrency in feeCurrencies){
      CurrencyBalance? currencyBalance = PersistentData.currencies.firstWhereOrNull((element) => element.currencyAddress.toLowerCase() == feeCurrency.token.address.toLowerCase());
      if (currencyBalance == null) continue;
      if (feeCurrency.fee > currencyBalance.balance) continue;
      if (feeCurrency.token.address.toLowerCase() == widget.currency?.address.toLowerCase()){
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
      if (widget.currency?.address.toLowerCase() == widget.batch.selectedFeeToken!.token.address.toLowerCase()){
        if ((widget.value ?? BigInt.zero) + fee > PersistentData.getCurrencyBalance(widget.currency!.address.toLowerCase())){
          errorMessage = _errors["fee"]!;
        }
      }else{
        if ((widget.value ?? BigInt.zero) > PersistentData.getCurrencyBalance(widget.currency!.address.toLowerCase())){
          errorMessage = _errors["balance"]!;
        }else{
          if (PersistentData.getCurrencyBalance(widget.batch.selectedFeeToken!.token.address.toLowerCase()) < fee){
            errorMessage = _errors["fee"]!;
          }
        }
      }
    }else{
      if (PersistentData.getCurrencyBalance(widget.batch.selectedFeeToken!.token.address.toLowerCase()) < fee){
        errorMessage = _errors["fee"]!;
      }
    }
    setState(() {});
  }

  bool _allCheckboxesConfirmed(){
    for (bool confirmed in confirmedCheckBoxes) {
      if (!confirmed) return false;
    }
    return true;
  }

  @override
  void initState() {
    FeeToken? feeCurrency = selectDefaultFeeCurrency(widget.batch.paymasterResponse.tokens);
    if (feeCurrency != null){
      widget.batch.setSelectedFeeToken(feeCurrency);
      validateFeeBalance();
    }else{
      errorMessage = _errors["fee"]!;
    }
    confirmedCheckBoxes = List.generate(widget.confirmCheckboxes.length, (index) => widget.confirmCheckboxes[index] == null || widget.confirmCheckboxes[index]!.isEmpty ? true : false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool confirmButtonEnabled =  _allCheckboxesConfirmed() && errorMessage.isEmpty;
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
                            value: entry.key == "Network" ? Networks.getByChainId(int.parse(entry.value))!.name : entry.value,
                            valueStyle: entry.key == "Network" ? TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Networks.selected().color) : null,
                          )
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: Get.width * 0.03),
                    child: TokenFeeSelector(
                      batch: widget.batch,
                      onFeeCurrencyChange: (FeeToken feeCurrency){
                        validateFeeBalance();
                      },
                    ),
                  ),
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        for (int i=0; i < widget.confirmCheckboxes.length; i++)
                          widget.confirmCheckboxes[i] != null && widget.confirmCheckboxes[i]!.isNotEmpty ? FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: Get.width,
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: CheckboxListTile(
                                      onChanged: (val) => setState(() => confirmedCheckBoxes[i] = val ?? false),
                                      value: confirmedCheckBoxes[i],
                                      activeColor: Colors.blue,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        widget.confirmCheckboxes[i]![0],
                                        textDirection: TextDirection.ltr,
                                        style: const TextStyle(fontSize: 13, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                widget.confirmCheckboxes[i]!.length > 1 ? InfoPopupWidget(
                                  arrowTheme: InfoPopupArrowTheme(
                                    color: Colors.black.withOpacity(0.8),
                                  ),
                                  customContent: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                                    decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(8)
                                    ),
                                    child: Text(widget.confirmCheckboxes[i]![1]),
                                  ),
                                  child: const Icon(
                                    Icons.info,
                                  ),
                                ) : const SizedBox.shrink(),
                              ],
                            ),
                          ) : const SizedBox.shrink(),
                      ],
                    ),
                  ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.showRejectButton ? ElevatedButton(
                        onPressed: () async {
                          Get.back();
                        },
                        style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(Size(Get.width * 0.30, 40)),
                            backgroundColor: MaterialStateProperty.all(Colors.transparent),
                            elevation: MaterialStateProperty.all(0),
                            shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                                side: BorderSide(color: Get.theme.colorScheme.primary)
                            ))
                        ),
                        child: Text("Reject", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.primary),),
                      ) : const SizedBox.shrink(),
                      SizedBox(width: widget.showRejectButton ? 15 : 0,),
                      ElevatedButton(
                        onPressed: confirmButtonEnabled ? (){
                          TransactionConfirmController.onPressConfirm(widget.batch, widget.transactionActivity);
                        } : null,
                        style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(Size(Get.width * 0.30, 40)),
                            elevation: MaterialStateProperty.all(0),
                            shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                                side: BorderSide(color: confirmButtonEnabled ? Get.theme.colorScheme.primary : Colors.grey.withOpacity(0.25))
                            ))
                        ),
                        child: Text("Confirm", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
                      ),
                    ],
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
