import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/screens/components/continous_input_border.dart';
import 'package:candide_mobile_app/screens/components/summary_table.dart';
import 'package:candide_mobile_app/screens/home/guardians/guardian_address_sheet.dart';
import 'package:candide_mobile_app/screens/home/guardians/guardian_system_onboarding.dart';
import 'package:candide_mobile_app/screens/home/guardians/magic_email_sheet.dart';
import 'package:candide_mobile_app/services/explorer.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/guardian_helpers.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    await Explorer.fetchAddressOverview(address: AddressData.wallet.walletAddress.hex,);
    await AddressData.loadGuardians();
    //AddressData.guardians = [];
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void checkGuardianSystemOnboarding() async {
    await Future.delayed(const Duration(milliseconds: 250)); // cooldown for the widget to not interrupt the widget while being built
    bool? onboardSeenStatus = Hive.box("state").get("guardian_onboard_tutorial_seen");
    if (onboardSeenStatus == null || onboardSeenStatus == false){
      Get.to(const GuardianSystemOnBoarding());
      await Hive.box("state").put("guardian_onboard_tutorial_seen", true);
    }
  }

  @override
  void initState() {
    checkGuardianSystemOnboarding();
    fetchGuardians();
    transactionStatusSubscription = eventBus.on<OnTransactionStatusChange>().listen((event) async {
      if (!mounted) return;
      if (event.activity.action.contains("guardian-")){
        if (event.activity.action == "guardian-revoke"){
          AddressData.guardians.removeWhere((element) => element.address.toLowerCase() == event.activity.data["guardian"]!.toLowerCase());
          await AddressData.storeGuardians();
        }
        fetchGuardians();
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
                    child: Text("Guardians", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),)
                  ),
                  IconButton(
                    icon: const Icon(
                      PhosphorIcons.info,
                      size: 32.0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GuardianSystemOnBoarding()),
                      );
                    },
                  ),
                  const SizedBox(width: 10,),
                ]
              )
            ),
            AddressData.guardians.length < 3 ? const _GuardianCountAlert() : const SizedBox.shrink(),
            AddressData.guardians.isEmpty ? noGuardiansWidget(true) : withGuardiansWidget()
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
        Container(
            margin: const EdgeInsets.only(left: 15, bottom: 5, top: 10),
            child: Text("Your guardians", style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 18),)
        ),
        const SizedBox(height: 10,),
        for (WalletGuardian guardian in AddressData.guardians)
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
                  bool refresh = await GuardianOperationsHelper.revokeGuardian(guardian.address, guardian.index);
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
                builder: (context) => SingleChildScrollView(
                  controller: ModalScrollController.of(context),
                  child: noGuardiansWidget(false),
                ),
              );
            },
            icon: const Icon(PhosphorIcons.plusBold, size: 15,),
            label: Text("Add guardian", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 15, height: 1.6),),
          ),
        ),
      ],
    );
  }

  Widget noGuardiansWidget(bool showTitle){
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        showTitle ? Container(
            margin: const EdgeInsets.only(left: 15, bottom: 5, top: 10),
            child: Text("Start by adding your first guardian", style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 18),)
        ) : const SizedBox(height: 15,),
        _GuardianAddCard(
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
        const SizedBox(height: 10,),
        _GuardianAddCard(
          type: "Family and friends",
          logo: SizedBox(
              width: 25,
              height: 25,
              child: SvgPicture.asset("assets/images/friends.svg")
          ),
          onPress: (){
            showBarModalBottomSheet(
              context: context,
              builder: (context) => SingleChildScrollView(
                controller: ModalScrollController.of(context),
                child: GuardianAddressSheet(
                  onProceed: (String address, String? nickname) async {
                    Get.back();
                    bool refresh = await GuardianOperationsHelper.grantGuardian(address, nickname);
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
        const SizedBox(height: 15,)
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
  final WalletGuardian guardian;
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
      title = "Email Guardian";
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        elevation: 3,
        child: InkWell(
          onTap: () async {
            await showBarModalBottomSheet(
              context: context,
              builder: (context) {
                Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "guardian_details_modal");
                return _GuardianDetailsCard(
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
                  text: "We recommend to have at least ",
                  style: TextStyle(height: 1.35),
                  children: [
                    TextSpan(text: "3 guardians ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: "to protect your wallet against loss"),
                  ]
                ),
              ),
              //Text("You are limited to only 1 guardian through our client app in beta\nThis restriction will be removed in production"),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuardianDetailsCard extends StatefulWidget {
  final WalletGuardian guardian;
  final VoidCallback onPressDelete;
  final Widget logo;
  const _GuardianDetailsCard({Key? key, required this.guardian, required this.logo, required this.onPressDelete}) : super(key: key);

  @override
  State<_GuardianDetailsCard> createState() => _GuardianDetailsCardState();
}

class _GuardianDetailsCardState extends State<_GuardianDetailsCard> {
  late final StreamSubscription transactionStatusSubscription;
  final TextEditingController nicknameController = TextEditingController();
  final FocusNode nicknameFocus = FocusNode();

  copyAddress() async {
    Clipboard.setData(ClipboardData(text: widget.guardian.address));
    BotToast.showText(
        text: "Address copied to clipboard!",
        textStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.black),
        contentColor: Get.theme.colorScheme.primary,
        align: Alignment.topCenter,
    );
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
  }

  saveNickname(String newNickname) async {
    widget.guardian.nickname = newNickname;
    await AddressData.storeGuardians();
    BotToast.showText(
        text: "New nickname saved!",
        textStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.black),
        contentColor: Get.theme.colorScheme.primary,
        align: Alignment.topCenter,
    );
  }


  @override
  void initState(){
    if (widget.guardian.nickname == null || widget.guardian.nickname!.isEmpty){
      nicknameController.text = "";
    }else{
      nicknameController.text = widget.guardian.nickname!;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.guardian.type.replaceAll("-", " ").capitalize!;
    if (widget.guardian.type == "magic-link"){
      title = "Email Guardian";
    }
    String dateAdded;
    if (widget.guardian.creationDate == null) {
      dateAdded = "Unknown";
    } else {
      dateAdded = intl.DateFormat.yMMMMd().format(widget.guardian.creationDate!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: Get.find<ScrollController>(tag: "guardian_details_modal"),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 15,),
                  Text("Guardian Details", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                  const SizedBox(height: 50,),
                  Transform.scale(
                    scale: 2.5,
                    child: widget.logo
                  ),
                  const SizedBox(height: 50,),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    child: TextFormField(
                      controller: nicknameController,
                      focusNode: nicknameFocus,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),
                      decoration: const InputDecoration(
                        label: Text("Nickname", style: TextStyle(fontSize: 25),),
                        border: ContinousInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                          borderRadius: BorderRadius.all(Radius.circular(35)),
                        ),
                      ),
                      onFieldSubmitted: (value) => saveNickname(value),
                    ),
                  ),
                  const SizedBox(height: 20,),
                  widget.guardian.type == "magic-link" 
                  ? Text(widget.guardian.email!, style: const TextStyle(fontSize: 15, color: Colors.grey)) 
                  : const SizedBox.shrink(),
                  const SizedBox(height: 15,),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: Get.width * 0.03),
                    child: SummaryTable(
                      entries: [
                          SummaryTableEntry(
                            title: "Guardian Address",
                            value: Utils.truncate(widget.guardian.address, trailingDigits: 4),
                            trailing: IconButton(
                              splashRadius: 12,
                              style: const ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: copyAddress,
                              icon: Icon(PhosphorIcons.copyLight, color: Get.theme.colorScheme.primary , size: 20),
                            ),
                          ),
                          SummaryTableEntry(
                            title: "Connection",
                            value: title,
                          ),
                         SummaryTableEntry(
                            title: "Date Added",
                            value: dateAdded,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20,),   
                  ElevatedButton(
                    onPressed: (){
                      widget.onPressDelete();
                    },
                    style: ButtonStyle(
                     backgroundColor: MaterialStateProperty.all(Colors.orange[600]),
                    ),
                    child: Text("Remove", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 17),),
                  ),
                  const Spacer(),
                  const SizedBox(height: 25,),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
