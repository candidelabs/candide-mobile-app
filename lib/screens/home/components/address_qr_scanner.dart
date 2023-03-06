import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class AddressQRScanner extends StatefulWidget {
  final Function(String) onScanAddress;
  final Widget alertWidget;
  const AddressQRScanner({Key? key, required this.onScanAddress, required this.alertWidget}) : super(key: key);

  @override
  State<AddressQRScanner> createState() => _AddressQRScannerState();
}

class _AddressQRScannerState extends State<AddressQRScanner> with WidgetsBindingObserver {
  final GlobalKey _qrKey = GlobalKey();
  Barcode? result;
  QRViewController? controller;
  bool? cameraPermissionDenied;

  _permissionRequest() async {
    var permissionResult = await Permission.camera.request();
    if (permissionResult.isDenied || permissionResult.isPermanentlyDenied) {
      cameraPermissionDenied = true;
    }else{
      cameraPermissionDenied = false;
    }
    setState(() {});
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.resumeCamera();
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code == null) return;
      var address = "";
      if (scanData.code!.contains(':')) {
        address = scanData.code!.split(":")[1];
      } else {
        address = scanData.code!;
      }

      if (Utils.isValidAddress(address)) {
        controller.dispose();
        Get.back();
        widget.onScanAddress(address);
      }else{
        BotToast.showText(
          text: "Invalid address",
          contentColor: Colors.red,
          align: Alignment.topCenter,
          textStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _permissionRequest();
        break;
      default: break;
    }
  }

  @override
  void initState() {
    _permissionRequest();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
                    cameraPermissionDenied == null ? const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: CircularProgressIndicator()
                    ) : cameraPermissionDenied! ? Container(
                      height: Get.height * 0.65,
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(PhosphorIcons.warning, size: 40, color: Colors.amber,),
                          const SizedBox(height: 10,),
                          const Text(
                            "We need your permission to use the camera in order to be able to scan a QR Address",
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20,),
                          const Text(
                            "You need to give this permission from the system settings",
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10,),
                          ElevatedButton(
                            onPressed: () => openAppSettings(),
                            child: Text("Open settings" ,style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold)),
                          )
                        ],
                      ),
                    ) : Expanded(
                      child: QRView(
                        key: _qrKey,
                        onQRViewCreated: _onQRViewCreated,
                      ),
                    ),
                    !(cameraPermissionDenied ?? true) ? widget.alertWidget : const SizedBox.shrink(),
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
                  text: Networks.selected().name,
                  style: TextStyle(color: Networks.selected().color)
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
                  text: Networks.selected().name,
                  style: TextStyle(color: Networks.selected().color)
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
                  text: Networks.selected().name,
                  style: TextStyle(color: Networks.selected().color)
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
