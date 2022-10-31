import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:candide_mobile_app/screens/home/guardians/guardian_address_sheet.dart';
import 'package:candide_mobile_app/screens/home/guardians/magic_email_sheet.dart';
import 'package:candide_mobile_app/utils/guardian_helpers.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GuardiansPage extends StatefulWidget {
  const GuardiansPage({Key? key}) : super(key: key);

  @override
  State<GuardiansPage> createState() => _GuardiansPageState();
}

class _GuardiansPageState extends State<GuardiansPage> {
  bool _loading = true;

  void fetchGuardians() async {
    setState(() => _loading = true);
    await AddressData.loadGuardians();
    //AddressData.guardians = [];
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void initState() {
    fetchGuardians();
    super.initState();
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
                margin: const EdgeInsets.only(left: 15, top: 25),
                child: Text("Guardians", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),)
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
          recommended: true,
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
                  onProceed: (String email) async {
                    bool result = await GuardianOperationsHelper.setupMagicLinkGuardian(email);
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
                  onProceed: (String address) async {
                    Get.back();
                    bool refresh = await GuardianOperationsHelper.grantGuardian(address);
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
  final Widget logo;
  final bool recommended;
  final VoidCallback onPress;
  const _GuardianAddCard({Key? key, required this.type, required this.logo, required this.onPress, this.recommended=false}) : super(key: key);

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
                    Row(
                      children: [
                        Text(type.capitalize!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                        //recommended ? const Text("  recommended", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.green, height: 2),) : const SizedBox.shrink(),
                      ],
                    ),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: TextButton.icon(
                        onPressed: (){},
                        style: ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: MaterialStateProperty.all(EdgeInsets.zero),
                        ),
                        icon: Container(
                          margin: const EdgeInsets.only(bottom: 3.5),
                          child: const Icon(PhosphorIcons.arrowSquareOutLight, size: 10, color: Colors.lightBlue)
                        ),
                        label: Text("Learn more about ${type.toLowerCase()}", style: const TextStyle(fontSize: 11, color: Colors.lightBlue)),
                      ),
                    )
                    //const Text("Learn more about magic link", style: TextStyle(fontSize: 12, color: Colors.lightBlue),),
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


class _GuardianCard extends StatelessWidget { // todo move to components
  final WalletGuardian guardian;
  final Widget logo;
  final VoidCallback onPressDelete;
  const _GuardianCard({Key? key, required this.guardian, required this.logo, required this.onPressDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title = guardian.type.replaceAll("-", " ").capitalize!;
    if (guardian.type == "magic-link"){
      title = "Email Guardian";
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        elevation: 3,
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
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                    ],
                  ),
                  Text(Utils.truncate(guardian.address), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  guardian.type == "magic-link" ? Text(guardian.email!, style: const TextStyle(fontSize: 12, color: Colors.grey)) : const SizedBox.shrink(),
                ],
              ),
              const SizedBox(width: 5,),
              const Spacer(),
              TextButton(
                onPressed: onPressDelete,
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  padding: MaterialStateProperty.all(EdgeInsets.zero),
                  visualDensity: VisualDensity.compact
                ),
                child: Column(
                  children: const [
                    Icon(PhosphorIcons.trashLight),
                    SizedBox(height: 5,),
                    Text("Remove"),
                  ],
                ),
              ),
              const SizedBox(width: 5,),
            ],
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
                text: TextSpan(
                  text: "We recommend to have at least ",
                  style: const TextStyle(height: 1.35),
                  children: [
                    const TextSpan(text: "3 guardians ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const TextSpan(text: "to fully protect your wallet against lost"),
                    const TextSpan(text: "\nlearn more at"),
                    TextSpan(
                      text: " candidewallet.com/security-faqs",
                      style: const TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {}, // todo add faqs url
                    ),
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

