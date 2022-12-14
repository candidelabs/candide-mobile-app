import 'dart:convert';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/services/security.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/models/recovery_request.dart';
import 'package:candide_mobile_app/screens/components/summary_table.dart';
import 'package:candide_mobile_app/screens/home/home_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
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
  List<EthereumAddress> guardians = [];
  late List<SummaryTableEntry> recoveryInfoList;
  bool _showGuardianAddresses = false;

  navigateToHome(){
    AddressData.loadExplorerJson(null);
    SettingsData.loadFromJson(null);
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> const HomeScreen()));
  }

  Future<void> fetchMinimumSignatures() async {
    minimumSignatures = (await CWallet.recoveryInterface(EthereumAddress.fromHex(request.socialRecoveryAddress)).threshold()).toInt();
    setState(() {});
  }

  Future<void> getFriends() async {
    guardians = await CWallet.recoveryInterface(EthereumAddress.fromHex(request.socialRecoveryAddress)).getFriends();

    setState(() {});
  }

  void refreshData() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    RecoveryRequest? _updatedRequest = (await SecurityGateway.fetchById(request.id!));
    if (_updatedRequest == null){
      setState(() => refreshing = false);
      return;
    }
    request = _updatedRequest;
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

  List<SummaryTableEntry> getRecoveryInfoEntries() {
    recoveryInfoList = [
      SummaryTableEntry(
        title: "Wallet Address",
        value: refreshing ? "..." : request.walletAddress,
      ),
      SummaryTableEntry(
        title: "Recovery status",
        value: refreshing ? "..." : request.status!,
      ),
      SummaryTableEntry(
        title: "Minimum approvals",
        value: refreshing ? "..." : minimumSignatures?.toString() ?? "...",
      ),
      SummaryTableEntry(
        title: "Approvals acquired",
        value: refreshing ? "..." : request.signaturesAcquired!.toString(),
        trailing: IconButton(
          onPressed: (()=> setState(() {
            _showGuardianAddresses = !_showGuardianAddresses;
          })),
          iconSize: 18,
            icon: !_showGuardianAddresses 
            ? const Icon(PhosphorIcons.caretDown) 
            : const Icon(PhosphorIcons.caretUp),
        ),
      ),
    ];

    if (_showGuardianAddresses && guardians.isNotEmpty) {
      int index = 1;
      for (EthereumAddress guardian in guardians) {
        var guardianAddressFormatted = guardian.toString();
        recoveryInfoList.add(
          SummaryTableEntry(
            title: "Guardian ${index++}",
            value: guardianAddressFormatted,
            trailing: IconButton(
              splashRadius: 12,
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => Utils.copyText(guardianAddressFormatted, message: "Address copied to clipboard!"),
              icon: Icon(PhosphorIcons.copyLight, color: Get.theme.colorScheme.primary , size: 20),
            ),
          ),
        );
      }
    }
    return recoveryInfoList;
  }

  @override
  void initState() {
    request = widget.request;
    refreshData();
    getFriends();
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
              const SizedBox(height: 10,),
              Lottie.asset(
                "assets/animations/keys3.json",
                width: Get.width * 0.5,
              ),
              const SizedBox(height: 10,),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                    text: "Ask your guardians to approve your request on ",
                    style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 18),
                    children: [
                      TextSpan(
                        text: "security.candidewallet.com",
                        style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            String url = "https://security.candidewallet.com";
                            var urllaunchable = await canLaunchUrl(Uri.parse(url)); 
                            if(urllaunchable) {
                              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            } else {
                              throw("URL can't be launched.");
                            }
                          } 
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
                    text: "Ensure you and your guardian see matching ",
                    style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),
                    children: const [
                      TextSpan(
                        text: "emojis",
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                    ]
                  ),
                ),
              ),
              const SizedBox(height: 10,),
              Container(
                width: 350,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () => Utils.copyText(request.emoji.toString(), message: "Emojis copied to clipboard!"),
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.transparent),
                    shape: MaterialStateProperty.all(BeveledRectangleBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      side: BorderSide(
                          width: 2, color: Colors.grey.withOpacity(0.5)),
                    )),
                  ),
                  child: TextFormField(
                          initialValue: request.emoji!,
                          textAlign: TextAlign.center,
                          enabled: false,
                          style:
                              const TextStyle(letterSpacing: 5, fontSize: 23),
                        ),
                ),
              ),
              const SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 65,
                    child: ElevatedButton(
                      onPressed: () {
                        // _onShare method:
                        final box = context.findRenderObject() as RenderBox?;
                        Share.share(
                          "Here's my public address: ${widget.request.walletAddress}.\n I need you to approve my recovery request on https://security.candidewallet.com.\nInsure you are approving the same set of emojis ${widget.request.emoji!}",
                          sharePositionOrigin:
                              box!.localToGlobal(Offset.zero) & box.size,
                        );
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.transparent),
                        elevation: MaterialStateProperty.all(0),
                        shape: MaterialStateProperty.all(BeveledRectangleBorder(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                            ),
                            side: BorderSide(width: 2, color: Colors.grey.withOpacity(0.5))
                        )),
                      ),
                      child: Icon(PhosphorIcons.shareLight, color: Get.theme.colorScheme.primary, size: 20,),
                    ),
                  ),
                  const SizedBox(width: 5,),
                ],
              ),
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
                  entries: getRecoveryInfoEntries(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
