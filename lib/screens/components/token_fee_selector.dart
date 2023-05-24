import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/paymaster/fee_token.dart';
import 'package:candide_mobile_app/screens/home/components/transaction/fee_currency_selection_sheet.dart';
import 'package:candide_mobile_app/screens/home/components/transaction/gas_back_sheet.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class TokenFeeSelector extends StatefulWidget {
  final Batch batch;
  final Function(FeeToken)? onFeeCurrencyChange;
  const TokenFeeSelector({Key? key, required this.batch, this.onFeeCurrencyChange}) : super(key: key);

  @override
  State<TokenFeeSelector> createState() => _TokenFeeSelectorState();
}

class _TokenFeeSelectorState extends State<TokenFeeSelector> {

  showFeeCurrencySelectionModal(){
    showBarModalBottomSheet(
      context: context,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) => SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: FeeCurrenciesSelectionSheet(
          currencies: widget.batch.paymasterResponse.tokens,
          initialSelection: widget.batch.selectedFeeToken?.token,
          onSelected: (feeCurrency){
            setState(() {
              widget.batch.setSelectedFeeToken(feeCurrency);
            });
            widget.onFeeCurrencyChange?.call(feeCurrency);
          },
        ),
      ),
    );
  }

  showGasBackSheet(){
    showBarModalBottomSheet(
      context: context,
      backgroundColor: Get.theme.canvasColor,
      builder: (context) => SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: const GasBackSheet(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 15,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Colors.grey.withOpacity(0.25),
          width: 0.75,
        ),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: InkWell(
        onTap: (){
          if (widget.batch.gasBack?.gasBackApplied ?? false){
            showGasBackSheet();
          }else{
            showFeeCurrencySelectionModal();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Row(
            children: [
              const SizedBox(width: 5,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Transaction fee", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.grey),),
                  SizedBox(
                      width: Get.width*0.5,
                      child: Text("choose preferred token for transaction fees", style: TextStyle(fontFamily: AppThemes.fonts.gilroy, color: Colors.grey, fontSize: 11),)
                  ),
                ],
              ),
              const Spacer(),
              !widget.batch.gasBack!.gasBackApplied ? _TokenFeeDisplay(batch: widget.batch,) : const _FreeCardIndicator(),
              const SizedBox(width: 5,),
              const Icon(PhosphorIcons.caretRightBold, size: 15, color: Colors.white,),
              const SizedBox(width: 5,),
            ],
          ),
        ),
      ),
    );
  }
}

class _TokenFeeDisplay extends StatelessWidget {
  final Batch batch;
  const _TokenFeeDisplay({Key? key, required this.batch}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(batch.selectedFeeToken != null ? CurrencyUtils.formatCurrency(batch.selectedFeeToken!.fee, batch.selectedFeeToken!.token, formatSmallDecimals: true) : "-", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.white)),
        Text(batch.selectedFeeToken != null ? "\$${CurrencyUtils.convertToQuote(batch.selectedFeeToken!.token.address.toLowerCase(), PersistentData.accountBalance.quoteCurrency, batch.selectedFeeToken!.fee).toPrecision(3)}" : "-", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _FreeCardIndicator extends StatelessWidget {
  const _FreeCardIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.green.withOpacity(0.2),
      color: Colors.green.withOpacity(0.2),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(
              color: Colors.green,
              width: 1.2
          )
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(PhosphorIcons.lightningBold, size: 15,),
            const SizedBox(width: 5,),
            Text("FREE", textAlign: TextAlign.center, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
          ],
        ),
      ),
    );
  }
}
