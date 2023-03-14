import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/screens/components/custom_switch.dart';
import 'package:candide_mobile_app/screens/home/components/token_add_page.dart';
import 'package:candide_mobile_app/screens/home/components/token_logo.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TokenManagementSheet extends StatefulWidget {
  const TokenManagementSheet({Key? key}) : super(key: key);

  @override
  State<TokenManagementSheet> createState() => _TokenManagementSheetState();
}

class _TokenManagementSheetState extends State<TokenManagementSheet> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: Get.find<ScrollController>(tag: "token_management_modal"),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
            child: Stack(
              children: [
                IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 25,),
                      Text("Manage token list", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                      const SizedBox(height: 15,),
                      for (TokenInfo token in TokenInfoStorage.tokens)
                        _TokenCard(
                          onVisibilityChange: () async {
                            token.visible = !token.visible;
                            await TokenInfoStorage.persistAllTokens(TokenInfoStorage.tokens, PersistentData.selectedAccount.chainId);
                            setState(() {});
                          },
                          token: token,
                        ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 25,
                  right: 25,
                  child: FloatingActionButton(
                    onPressed: (){
                      Get.to(const TokenImportPage());
                    },
                    backgroundColor: Get.theme.colorScheme.primary,
                    child: const Icon(Icons.add),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TokenCard extends StatelessWidget {
  final TokenInfo token;
  final VoidCallback onVisibilityChange;
  const _TokenCard({Key? key, required this.token, required this.onVisibilityChange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        child: ListTile(
          trailing: CustomSwitch(
            onChanged: (bool selected) => onVisibilityChange(),
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.grey[850],
            value: token.visible,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TokenLogo(
                token: token,
                size: 40,
              ),
              const SizedBox(width: 5,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Text(Utils.truncate(token.name, leadingDigits: 30, trailingDigits: 0), style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18))
                    ),
                    Text(token.symbol, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

