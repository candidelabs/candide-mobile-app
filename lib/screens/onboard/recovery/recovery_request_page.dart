import 'dart:convert';

import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/services/security.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/recovery_request.dart';
import 'package:candide_mobile_app/screens/components/continous_input_border.dart';
import 'package:candide_mobile_app/screens/components/summary_table.dart';
import 'package:candide_mobile_app/screens/home/home_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_dart/contracts/wallet.dart';
import 'package:wallet_dart/wallet/wallet_instance.dart';
import 'package:web3dart/web3dart.dart';

class RecoveryRequestPage extends StatefulWidget {
  final RecoveryRequest request;
  const RecoveryRequestPage({Key? key, required this.request}) : super(key: key);

  @override
  State<RecoveryRequestPage> createState() => _RecoveryRequestPageState();
}

class _RecoveryRequestPageState extends State<RecoveryRequestPage> {
  late RecoveryRequest request;
  bool refreshing = false;
  int? minimumSignatures;

  navigateToHome(){
    AddressData.loadExplorerJson(null);
    SettingsData.loadFromJson(null);
    Get.off(const HomeScreen());
  }

  Future<void> fetchMinimumSignatures() async {
    minimumSignatures = (await CWallet.recoveryInterface(EthereumAddress.fromHex(request.socialRecoveryAddress)).threshold()).toInt(); // todo fix for integration
    setState(() {});
  }

  void refreshData() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    request = (await SecurityGateway.fetchById(request.id!))!;
    await fetchMinimumSignatures();
    bool _isOwner = await isOwner();
    setState(() => refreshing = false);
    if (_isOwner){
      Future.delayed(const Duration(milliseconds: 500), () async {
        await Hive.box("state").delete("recovery_request_id");
        var walletData = Hive.box("wallet").get("recovered");
        await Hive.box("wallet").put("main", walletData);
        AddressData.wallet = WalletInstance.fromJson(jsonDecode(walletData));
        navigateToHome();
      }); // delay to give the user some time to see the signatures he acquired
    }
  }

  Future<bool> isOwner() async {
    String currentOwner = (await CWallet.customInterface(EthereumAddress.fromHex(request.walletAddress)).getOwners())[0].hex.toLowerCase();
    if (currentOwner == request.newOwner.toLowerCase()){
      return true;
    }
    return false;
  }

  @override
  void initState() {
    request = widget.request;
    refreshData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 25,),
              Text("Hi.", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 30),),
              const SizedBox(height: 10,),
              Lottie.asset(
                "assets/animations/keys3.json",
                width: Get.width * 0.5,
              ),
              const SizedBox(height: 10,),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "Your recovery request is still in ",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 18),
                  children: [
                    TextSpan(
                      text: "progress",
                      style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.green),
                    )
                  ]
                ),
              ),
              const SizedBox(height: 10,),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                    text: "Your guardians can approve the request through ",
                    style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 18),
                    children: [
                      TextSpan(
                        text: "security.candidewallet.com",
                        style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchUrl(Uri.parse('https://security.candidewallet.com')),
                      )
                    ]
                ),
              ),
              const SizedBox(height: 15,),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: "Be sure that your guardians see this same set of ",
                    style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),
                    children: const [
                      TextSpan(
                        text: "emojis",
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                      TextSpan(
                        text: " when approving your request",
                      )
                    ]
                  ),
                ),
              ),
              const SizedBox(height: 10,),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: TextFormField(
                  initialValue: request.emoji!,
                  enabled: false,
                  textAlign: TextAlign.center,
                  style: const TextStyle(letterSpacing: 5, fontSize: 23),
                  decoration: InputDecoration(
                    disabledBorder: ContinousInputBorder(
                        borderSide: BorderSide(width: 2, color: Colors.grey.withOpacity(0.5)),
                        borderRadius: const BorderRadius.all(Radius.circular(40))
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(40))
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20,),
              Row(
                children: [
                  const SizedBox(width: 10,),
                  Text("Recovery info", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),),
                  const Spacer(),
                  IconButton(
                    onPressed: refreshData,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 10,),
                ],
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: SummaryTable(
                  entries: [
                    SummaryTableEntry(
                      title: "Wallet Address",
                      value: refreshing ? "..." : request.walletAddress,
                    ),
                    SummaryTableEntry(
                      title: "Recovery status",
                      value: refreshing ? "..." : request.status!,
                    ),
                    SummaryTableEntry(
                      title: "Minimum signatures",
                      value: refreshing ? "..." : minimumSignatures?.toString() ?? "...",
                    ),
                    SummaryTableEntry(
                      title: "Signatures acquired",
                      value: refreshing ? "..." : request.signaturesAcquired!.toString(),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
