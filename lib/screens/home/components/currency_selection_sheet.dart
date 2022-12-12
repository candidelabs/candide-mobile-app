import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/screens/home/components/token_logo.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CurrenciesSelectionSheet extends StatelessWidget {
  final List<TokenInfo> currencies;
  final TokenInfo? initialSelection;
  final Function(TokenInfo) onSelected;
  const CurrenciesSelectionSheet({Key? key, required this.currencies, this.initialSelection, required this.onSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 15,),
        Text("Currency", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
        const SizedBox(height: 35,),
        for (TokenInfo currency in currencies)
          Builder(
              builder: (context) {
                CurrencyBalance? currencyBalance = AddressData.currencies.firstWhereOrNull((element) => element.currencyAddress.toLowerCase() == currency.address.toLowerCase());
                if (currencyBalance == null){
                  return const SizedBox.shrink();
                }
                return _CurrencySelectionCard(
                  currencyBalance: currencyBalance,
                  selected: initialSelection != null && currencyBalance.currencyAddress.toLowerCase() == initialSelection?.address.toLowerCase(),
                  onSelected: (){
                    onSelected(currency);
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
    TokenInfo? tokenInfo = TokenInfoStorage.getTokenByAddress(currencyBalance.currencyAddress);
    if (tokenInfo == null){
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
                TokenLogo(
                  token: tokenInfo,
                  size: 40,
                ),
                const SizedBox(width: 7,),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tokenInfo.name, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18)),
                    RichText(
                      text: TextSpan(
                          text: CurrencyUtils.formatCurrency(currencyBalance.balance, tokenInfo, includeSymbol: false),
                          style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13),
                          children: [
                            TextSpan(
                              text: " ${tokenInfo.symbol}",
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            )
                          ]
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}