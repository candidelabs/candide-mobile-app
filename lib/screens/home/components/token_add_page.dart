import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/screens/home/components/address_field.dart';
import 'package:candide_mobile_app/screens/home/components/address_qr_scanner.dart';
import 'package:candide_mobile_app/services/token_info_fetcher.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class TokenImportPage extends StatefulWidget {
  const TokenImportPage({Key? key}) : super(key: key);

  @override
  State<TokenImportPage> createState() => _TokenImportPageState();
}

class _TokenImportPageState extends State<TokenImportPage> {
  String? address;
  TokenInfo? token;
  bool fetching = false;

  void fetchToken() async {
    if (address == null) return;
    setState(() => fetching = true);
    token = await TokenInfoFetcher.fetchTokenInfo(address!);
    setState(() => fetching = false);
    if (token == null) return;
  }

  RichText _buildTokenProperty(String property, String? value){
    return RichText(
      text: TextSpan(
        text: "$property: ",
        style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),
        children: [
          TextSpan(
            text: value ?? "-",
            style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 15),
          )
        ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Import Token", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 40,
        leading: Container(
          margin: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[800],
          ),
          child: IconButton(
            onPressed: (){
              Navigator.pop(context);
            },
            padding: const EdgeInsets.all(0),
            splashRadius: 15,
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(PhosphorIcons.caretLeftBold, size: 17,),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10,),
          AddressField(
            onAddressChanged: (val){
              if (Utils.isValidAddress(val)){
                address = val;
                fetchToken();
              }else{
                address = null;
                token = null;
                setState(() {});
              }
            },
            onENSChange: (Map? ens) {},
            hint: "Token Address",
            filled: false,
            scanENS: false,
            qrAlertWidget: const QRAlertFundsLoss(),
          ),
          const SizedBox(height: 25,),
          fetching ? Text(
            "Fetching token info...",
            style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),
          ) : Container(
            width: double.maxFinite,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTokenProperty("Name", token?.name),
                const SizedBox(height: 10,),
                _buildTokenProperty("Symbol", token?.symbol),
                const SizedBox(height: 10,),
                _buildTokenProperty("Decimals", token?.decimals.toString()),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  Get.back();
                },
                style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(Size(Get.width * 0.30, 40)),
                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                  elevation: MaterialStateProperty.all(0),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(color: Get.theme.colorScheme.primary)
                  ))
                ),
                child: Text("Cancel", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.primary),),
              ),
              const SizedBox(width: 15,),
              ElevatedButton(
                onPressed: token != null ? () async {
                  await TokenInfoStorage.addToken(token!, PersistentData.selectedAccount.chainId);
                  Get.back();
                } : null,
                style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(Size(Get.width * 0.30, 40)),
                  elevation: MaterialStateProperty.all(0),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(color: Get.theme.colorScheme.primary)
                  ))
                ),
                child: Text("Add token", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
              ),
            ],
          ),
          const SizedBox(height: 25,),
        ],
      ),
    );
  }
}
