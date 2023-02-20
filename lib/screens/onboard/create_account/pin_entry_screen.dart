import 'dart:async';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/onboard/create_account/custom_pin_keyboard.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:pinput/pinput.dart';

class PinEntryScreen extends StatefulWidget {
  final bool showLogo;
  final String promptText;
  final bool confirmMode;
  final String confirmText;
  final bool showBiometricsToggle;
  final VoidCallback? onBack;
  final Function(String, bool) onPinEnter;
  const PinEntryScreen({Key? key, required this.showLogo, required this.promptText, this.confirmText = "", this.showBiometricsToggle = false, required this.confirmMode, required this.onPinEnter, this.onBack}) : super(key: key);

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final TextEditingController pinController = TextEditingController();
  final GlobalKey<FormState> pinFormKey = GlobalKey<FormState>();
  late StreamSubscription pinErrorSubscription;
  //
  final PinTheme defaultPinTheme = PinTheme(
    width: 10,
    height: 10,
    textStyle: const TextStyle(color: Colors.transparent),
    decoration: BoxDecoration(
      color: Get.theme.colorScheme.primary.withOpacity(0.25),
      border: Border.all(color: Colors.transparent),
      borderRadius: BorderRadius.circular(40),
    ),
  );
  String pin = "";
  String error = "";
  bool showBiometricsUsage = false;
  bool showBiometricsToggle = false;
  bool useBiometrics = false;
  bool confirming = false;

  Future<String?> _getPasswordThroughBiometrics() async {
    try{
      final store = await BiometricStorage().getStorage('auth_data');
      String? password = await store.read();
      return password;
    } on AuthException catch(_) {
      return null;
    }
  }

  Future<void> startBiometric() async {
    String? password = await _getPasswordThroughBiometrics();
    if (password == null){
      return;
    }else{
      if (password.length > 6) return;
      if (!password.isNumericOnly) return;
      pinController.clear();
      pinController.append(password, 6);
    }
  }

  Future<void> initBiometricsState() async {
    var response = await BiometricStorage().canAuthenticate();
    if (response != CanAuthenticateResponse.success) return;
    if (widget.showBiometricsToggle){
      useBiometrics = true;
      setState(() => showBiometricsToggle = true);
      return;
    }
    var biometricsEnabled = Hive.box("settings").get("biometrics_enabled");
    if (biometricsEnabled){
      setState(() {
        useBiometrics = true;
      });
      startBiometric();
    }
  }
  @override
  void initState() {
    initBiometricsState();
    pinErrorSubscription = eventBus.on<OnPinErrorChange>().listen((event) {
      if (!mounted) return;
      pinController.clear();
      setState(() {
        error = event.error;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    pinErrorSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            widget.onBack != null ? Container(
              margin: const EdgeInsets.only(left: 15, top: 10),
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ) : const SizedBox(height: 20,),
            const SizedBox(height: 10,),
            widget.showLogo ? Container(
              margin: const EdgeInsets.only(bottom: 25),
              child: SvgPicture.asset(
                "assets/images/logo_cropped.svg",
                width: Get.width * 0.30,
                color: Get.theme.primaryColor,
              ),
            ) : const SizedBox.shrink(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(!confirming ? widget.promptText : widget.confirmText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 25),)
            ),
            const SizedBox(height: 35,),
            Form(
              key: pinFormKey,
              child: Pinput(
                controller: pinController,
                defaultPinTheme: defaultPinTheme,
                submittedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration?.copyWith(
                    color: Get.theme.colorScheme.primary,
                  ),
                ),
                separator: const SizedBox(width: 25,),
                length: 6,
                autofocus: false,
                useNativeKeyboard: false,
                obscureText: true,
                showCursor: false,
                onChanged: (_) => setState(() {}),
                onCompleted: (_pin) {
                  if (confirming){
                    if (_pin != pin){
                      setState(() {
                        error = "PINs don't match, try again";
                        pin = "";
                        confirming = false;
                      });
                    }else{
                      widget.onPinEnter(pin, useBiometrics);
                      return;
                    }
                  }else{
                    pin = _pin;
                    if (widget.confirmMode){
                      setState(() {
                        confirming = true;
                        error = "";
                      });
                    }else{
                      widget.onPinEnter(pin, useBiometrics);
                      return;
                    }
                  }
                  pinController.clear();
                },
                pinputAutovalidateMode: PinputAutovalidateMode.disabled,
              ),
            ),
            error.isNotEmpty ? Container(
              margin: const EdgeInsets.only(top: 25),
              child: Text(error, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.red[900]),)
            ) : const SizedBox.shrink(),
            const Spacer(),
            showBiometricsToggle ? SwitchListTile(
              onChanged: (bool? val){
                setState(() => useBiometrics = (val ?? false));
              },
              value: useBiometrics,
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(PhosphorIcons.fingerprint, size: 27),
                  const SizedBox(width: 10,),
                  Text("Use biometrics to log in", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, height: 1.5),),
                ],
              ),
              activeColor: Colors.blue,
            ) : const SizedBox.shrink(),
            const Divider(thickness: 0.75),
            CustomPinKeyboard(
              showFingerprintAction: useBiometrics && !showBiometricsToggle && pinController.text.isEmpty,
              onKeyPress: (String key){
                if (key.startsWith("action")){
                  String action = key.split(":")[1];
                  if (action == "backspace"){
                    pinController.delete();
                    return;
                  }else if (action == "fingerprint"){
                    startBiometric();
                    return;
                  }
                }
                pinController.append(key, 6);
              },
            ),
          ],
        ),
      ),
    );
  }
}
