import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/wallet_connect_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class WCScanSheet extends StatefulWidget {
  final Function(String) onScanResult;
  const WCScanSheet({Key? key, required this.onScanResult}) : super(key: key);

  @override
  State<WCScanSheet> createState() => _WCScanSheetState();
}

class _WCScanSheetState extends State<WCScanSheet> {
  final GlobalKey _qrKey = GlobalKey();
  Barcode? result;
  QRViewController? controller;

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    //controller.resumeCamera();
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code == null) return;
      String uri = scanData.code!;
      if (uri.startsWith("wc:")) {
        controller.dispose();
        Get.back();
        widget.onScanResult(uri);
      }else{
        BotToast.showText(
          text: "Invalid wallet connect URI",
          contentColor: Colors.red,
          align: Alignment.topCenter,
          textStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double exactCenter = (constraints.constrainWidth() / 2 - 25 / 2);
        return Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  QRView(
                    key: _qrKey,
                    overlay: QrScannerOverlayShape(
                      borderColor: Get.theme.colorScheme.primary,
                      overlayColor: Colors.black.withOpacity(0.8),
                      borderRadius: 25,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: Get.width * 0.8
                    ),
                    onQRViewCreated: _onQRViewCreated,
                  ),
                  Positioned(
                    top: 0,
                    child: Container(
                      width: Get.width,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: Colors.black45,
                      child: Center(
                        child: Text("Scan to connect", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),)
                      )
                    )
                  ),
                  Positioned(
                    bottom: Get.height * 0.10,
                    child: Column(
                      children: [
                        Card(
                          color: Get.theme.colorScheme.primary.withOpacity(0.5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: Text("${WalletConnectController.instances.length} connections", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
                          ),
                        ),
                        const SizedBox(height: 10,),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: exactCenter - 120,
                              child: Icon(Icons.chevron_left, color: Get.theme.colorScheme.primary.withOpacity(0.75))
                            ),
                            Positioned(
                                left: exactCenter - 110,
                                child: Icon(Icons.chevron_left, color: Get.theme.colorScheme.primary.withOpacity(0.5))
                            ),
                            Positioned(
                                left: exactCenter - 100,
                                child: Icon(Icons.chevron_left, color: Get.theme.colorScheme.primary.withOpacity(0.25))
                            ),
                            Positioned(
                              left: exactCenter - 75,
                              child: Text("Swipe left to view connections", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.primary.withOpacity(0.25)),),
                            ),
                            SizedBox(width: constraints.constrainWidth(), height: 25,),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }
}
