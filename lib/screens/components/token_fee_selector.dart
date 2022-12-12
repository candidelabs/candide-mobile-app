import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/models/batch.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/screens/home/components/fee_currency_selection_sheet.dart';
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
      builder: (context) => SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: FeeCurrenciesSelectionSheet(
          currencies: widget.batch.feeCurrencies,
          initialSelection: widget.batch.feeCurrency?.token,
          onSelected: (feeCurrency){
            setState(() {
              widget.batch.changeFeeCurrency(feeCurrency);
            });
            widget.onFeeCurrencyChange?.call(feeCurrency);
          },
        ),
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
      child: InkWell(
        onTap: (){
          showFeeCurrencySelectionModal();
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
                      child: Text("pay transaction fees with one of the supported tokens", style: TextStyle(fontFamily: AppThemes.fonts.gilroy, color: Colors.grey, fontSize: 11),)
                  ),
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  Text(widget.batch.feeCurrency != null ? CurrencyUtils.formatCurrency(widget.batch.feeCurrency!.fee, widget.batch.feeCurrency!.token) : "-", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.white)),
                  Text(widget.batch.feeCurrency != null ? CurrencyUtils.formatCurrency(CurrencyUtils.convertToQuote(widget.batch.feeCurrency!.token.address.toLowerCase(), SettingsData.quoteCurrency, widget.batch.feeCurrency!.fee), TokenInfoStorage.getTokenBySymbol(SettingsData.quoteCurrency)!) : "-", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.grey, fontSize: 12)),
                ],
              ),
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