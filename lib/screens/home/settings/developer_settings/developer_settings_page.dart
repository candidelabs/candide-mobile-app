import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/home/settings/components/setting_menu_item.dart';
import 'package:candide_mobile_app/screens/home/settings/components/test_token_account_selection.dart';
import 'package:candide_mobile_app/screens/home/settings/developer_settings/manage_networks_page.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_dart/wallet/account.dart';

class DeveloperSettingsPage extends StatefulWidget {
  const DeveloperSettingsPage({Key? key}) : super(key: key);

  @override
  State<DeveloperSettingsPage> createState() => _DeveloperSettingsPageState();
}

class _DeveloperSettingsPageState extends State<DeveloperSettingsPage> {

  tweetToClaimTestTokens(Account account) async {
    Network network = Networks.getByChainId(account.chainId)!;
    var tweetUrl = "https://twitter.com/intent/tweet?text=I%27m%20claiming%20testnet%20tokens%20for%20%40candidewallet%2C%20a%20smart%20contract%20wallet%20based%20on%20ERC4337!%20%0a%0aMy%20Address%3A%20${account.address.hexEip55}%20%0aNetwork%3A%20${network.normalizedName}";
    Utils.launchUri(tweetUrl, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Developer settings", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
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
            onPressed: () => Get.back(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15,),
          SettingMenuItem(
            onPress: (){
              Get.to(const ManageNetworksPage(), transition: Transition.rightToLeft);
            },
            leading: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepOrange,
                    Colors.deepOrangeAccent,
                  ],
                ),
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Icon(PhosphorIcons.currencyEthLight, color: Colors.white,),
              ),
            ),
            label: Text("Manage Networks", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17)),
            trailing: const Icon(PhosphorIcons.arrowRightBold),
          ),
          SettingMenuItem(
            leading: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.yellow,
                    Colors.green,
                  ],
                ),
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Icon(PhosphorIcons.coins, color: Colors.white,),
              ),
            ),
            label: RichText(
              text: TextSpan(
                text: "Request Test Tokens",
                style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17),
              ),
            ),
            trailing: const Icon(PhosphorIcons.twitterLogo),
            onPress: () {
              //tweetToClaimTestTokens();
              showDialog(
                  context: context,
                  builder: (_) => TestTokenAccountSelection(
                    onSelect: (Account account){
                      tweetToClaimTestTokens(account);
                    },
                  )
              );
            },
            description: const Text("Use the social faucet to get test tokens",),
          ),
        ],
      ),
    );
  }
}
