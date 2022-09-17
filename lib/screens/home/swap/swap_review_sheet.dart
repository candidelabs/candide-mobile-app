import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/swap.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/screens/components/summary_table.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class SwapReviewSheet extends StatefulWidget {
  final String baseCurrency;
  final BigInt baseValue;
  final String quoteCurrency;
  final OptimalQuote quote;
  final Map paymasterStatus;
  //
  final VoidCallback onPressBack;
  final VoidCallback onConfirm;
  const SwapReviewSheet({Key? key, required this.baseCurrency, required this.baseValue, required this.quoteCurrency, required this.quote, required this.paymasterStatus, required this.onPressBack, required this.onConfirm}) : super(key: key);

  @override
  State<SwapReviewSheet> createState() => _SwapReviewSheetState();
}

class _SwapReviewSheetState extends State<SwapReviewSheet> {
  String errorMessage = "";
  final _errors = {
    "balance": "Insufficient balance",
    "fee": "Insufficient balance to cover network fee",
  };
  //
  @override
  void initState() {
    if (widget.baseCurrency == widget.paymasterStatus["fees"]["currency"]){
      if (widget.baseValue + widget.paymasterStatus["fees"]["value"] > AddressData.getCurrencyBalance(widget.baseCurrency)){
        errorMessage = _errors["fees"]!;
      }
    }else{
      if (widget.baseValue > AddressData.getCurrencyBalance(widget.baseCurrency)){
        errorMessage = _errors["balance"]!;
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints){
        return SingleChildScrollView(
          controller: Get.find<ScrollController>(tag: "swap_modal"),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2,),
                      _CurrencySwapIcon(
                        currency: widget.baseCurrency,
                        value: CurrencyUtils.formatCurrency(widget.baseValue, widget.baseCurrency, includeSymbol: false),
                        icon: Icon(Icons.arrow_downward_rounded, color: Get.theme.colorScheme.onPrimary, size: 18,),
                      ),
                      const Spacer(),
                      Container(
                        margin: const EdgeInsets.only(bottom: 35),
                        child: Card(
                          shape: ContinuousRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: const Icon(FontAwesomeIcons.leftRight)
                          )
                        ),
                      ),
                      const Spacer(),
                      _CurrencySwapIcon(
                        currency: widget.quoteCurrency,
                        value: CurrencyUtils.formatCurrency(widget.quote.amount, widget.quoteCurrency, includeSymbol: false),
                        icon: Icon(Icons.arrow_upward_rounded, color: Get.theme.colorScheme.onPrimary, size: 18,),
                      ),
                      const Spacer(flex: 2,),
                    ],
                  ),
                  const SizedBox(height: 15,),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    child: SummaryTable(entries: [
                      SummaryTableEntry(title: "Rate", value: CurrencyUtils.formatRate(widget.baseCurrency, widget.quoteCurrency, widget.quote.rate)),
                      SummaryTableEntry(title: "Fee", value: CurrencyUtils.formatCurrency(BigInt.parse(widget.paymasterStatus["fees"][SettingsData.quoteCurrency] ?? '0'), SettingsData.quoteCurrency)),
                    ]),
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
                    child: Text("Swap", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),),
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

class _CurrencySwapIcon extends StatelessWidget {
  final String currency;
  final String value;
  final Icon icon;
  const _CurrencySwapIcon({Key? key, required this.currency, required this.value, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              child: CurrencyMetadata.metadata[currency]!.logo,
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
                    child: icon,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25,),
        RichText(
          text: TextSpan(
            text: "$value ",
            style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),
            children: [
              TextSpan(
                text: currency,
                style: const TextStyle(fontSize: 13, color: Colors.grey)
              )
            ]
          ),
        ),
      ],
    );
  }
}

