import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/screens/home/components/token_logo.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CurrencyBalanceCard extends StatelessWidget {
  final TokenInfo token;
  final bool balanceVisible;
  const CurrencyBalanceCard({Key? key, required this.token, required this.balanceVisible}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    CurrencyBalance? currencyBalance = AddressData.currencies.firstWhereOrNull((element) => element.currencyAddress.toLowerCase() == token.address.toLowerCase());
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
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 5,),
              TokenLogo(
                token: token,
                size: 40,
              ),
              const SizedBox(width: 7,),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Text(Utils.truncate(token.name, leadingDigits: 30, trailingDigits: 0), style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18))
                    ),
                    RichText(
                      text: TextSpan(
                          text: balanceVisible ? CurrencyUtils.formatCurrency(currencyBalance?.balance ?? BigInt.zero, token, includeSymbol: false, formatSmallDecimals: true) : "••••••",
                          style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13),
                          children: [
                            TextSpan(
                              text: " ${token.symbol}",
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            )
                          ]
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15,),
              RichText(
                text: TextSpan(
                  text: balanceVisible ? CurrencyUtils.formatCurrency(currencyBalance?.currentBalanceInQuote ?? BigInt.zero, TokenInfoStorage.getTokenBySymbol(currencyBalance?.quoteCurrency ?? "USDT")!, includeSymbol: (currencyBalance?.quoteCurrency ?? "USDT") == "USDT") : "••••••",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13),
                  children: [
                    (currencyBalance?.quoteCurrency ?? "USDT") != "USDT" ? TextSpan(
                      text: token.symbol,
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