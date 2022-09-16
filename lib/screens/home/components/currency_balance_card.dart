import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:flutter/material.dart';

class CurrencyBalanceCard extends StatelessWidget {
  final CurrencyBalance currencyBalance;
  const CurrencyBalanceCard({Key? key, required this.currencyBalance}) : super(key: key);

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
    );
  }
}