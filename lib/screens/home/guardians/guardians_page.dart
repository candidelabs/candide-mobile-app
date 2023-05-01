import 'dart:async';
import 'dart:ui';

import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/screens/home/activity/components/transaction_activity_details_card.dart';
import 'package:candide_mobile_app/screens/home/guardians/components/guardian_details_sheet.dart';
import 'package:candide_mobile_app/screens/home/guardians/guardian_address_sheet.dart';
import 'package:candide_mobile_app/screens/home/guardians/guardian_system_onboarding.dart';
import 'package:candide_mobile_app/screens/home/guardians/magic_email_sheet.dart';
import 'package:candide_mobile_app/services/explorer.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/guardian_helpers.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:web3dart/credentials.dart';

class GuardiansPage extends StatefulWidget {
  const GuardiansPage({Key? key}) : super(key: key);

  @override
  State<GuardiansPage> createState() => _GuardiansPageState();
}

class _GuardiansPageState extends State<GuardiansPage> {
  bool _loading = true;
  late final StreamSubscription transactionStatusSubscription;

  void fetchGuardians() async {
    setState(() => _loading = true);
    await Explorer.fetchAddressOverview(account: PersistentData.selectedAccount, skipBalances: true, fetchSocialRecoveryModule: true);
    await PersistentData.loadGuardians(PersistentData.selectedAccount);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void checkGuardianSystemOnboarding() async {
    await Future.delayed(const Duration(milliseconds: 250)); // cooldown for the widget to not interrupt the widget while being built
    bool? onboardSeenStatus = Hive.box("state").get("guardian_onboard_tutorial_seen");
    if (onboardSeenStatus == null || onboardSeenStatus == false){
      Get.to(GuardianSystemOnBoarding(account: PersistentData.selectedAccount));
      await Hive.box("state").put("guardian_onboard_tutorial_seen", true);
    }
  }

  @override
  void initState() {
    checkGuardianSystemOnboarding();
    fetchGuardians();
    transactionStatusSubscription = eventBus.on<OnTransactionStatusChange>().listen((event) async {
      if (!mounted) return;
      if (!PersistentData.transactionsActivity.contains(event.activity)) return;
      if (event.activity.action.contains("guardian-")){
        if (event.activity.action == "guardian-revoke"){
          PersistentData.guardians.removeWhere((element) => element.address.toLowerCase() == event.activity.data["guardian"]!.toLowerCase());
          await PersistentData.storeGuardians(PersistentData.selectedAccount);
        }
        fetchGuardians();
      }else if (event.activity.action == "guardian-grant"){
        PersistentData.selectedAccount.socialRecoveryModule = Networks.selected().socialRecoveryModule;
        await PersistentData.saveAccounts();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    transactionStatusSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading ? const Center(child: CircularProgressIndicator(),) : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 12, top: 18),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text("Recovery Contacts", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),)
                  ),
                  IconButton(
                    icon: const Icon(
                      PhosphorIcons.info,
                      size: 32.0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GuardianSystemOnBoarding(account: PersistentData.selectedAccount)),
                      );
                    },
                  ),
                  const SizedBox(width: 10,),
                ]
              )
            ),
            PersistentData.guardians.length < 3 ? const _GuardianCountAlert() : const SizedBox.shrink(),
            PersistentData.guardians.isEmpty ? noGuardiansWidget(true) : withGuardiansWidget()
          ],
        ),
      ),
    );
  }

  Widget withGuardiansWidget(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (AccountGuardian guardian in PersistentData.guardians)
          Builder(
            builder: (context) {
              Widget logo;
              if (guardian.type == "magic-link"){
                logo = SizedBox(
                    width: 35,
                    height: 35,
                    child: SvgPicture.asset("assets/images/magic_link.svg")
                );
              }else if (guardian.type == "family-and-friends"){
                logo = SizedBox(
                    width: 35,
                    height: 35,
                    child: SvgPicture.asset("assets/images/friends.svg")
                );
              }else if (guardian.type == "hardware-wallet"){
                logo = SizedBox(
                    width: 35,
                    height: 35,
                  child: SvgPicture.asset("assets/images/hardware-wallet.svg")
                );
              }else{
                logo = Container(
                    margin: const EdgeInsets.only(right: 10, bottom: 5),
                    child: const Icon(PhosphorIcons.keyLight, size: 25,)
                );
              }
              return _GuardianCard(
                guardian: guardian,
                logo: logo,
                onPressDelete: () async {
                  bool refresh = await GuardianOperationsHelper.revokeGuardian(PersistentData.selectedAccount, EthereumAddress.fromHex(guardian.address));
                  if (refresh){
                    fetchGuardians();
                  }
                },
              );
            }
          ),
        const SizedBox(height: 10,),
        Center(
          child: ElevatedButton.icon(
            onPressed: (){
              showBarModalBottomSheet(
                context: context,
                backgroundColor: Get.theme.canvasColor,
                builder: (context) => SingleChildScrollView(
                  controller: ModalScrollController.of(context),
                  child: noGuardiansWidget(false),
                ),
              );
            },
            icon: const Icon(PhosphorIcons.plusBold, size: 15,),
            label: Text("Add recovery contact", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 15, height: 1.6),),
          ),
        ),
      ],
    );
  }

  Widget noGuardiansWidget(bool showTitle){
    bool magicLinkEnabled = Networks.selected().isFeatureEnabled("social-recovery.magic-link");
    if (Env.magicApiKey.trim().isEmpty || Env.magicApiKey.trim() == "-"){
      magicLinkEnabled = false;
    }
    bool familyFriendsEnabled = Networks.selected().isFeatureEnabled("social-recovery.family-and-friends");
    bool hardwareWalletsEnabled = Networks.selected().isFeatureEnabled("social-recovery.hardware-wallet");
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15,),
        magicLinkEnabled ? Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: _GuardianAddCard(
            type: "Email recovery",
            description: "Through Magic Link",
            logo: SizedBox(
              width: 25,
              height: 25,
              child: SvgPicture.asset("assets/images/magic_link.svg")
            ),
            onPress: (){
              showBarModalBottomSheet(
                context: context,
                backgroundColor: Get.theme.canvasColor,
                builder: (context) => SingleChildScrollView(
                  controller: ModalScrollController.of(context),
                  child: MagicEmailSheet(
                    onProceed: (String email, String? nickname) async {
                      bool result = await GuardianOperationsHelper.setupMagicLinkGuardian(email, nickname);
                      if (result){
                        fetchGuardians();
                      }
                      if (!showTitle){
                        Get.back();
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ) : const SizedBox.shrink(),
        familyFriendsEnabled ? Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: _GuardianAddCard(
            type: "Family and friends",
            logo: SizedBox(
                width: 25,
                height: 25,
                child: SvgPicture.asset("assets/images/friends.svg")
            ),
            onPress: (){
              showBarModalBottomSheet(
                context: context,
                backgroundColor: Get.theme.canvasColor,
                builder: (context) => SingleChildScrollView(
                  controller: ModalScrollController.of(context),
                  child: GuardianAddressSheet(
                    title: "Add recovery contact",
                    onProceed: (String address, String? nickname) async {
                      Get.back();
                      bool refresh = await GuardianOperationsHelper.grantGuardian(PersistentData.selectedAccount, EthereumAddress.fromHex(address), nickname, "family-and-friends");
                      if (refresh){
                        fetchGuardians();
                      }
                      if (!showTitle){
                        Get.back();
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ) : const SizedBox.shrink(),
        hardwareWalletsEnabled ? Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: _GuardianAddCard(
            type: "Hardware wallet",
            logo: SizedBox(
                width: 25,
                height: 25,
                child: SvgPicture.asset("assets/images/hardware-wallet.svg")
            ),
            onPress: (){
              showBarModalBottomSheet(
                context: context,
                backgroundColor: Get.theme.canvasColor,
                builder: (context) => SingleChildScrollView(
                  controller: ModalScrollController.of(context),
                  child: GuardianAddressSheet(
                    title: "Add hardware wallet",
                    onProceed: (String address, String? nickname) async {
                      Get.back();
                      bool refresh = await GuardianOperationsHelper.grantGuardian(PersistentData.selectedAccount, EthereumAddress.fromHex(address), nickname, "hardware-wallet");
                      if (refresh){
                        fetchGuardians();
                      }
                      if (!showTitle){
                        Get.back();
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ) : const SizedBox.shrink(),
        const SizedBox(height: 5,)
      ],
    );
  }
}

class _GuardianAddCard extends StatelessWidget { // todo move to components
  final String type;
  final String? description;
  final Widget logo;
  final VoidCallback onPress;
  const _GuardianAddCard({Key? key, required this.type, required this.logo, required this.onPress, this.description}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        elevation: 3,
        child: InkWell(
          onTap: onPress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            child: Row(
              children: [
                const SizedBox(width: 5,),
                logo,
                const SizedBox(width: 15,),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(type.capitalize!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                    const SizedBox(height: 5,),
                    description != null ? Text(description!, style: const TextStyle(fontSize: 13, color: Colors.grey),) : const SizedBox.shrink(),
                  ],
                ),
                const SizedBox(width: 5,),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded),
                const SizedBox(width: 5,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _GuardianCard extends StatefulWidget { // todo move to components
  final AccountGuardian guardian;
  final Widget logo;
  final VoidCallback onPressDelete;
  const _GuardianCard({Key? key, required this.guardian, required this.logo, required this.onPressDelete}) : super(key: key);

  @override
  State<_GuardianCard> createState() => _GuardianCardState();
}

class _GuardianCardState extends State<_GuardianCard> {
  @override
  Widget build(BuildContext context) {
    String title = widget.guardian.type.replaceAll("-", " ").capitalize!;
    if (widget.guardian.type == "magic-link"){
      title = "Email Recovery";
    } else if (widget.guardian.type == "hardware-wallet"){
      title = "Hardware Wallet";
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Stack(
        children: [
          Card(
            elevation: 3,
            child: InkWell(
              onTap: widget.guardian.isBeingRemoved ? null : () async {
                await showBarModalBottomSheet(
                  context: context,
                  backgroundColor: Get.theme.canvasColor,
                  builder: (context) {
                    Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "guardian_details_modal");
                    return GuardianDetailsSheet(
                      guardian: widget.guardian,
                      onPressDelete: widget.onPressDelete,
                      logo: widget.logo,
                    );
                  },
                );
                setState((){});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                child: Row(
                  children: [
                    const SizedBox(width: 5,),
                    widget.logo,
                    const SizedBox(width: 15,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                          ],
                        ),
                        (widget.guardian.nickname?.isNotEmpty ?? false) ? Text("\n${widget.guardian.nickname!}\n", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13, height: 0.5)) : const SizedBox.shrink(),
                        widget.guardian.type == "magic-link" ? Text(widget.guardian.email!, style: const TextStyle(fontSize: 12, color: Colors.grey)) : const SizedBox.shrink(),
                        Text(Utils.truncate(widget.guardian.address), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          widget.guardian.isBeingRemoved ? Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.75, sigmaY: 1.75),
                child: Container(
                  margin: const EdgeInsets.all(4.6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(3)
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        TransactionActivity? activity = PersistentData.transactionsActivity.reversed.toList().firstWhereOrNull(
                          (element) => element.action == "guardian-revoke"
                              && element.data["guardian"]?.toLowerCase() == widget.guardian.address.toLowerCase()
                        );
                        if (activity == null) return;
                        await showBarModalBottomSheet(
                          context: Get.context!,
                          backgroundColor: Get.theme.canvasColor,
                          builder: (context) {
                            Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "transaction_details_modal");
                            return TransactionActivityDetailsCard(
                              transaction: activity,
                            );
                          },
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator()
                          ),
                          const SizedBox(width: 15,),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Removal in progress", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20)),
                              const Text("Tap to view transaction status", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ) : const SizedBox.shrink(),
        ],
      ),
    );
  }
}


class _GuardianCountAlert extends StatelessWidget { // todo move to components
  const _GuardianCountAlert({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Card(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            children: [
              Row(
                children: const [
                  Icon(Icons.warning_rounded, color: Colors.amber,),
                  SizedBox(width: 10,),
                  Text("Note", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                ],
              ),
              const SizedBox(height: 10,),
              RichText(
                text: const TextSpan(
                  text: "Add at least",
                  style: TextStyle(height: 1.35),
                  children: [
                    TextSpan(text: " THREE ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: "recovery contacts to protect your account against loss"),
                  ]
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
