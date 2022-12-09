import 'dart:math';

import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:eth_sig_util/util/keccak.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:get/get.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:logger/logger.dart';

class Utils {
  static final Logger logger = Logger();

  static void copyText(String text, {String? message}) {
    Clipboard.setData(ClipboardData(text: text));
    BotToast.showText(
        text: message ?? "Copied to clipboard!",
        textStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.black),
        contentColor: Get.theme.colorScheme.primary,
        align: Alignment.topCenter,
    );
  }

  static void showError({required String title, required String message}){
    DangerAlertBox(
      context: Get.context,
      title: title,
      titleTextColor: Get.theme.colorScheme.primary,
      messageText: message
    );
  }
  static String truncateIfAddress(String input, {int? leadingDigits, int? trailingDigits}){
    var regex = RegExp('^(0x[a-zA-Z0-9]{${trailingDigits ?? 6}})[a-zA-Z0-9]+([a-zA-Z0-9]{${trailingDigits ?? 6}})\$');
    var matches = regex.allMatches(input);
    if (matches.isEmpty) {
      return input;
    }
    return "${matches.first.group(1)}...${matches.first.group(2)}";
  }

  static String truncate(String input, {int? leadingDigits, int? trailingDigits}){
    var regex = RegExp('^((?:0x)?.{${leadingDigits ?? 6}}).+(.{${trailingDigits ?? 6}})\$');
    var matches = regex.allMatches(input);
    if (matches.isEmpty) {
      return input;
    }
    return "${matches.first.group(1)}...${matches.first.group(2)}";
  }

  static bool _isChecksumAddress(String address){
    address = address.replaceAll('0x','');
    var addressHash = bytesToHex(keccakAscii(address.toLowerCase()));
    for (var i = 0; i < 40; i++ ) {
      if ((int.parse(addressHash[i], radix: 16) > 7 && address[i].toUpperCase() != address[i]) ||
          (int.parse(addressHash[i], radix: 16) <= 7 && address[i].toLowerCase() != address[i])) {
        return false;
      }
    }
    return true;
  }

  static bool isValidAddress(String address){
    if (!RegExp(r"^(0x)?[0-9a-fA-F]{40}$").hasMatch(address)) return false; // check basic conditions
    if (RegExp(r"^(0x)?[a-f0-9]{40}$").hasMatch(address)) return true; // check all lowercase
    if (RegExp(r"^(0x)?[A-F0-9]{40}$").hasMatch(address)) return true; // check all uppercase
    return _isChecksumAddress(address); // check checksum address
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

class Tuple<T1, T2> {
  final T1 a;
  final T2 b;

  Tuple({
    required this.a,
    required this.b,
  });

  factory Tuple.fromJson(Map<String, dynamic> json) {
    return Tuple(
      a: json['a'],
      b: json['b'],
    );
  }
}