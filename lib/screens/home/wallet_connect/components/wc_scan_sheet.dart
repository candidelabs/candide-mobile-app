import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/theme.dart';
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
    controller.resumeCamera();
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
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        QRView(
                          key: _qrKey,
                          overlay: QrScannerOverlayShape(
                            borderColor: Get.theme.colorScheme.primary,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
