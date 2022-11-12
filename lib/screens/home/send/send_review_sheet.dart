import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/screens/components/summary_table.dart';
import 'package:candide_mobile_app/screens/components/token_fee_selector.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SendReviewSheet extends StatefulWidget {
  final String from;
  final String to;
  final BigInt value;
  final String currency;
  final Batch batch;
  final VoidCallback onPressBack;
  final VoidCallback onConfirm;
  const SendReviewSheet({Key? key, required this.onPressBack, required this.from, required this.to, required this.value, required this.currency, required this.batch, required this.onConfirm}) : super(key: key);

  @override
  State<SendReviewSheet> createState() => _SendReviewSheetState();
}

class _SendReviewSheetState extends State<SendReviewSheet> {
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
        if (feeCurrency.fee + widget.value > currencyBalance.balance) continue;
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
    if (widget.currency == widget.batch.feeCurrency!.currency.symbol){
      if (widget.value + fee > AddressData.getCurrencyBalance(widget.currency)){
        errorMessage = _errors["fee"]!;
      }
    }else{
      if (widget.value > AddressData.getCurrencyBalance(widget.currency)){
        errorMessage = _errors["balance"]!;
      }else{
        if (AddressData.getCurrencyBalance(widget.batch.feeCurrency!.currency.symbol) < fee){
          errorMessage = _errors["fee"]!;
        }
      }
    }
    setState(() {});
  }

  //
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

  //
  @override
  Widget build(BuildContext context) {
    String sendingAmountText = CurrencyUtils.formatCurrency(widget.value, widget.currency, includeSymbol: false);
    if (sendingAmountText == "0.0" && widget.value > BigInt.zero){
      sendingAmountText = "< 0.000001 ${widget.currency}";
    }
    return LayoutBuilder(
      builder: (context, constraints){
        return SingleChildScrollView(
          controller: Get.find<ScrollController>(tag: "send_modal"),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 10,),
                  Row(
                    children: [
                      const SizedBox(width: 5,),
                      IconButton(
                        onPressed: (){
                          widget.onPressBack();
                        },
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Spacer(flex: 2,),
                      Text("Review", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                      const Spacer(flex: 3,),
                    ],
                  ),
                  const SizedBox(height: 25,),
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        width: 95,
                        height: 95,
                        decoration: BoxDecoration(
                          color: Get.theme.cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: CurrencyMetadata.metadata[widget.currency]!.logo,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Get.theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(Icons.arrow_upward_rounded, color: Get.theme.colorScheme.onPrimary, size: 18,)
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25,),
                  Text(
                    CurrencyUtils.formatCurrency(widget.value, widget.currency, formatSmallDecimals: true),
                    style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 28),
                  ),
                  const SizedBox(height: 15,),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: Get.width * 0.03),
                    child: SummaryTable(
                      entries: [
                        SummaryTableEntry(
                          title: "From",
                          value: widget.from,
                        ),
                        SummaryTableEntry(
                          title: "To",
                          value: widget.to,
                        ),
                        SummaryTableEntry(
                          title: "Network",
                          titleStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Networks.get(SettingsData.network)!.color),
                          valueStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Networks.get(SettingsData.network)!.color),
                          value: SettingsData.network,
                        ),
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
                      widget.onConfirm.call();
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

