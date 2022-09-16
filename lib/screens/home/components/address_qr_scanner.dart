import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/settings_persistent_data.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class AddressQRScanner extends StatefulWidget {
  final Function(String) onScanAddress;
  final Widget alertWidget;
  const AddressQRScanner({Key? key, required this.onScanAddress, required this.alertWidget}) : super(key: key);

  @override
  State<AddressQRScanner> createState() => _AddressQRScannerState();
}

class _AddressQRScannerState extends State<AddressQRScanner> {
  final GlobalKey _qrKey = GlobalKey();
  Barcode? result;
  QRViewController? controller;

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code == null) return;
      if (Utils.isValidAddress(scanData.code!)){
        controller.dispose();
        Get.back();
        widget.onScanAddress(scanData.code!);
      }else{
        BotToast.showText(
          text: "Invalid address",
          contentColor: Colors.red,
          align: Alignment.topCenter,
        );
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 5,),
                        IconButton(
                          onPressed: (){
                            Get.back();
                          },
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Spacer(flex: 2,),
                        Text("Scan QR code", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 20),),
                        const Spacer(flex: 3,),
                      ],
                    ),
                    Expanded(
                      child: QRView(
                        key: _qrKey,
                        onQRViewCreated: _onQRViewCreated,
                      ),
                    ),
                    widget.alertWidget,
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}

class QRAlertFundsLoss extends StatelessWidget {
  const QRAlertFundsLoss({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: RichText(
        text: TextSpan(
            text: "Please make sure that the address you wish to send to is on ",
            style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
            children: [
              TextSpan(
                  text: SettingsData.network,
                  style: TextStyle(color: Networks.get(SettingsData.network)!.color)
              ),
              const TextSpan(
                text: " network, otherwise funds may be ",
              ),
              const TextSpan(
                  text: "lost",
                  style: TextStyle(color: Colors.orange)
              ),
            ]
        ),
      ),
    );
  }
}

class QRAlertGuardianAddressFail extends StatelessWidget {
  const QRAlertGuardianAddressFail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: RichText(
        text: TextSpan(
            text: "Please make sure that the address you are adding is on ",
            style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
            children: [
              TextSpan(
                  text: SettingsData.network,
                  style: TextStyle(color: Networks.get(SettingsData.network)!.color)
              ),
              const TextSpan(
                text: " network",
              ),
            ]
        ),
      ),
    );
  }
}

class QRAlertRecoveryFail extends StatelessWidget {
  const QRAlertRecoveryFail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: RichText(
        text: TextSpan(
            text: "Please make sure that the address you wish to recover is on ",
            style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
            children: [
              TextSpan(
                  text: SettingsData.network,
                  style: TextStyle(color: Networks.get(SettingsData.network)!.color)
              ),
              const TextSpan(
                text: " network, otherwise operation will ",
              ),
              const TextSpan(
                  text: "fail",
                  style: TextStyle(color: Colors.orange)
              ),
            ]
        ),
      ),
    );
  }
}
