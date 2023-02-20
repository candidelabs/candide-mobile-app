import 'package:blockies/blockies.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/services/transaction_decoder.dart';
import 'package:candide_mobile_app/utils/currency.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';

class WCApproveComponent extends StatelessWidget {
  final HexTransactionDetails transactionDetails;
  final TokenInfo token;
  final EdgeInsets margin;
  final double? elevation;

  const WCApproveComponent({
    Key? key,
    required this.transactionDetails,
    required this.token,
    this.margin = const EdgeInsets.symmetric(horizontal: 10),
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String value = transactionDetails.parameterValues[1].toString();
    if ((transactionDetails.parameterValues[1] as BigInt) == BigInt.parse("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", radix: 16)){
      value = "∞";
    }else{
      value = CurrencyUtils.commify(CurrencyUtils.formatUnits(transactionDetails.parameterValues[1], token.decimals));
    }
    return Container(
      margin: margin,
      child: Card(
        elevation: elevation ?? Get.theme.cardTheme.elevation,
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: RichText(
                  text: TextSpan(
                    text: "By approving this transaction you are giving the following address access to spend ",
                    style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 15),
                    children: [
                      TextSpan(
                        text: value,
                        style: const TextStyle(fontSize: 17, color: Colors.orange),
                      ),
                      const TextSpan(
                        text: " of your ",
                      ),
                      TextSpan(
                        text: token.symbol,
                        style: const TextStyle(fontSize: 16, color: Colors.orange),
                      ),
                    ]
                  ),
                )
              ),
              const SizedBox(height: 5,),
              Row(
                children: [
                  Text("Address: ", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13)),
                  InkWell(
                    onTap: () async {
                      String url = "${Networks.selected().explorerUrl}/address/${(transactionDetails.parameterValues[0] as EthereumAddress).hex}";
                      Utils.launchUri(url, mode: LaunchMode.externalApplication);
                    },
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.primary.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(25)
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 25,
                            height: 25,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Blockies(
                                seed: (transactionDetails.parameterValues[0] as EthereumAddress).hexEip55,
                                color: Get.theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5,),
                          Text(
                            Utils.truncate((transactionDetails.parameterValues[0] as EthereumAddress).hexEip55, leadingDigits: 4, trailingDigits: 4),
                            style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 3,),
                  InkWell(
                    onTap: (){
                      Utils.copyText((transactionDetails.parameterValues[0] as EthereumAddress).hexEip55, message: "Address copied!");
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                      decoration: BoxDecoration(
                          color: Get.theme.colorScheme.primary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(50)
                      ),
                      child: const Icon(PhosphorIcons.copy, size: 18,),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
