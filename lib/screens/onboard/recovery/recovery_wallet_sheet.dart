import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/home/components/address_field.dart';
import 'package:candide_mobile_app/screens/home/components/address_qr_scanner.dart';
import 'package:candide_mobile_app/screens/onboard/components/credentials_entry.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RecoveryWalletSheet extends StatefulWidget {
  final String method;
  final Function(String, String, bool, String) onNext;
  const RecoveryWalletSheet({Key? key, required this.onNext, required this.method}) : super(key: key);

  @override
  State<RecoveryWalletSheet> createState() => _RecoveryWalletSheetState();
}

class _RecoveryWalletSheetState extends State<RecoveryWalletSheet> {
  String _lostWalletAddress = "";
  Map? _ensResponse = null;
  bool isValid = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints){
        return SingleChildScrollView(
          controller: Get.find<ScrollController>(tag: "recovery_wallet_modal"),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 15,),
                  Text("Recover", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                  const SizedBox(height: 35,),
                  AddressField(
                    onAddressChanged: (val){
                      setState(() => _lostWalletAddress = val);
                    },
                    onENSChange: (Map? ens) {
                      setState(() => _ensResponse = ens);
                    },
                    hint: "Lost wallet public address (0x), or ENS",
                    filled: false,
                    qrAlertWidget: const QRAlertRecoveryFail(),
                  ),
                  const SizedBox(height: 10,),
                  const Divider(thickness: 1, indent: 30, endIndent: 30,),
                  const SizedBox(height: 10,),
                  Text("New password", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),),
                  const SizedBox(height: 10,),
                  CredentialsEntry(
                    onConfirm: (password, biometricsEnabled) {
                      if (_ensResponse != null){
                        widget.onNext.call(_ensResponse!["address"], password, biometricsEnabled, widget.method);
                        return;
                      }
                      widget.onNext.call(_lostWalletAddress, password, biometricsEnabled, widget.method);
                    },
                    horizontalMargin: 15,
                    confirmButtonText: 'Next',
                    disable: !Utils.isValidAddress(_lostWalletAddress) && _ensResponse == null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
