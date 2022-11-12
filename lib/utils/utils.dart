import 'dart:math';
import 'dart:typed_data';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:get/get.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:logger/logger.dart';

class Utils {
  static final Logger logger = Logger();

  static void showError({required String title, required String message}){
    DangerAlertBox(
      context: Get.context,
      title: title,
      titleTextColor: Get.theme.colorScheme.primary,
      messageText: message
    );
  }

  static String truncate(String input, {int? trailingDigits}){
    var regex = RegExp('^(0x[a-zA-Z0-9]{6})[a-zA-Z0-9]+([a-zA-Z0-9]{${trailingDigits ?? 6}})\$');
    var matches = regex.allMatches(input);
    if (matches.isEmpty) {
      return input;
    }
    return "${matches.first.group(1)}...${matches.first.group(2)}";
  }

  static bool isValidAddress(String address){
    return RegExp(r"^0x[a-fA-F0-9]{40}$").hasMatch(address);
  }

  static Uint8List randomBytes(int length, {bool secure = false}) {
    assert(length > 0);

    final random = secure ? Random.secure() : Random();
    final ret = Uint8List(length);

    for (var i = 0; i < length; i++) {
      ret[i] = random.nextInt(256);
    }
    return ret;
  }

  static CancelFunc showLoading(){
    return BotToast.showCustomLoading(
      toastBuilder: (CancelFunc func) => const _LoadingWidget(),
    );
  }

  static KeyboardActionsConfig getiOSNumericKeyboardConfig(BuildContext context, FocusNode focusNode){
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
      keyboardBarColor: Colors.grey[200],
      actions: [
        KeyboardActionsItem(
          focusNode: focusNode,
          toolbarButtons: [
            (node) {
              return TextButton.icon(
                onPressed: () => node.unfocus(),
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 8)),
                ),
                label: Text("Done", style: TextStyle(color: Get.theme.colorScheme.onPrimary)),
                icon: Icon(Icons.check, color: Get.theme.colorScheme.onPrimary, size: 15,),
              );
            },
            /*(node) {
              return GestureDetector(
                onTap: () => node.unfocus(),
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                  child: Text(
                    "Done",
                    style: TextStyle(color: Get.theme.colorScheme.onPrimary),
                  ),
                ),
              );
            },*/
          ]
        ),
      ]
    );
  }

}


class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.all(Radius.circular(8))),
      child: CircularProgressIndicator(
        color: Get.theme.colorScheme.primary,
        backgroundColor: Get.theme.colorScheme.onPrimary,
      ),
    );
  }
}