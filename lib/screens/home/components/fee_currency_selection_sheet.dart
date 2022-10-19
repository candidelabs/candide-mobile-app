import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/models/fee_currency.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FeeCurrenciesSelectionSheet extends StatelessWidget {
  final List<FeeCurrency> currencies;
  final String? initialSelection;
  final Function(FeeCurrency) onSelected;
  const FeeCurrenciesSelectionSheet({Key? key, required this.currencies, this.initialSelection, required this.onSelected}) : super(key: key);

  void sortByAvailability(){
    currencies.sort((a, b){
      CurrencyBalance? _aBalance = AddressData.currencies.firstWhereOrNull((element) => element.currency == a.currency.symbol);
      CurrencyBalance? _bBalance = AddressData.currencies.firstWhereOrNull((element) => element.currency == b.currency.symbol);
      //
      BigInt aBalance = _aBalance?.balance ?? BigInt.zero;
      BigInt bBalance = _bBalance?.balance ?? BigInt.zero;
      //
      BigInt aPriority = _aBalance?.currentBalanceInQuote ?? BigInt.zero;
      BigInt bPriority = _bBalance?.currentBalanceInQuote ?? BigInt.zero;
      //
      if (aBalance < a.fee && bBalance < b.fee){
        return bPriority.compareTo(aPriority);
      }
      if (aBalance < a.fee){
        return 1;
      }
      if (bBalance < b.fee){
        return -1;
      }
      //
      return bPriority.compareTo(aPriority);
    });
  }

  @override
  Widget build(BuildContext context) {
    sortByAvailability();
    return Column(
      children: [
        const SizedBox(height: 15,),
        Text("Network fee", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
        const SizedBox(height: 20,),
        Container(
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.only(left: 15),
          child: Text("Pay with", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 15),)
        ),
        for (FeeCurrency feeCurrency in currencies)
          Builder(
              builder: (context) {
                CurrencyBalance? currencyBalance = AddressData.currencies.firstWhereOrNull((element) => element.currency == feeCurrency.currency.symbol);
                if (currencyBalance == null){
                  return const SizedBox.shrink();
                }
                return _FeeCurrencySelectionCard(
                  feeCurrency: feeCurrency,
                  currencyBalance: currencyBalance,
                  selected: initialSelection != null && currencyBalance.currency == initialSelection,
                  onSelected: (){
                    onSelected(feeCurrency);
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


class _FeeCurrencySelectionCard extends StatelessWidget {
  final FeeCurrency feeCurrency;
  final CurrencyBalance currencyBalance;
  final bool selected;
  final VoidCallback onSelected;
  const _FeeCurrencySelectionCard({Key? key, required this.feeCurrency, required this.currencyBalance, required this.selected, required this.onSelected}) : super(key: key);

  static const ColorFilter _greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    bool disabled = currencyBalance.balance < feeCurrency.fee;
    CurrencyMetadata? metadata = CurrencyMetadata.metadata[feeCurrency.currency.symbol];
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
          onTap: !disabled ? onSelected : null,
          child: ColorFiltered(
            colorFilter: disabled ? _greyscale : const ColorFilter.mode(Colors.transparent, BlendMode.saturation),
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
                      Text(metadata.name, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18, color: disabled ? Colors.grey[700] : Colors.white)),
                      !disabled ? RichText(
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
                      ) : const SizedBox.shrink(),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 100,
                    child: disabled ? Text("Insufficient Balance", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700]),)
                        : Column(
                      children: [
                        Text("Fee", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 14, color: Colors.white)),
                        Text(CurrencyUtils.formatCurrency(feeCurrency.fee, feeCurrency.currency.symbol), style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 11)),
                      ],
                    )
                  ),
                  const SizedBox(width: 5,)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}