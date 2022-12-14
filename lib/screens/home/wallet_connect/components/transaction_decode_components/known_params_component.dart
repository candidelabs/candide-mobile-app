import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/services/transaction_decoder.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web3dart/credentials.dart';

class KnownParamsComponent extends StatelessWidget {
  final HexTransactionDetails transactionDetails;
  const KnownParamsComponent({Key? key, required this.transactionDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: Utils.camelCaseToLowerUnderscore(transactionDetails.functionName).replaceAll("_", " ").capitalize,
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),
                ),
              ),
              for (int i=0; i<transactionDetails.parameterTypes.length; i++)
                Builder(
                  builder: (context) {
                    String value = transactionDetails.parameterValues[i].toString();
                    double valueFontSize = 12;
                    if (transactionDetails.parameterTypes[i] == "uint256"){
                      if ((transactionDetails.parameterValues[i] as BigInt) == BigInt.parse("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", radix: 16)){
                        value = "∞";
                        valueFontSize = 18;
                      }
                    }
                    if (transactionDetails.parameterTypes[i] == "address"){
                      value = (transactionDetails.parameterValues[i] as EthereumAddress).hexEip55;
                    }
                    return Container(
                      margin: const EdgeInsets.only(top: 5),
                      child: RichText(
                        text: TextSpan(
                          text: "${transactionDetails.parameterTypes[i]}: ",
                          style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 15),
                          children: [
                            TextSpan(
                              text: value,
                              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: valueFontSize, color: Colors.grey),
                            ),
                          ]
                        ),
                      ),
                    );
                  }
                )
              ],
            )
        ),
      ),
    );
  }
}
