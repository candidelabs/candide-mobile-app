import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/screens/home/components/address_field.dart';
import 'package:candide_mobile_app/screens/home/components/address_qr_scanner.dart';
import 'package:candide_mobile_app/screens/onboard/components/chain_selector.dart';
import 'package:candide_mobile_app/screens/onboard/create_account/pin_entry_screen.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_dart/wallet/account.dart';

class RecoverAccountSheet extends StatefulWidget {
  final String method;
  final Function(String, int, String?, bool?, String) onNext;
  const RecoverAccountSheet({Key? key, required this.onNext, required this.method}) : super(key: key);

  @override
  State<RecoverAccountSheet> createState() => _RecoverAccountSheetState();
}

class _RecoverAccountSheetState extends State<RecoverAccountSheet> {
  String _lostAccountAddress = "";
  int chainId = Networks.instances.firstWhere((element) => element.visible).chainId.toInt();
  bool isValid = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints){
        return SingleChildScrollView(
          controller: Get.find<ScrollController>(tag: "recovery_account_modal"),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 15,),
                  Text("Recover", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                  const SizedBox(height: 5,),
                  const Divider(thickness: 1, indent: 30, endIndent: 30,),
                  const SizedBox(height: 5,),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 25),
                    child: Text(
                      "What chain did your account reside in ?",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 16),
                    )
                  ),
                  const SizedBox(height: 5,),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChainSelector(
                      selectedChainId: chainId,
                      onSelect: (_chainId){
                        setState(() {
                          chainId = _chainId;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 5,),
                  const Divider(thickness: 1, indent: 30, endIndent: 30,),
                  const SizedBox(height: 5,),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 25),
                    child: Text(
                      "What was your account's address ?",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 16),
                    )
                  ),
                  const SizedBox(height: 5,),
                  AddressField(
                    onAddressChanged: (val){
                      setState(() => _lostAccountAddress = val);
                    },
                    onENSChange: (Map? ens) {
                      // ENS is disabled
                    },
                    hint: "Lost account public address (0x)",
                    filled: false,
                    scanENS: false,
                    qrAlertWidget: const QRAlertRecoveryFail(),
                  ),
                  const SizedBox(height: 10,),
                  ElevatedButton(
                    onPressed: !Utils.isValidAddress(_lostAccountAddress) ? null : (){
                      Account? account = PersistentData.accounts.firstWhereOrNull(
                        (element) => element.address.hex == _lostAccountAddress.toLowerCase() && element.chainId == chainId
                      );
                      if (account != null){
                        Utils.showError(title: "Account already exists", message: "Your wallet already contains this account, no need for recovery");
                        return;
                      }
                      if (PersistentData.accounts.isEmpty){
                        Get.to(PinEntryScreen(
                          showLogo: false,
                          promptText: "Choose a PIN to unlock your wallet",
                          confirmText: "Confirm your chosen PIN",
                          confirmMode: true,
                          showBiometricsToggle: true,
                          onPinEnter: (String password, bool useBiometrics){
                            widget.onNext.call(_lostAccountAddress, chainId, password, useBiometrics, widget.method);
                          },
                          onBack: (){
                            Get.back();
                          },
                        ));
                      }else{
                        widget.onNext.call(_lostAccountAddress, chainId, null, null, widget.method);
                      }
                    },
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)
                      )),
                    ),
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Text("Next", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),)
                    ),
                  ),
                  const SizedBox(height: 10,),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
