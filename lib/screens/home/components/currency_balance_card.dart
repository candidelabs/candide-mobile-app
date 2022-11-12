import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:flutter/material.dart';

class CurrencyBalanceCard extends StatelessWidget {
  final CurrencyBalance currencyBalance;
  final bool balanceVisible;
  const CurrencyBalanceCard({Key? key, required this.currencyBalance, required this.balanceVisible}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    CurrencyMetadata? metadata = CurrencyMetadata.metadata[currencyBalance.currency];
    if (metadata == null){
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10)
            )
        ),
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
                        text: balanceVisible ? CurrencyUtils.formatCurrency(currencyBalance.balance, metadata.symbol, includeSymbol: false, formatSmallDecimals: true) : "••••••",
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
                  text: balanceVisible ? CurrencyUtils.formatCurrency(currencyBalance.currentBalanceInQuote, currencyBalance.quoteCurrency, includeSymbol: currencyBalance.quoteCurrency == "USDT") : "••••••",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13),
                  children: [
                    currencyBalance.quoteCurrency != "USDT" ? TextSpan(
                      text: CurrencyMetadata.metadata[currencyBalance.quoteCurrency]!.displaySymbol,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ) : const WidgetSpan(child: SizedBox.shrink())
                  ]
                ),
              ),
              const SizedBox(width: 7,),
            ],
          ),
        ),
      ),
    );
  }
}