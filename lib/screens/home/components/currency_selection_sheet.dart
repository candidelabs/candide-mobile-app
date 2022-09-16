import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CurrenciesSelectionSheet extends StatelessWidget {
  final List<String> currencies;
  final String? initialSelection;
  final Function(String) onSelected;
  const CurrenciesSelectionSheet({Key? key, required this.currencies, this.initialSelection, required this.onSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 15,),
        Text("Currency", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
        const SizedBox(height: 35,),
        for (String currency in currencies)
          Builder(
              builder: (context) {
                CurrencyBalance? currencyBalance = AddressData.currencies.firstWhereOrNull((element) => element.currency == currency);
                if (currencyBalance == null){
                  return const SizedBox.shrink();
                }
                return _CurrencySelectionCard(
                  currencyBalance: currencyBalance,
                  selected: initialSelection != null && currencyBalance.currency == initialSelection,
                  onSelected: (){
                    onSelected(currencyBalance.currency);
                    Get.back();
                  },
                );
              }
          ),
        const SizedBox(height: 25,),
      ],
    );
  }
}


class _CurrencySelectionCard extends StatelessWidget {
  final CurrencyBalance currencyBalance;
  final bool selected;
  final VoidCallback onSelected;
  const _CurrencySelectionCard({Key? key, required this.currencyBalance, required this.selected, required this.onSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    CurrencyMetadata? metadata = CurrencyMetadata.metadata[currencyBalance.currency];
    if (metadata == null){
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        elevation: 0,
        color: selected ? null : Colors.transparent,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
        child: InkWell(
          onTap: onSelected,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const SizedBox(width: 5,),
                SizedBox(
                    height: 40,
                    width: 40,
                    child: metadata.logo
                ),
                const SizedBox(width: 7,),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(metadata.name, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18)),
                    RichText(
                      text: TextSpan(
                          text: CurrencyUtils.formatCurrency(currencyBalance.balance, metadata.symbol, includeSymbol: false),
                          style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13),
                          children: [
                            TextSpan(
                              text: " ${metadata.symbol}",
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            )
                          ]
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                RichText(
                  text: TextSpan(
                      text: CurrencyUtils.formatCurrency(currencyBalance.currentBalanceInQuote, currencyBalance.quoteCurrency, includeSymbol: false),
                      style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13),
                      children: [
                        TextSpan(
                          text: " ${currencyBalance.quoteCurrency}",
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        )
                      ]
                  ),
                ),
                const SizedBox(width: 7,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}