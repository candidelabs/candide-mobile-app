import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class WCReviewLeading extends StatelessWidget {
  final WalletConnect connector;
  final JsonRpcRequest request;
  const WCReviewLeading({Key? key, required this.connector, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 75,
          height: 75,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(75),
            child: Image.network(
              connector.session.peerMeta!.icons![0]
            ),
          ),
        ),
        const SizedBox(height: 25,),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: connector.session.peerMeta!.name,
              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 22, color: Get.theme.colorScheme.primary),
              children: const [
                TextSpan(
                  text: " wants your permission to execute this transaction",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                )
              ]
            ),
          ),
        ),
        const SizedBox(height: 15,),
        Container(
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
                      text: "Data",
                      style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),
                      children: const [
                        TextSpan(
                          text: " in hex",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        )
                      ]
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(Utils.truncate(request.params![0]["data"], leadingDigits: 30, trailingDigits: 30), style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              )
            ),
          ),
        ),
      ],
    );
  }
}
