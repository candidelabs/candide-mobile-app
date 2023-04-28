import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/services/transaction_decoder.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

class KnownParamsComponent extends StatelessWidget {
  final HexTransactionDetails transactionDetails;
  final EdgeInsets margin;
  final double? elevation;

  const KnownParamsComponent({
    Key? key,
    required this.transactionDetails,
    this.margin = const EdgeInsets.symmetric(horizontal: 10),
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Card(
        elevation: elevation ?? Get.theme.cardTheme.elevation,
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
                    if (transactionDetails.parameterValues[i].runtimeType.toString() == "List<dynamic>"){ // todo decode nested arrays
                      if (transactionDetails.parameterValues[i].isNotEmpty){
                        if (transactionDetails.parameterValues[i][0].runtimeType.toString() == "_Uint8ArrayView"){
                          value = (transactionDetails.parameterValues[i] as List<dynamic>).map((e) => bytesToHex(e, include0x: true)).toList().toString();
                        }
                      }

                    }
                    if (transactionDetails.parameterValues[i].runtimeType.toString() == "_Uint8ArrayView"){
                      value = bytesToHex(transactionDetails.parameterValues[i], include0x: true);
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
