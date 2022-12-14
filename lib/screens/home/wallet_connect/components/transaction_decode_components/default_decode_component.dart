import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class DefaultDecodedLeading extends StatelessWidget {
  final JsonRpcRequest request;
  const DefaultDecodedLeading({Key? key, required this.request}) : super(key: key);

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
              Text(Utils.truncate(request.params![0]["data"], leadingDigits: 30, trailingDigits: 30), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ),
      ),
    );
  }
}
