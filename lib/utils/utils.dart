import 'dart:convert';
import 'dart:math';

import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/components/error_alert_dialog.dart';
import 'package:eth_sig_util/util/keccak.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static final Logger logger = Logger();

  static void printWrapped(String text) {
    final pattern = new RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
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
    String result = "${matches.first.group(1)}...${matches.first.group(2)}";
    result = utf8.decode(result.codeUnits, allowMalformed: true);
    result = result.replaceAll('\uFFFD', "");
    return result;
  }

  static bool _isUpperCase(String s) {
    return s == s.toUpperCase();
  }

  static String camelCaseToLowerUnderscore(String s) {
    var sb = StringBuffer();
    var first = true;
    String? lastChar;
    for (var rune in s.runes) {
      var char = String.fromCharCode(rune);
      if (_isUpperCase(char) && !first) {
        if (char != '_') {
          if (lastChar != null && !_isUpperCase(lastChar)){
            sb.write('_');
          }
        }
        sb.write(char.toLowerCase());
      } else {
        if (lastChar != null && _isUpperCase(lastChar) && sb.toString()[sb.length-2] != "_"){
          String _temp = sb.toString().substring(0, sb.length-1);
          _temp += "_$lastChar";
          sb = StringBuffer(_temp);
        }
        first = false;
        sb.write(char.toLowerCase());
      }
      lastChar = char;
    }
    return sb.toString();
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

  static void copyText(String text, {String? message}) {
    Clipboard.setData(ClipboardData(text: text));
    BotToast.showText(
      text: message ?? "Copied to clipboard!",
      textStyle: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.black),
      contentColor: Get.theme.colorScheme.primary,
      align: Alignment.topCenter,
    );
  }

  static Future<void> launchUri(String url, {LaunchMode mode = LaunchMode.externalApplication}) async {
    var launchable = await canLaunchUrl(Uri.parse(url));
    if(launchable) {
      await launchUrl(Uri.parse(url), mode: mode);
    } else {
      throw("URL can't be launched.");
    }
  }

  static void showError({required String title, required String message, List<String> urls = const []}){
    Map<String, String?> tokens = {}; // key = message, value = link url (if value is empty or null then key is normal text)
    //
    RegExp regex = RegExp(r"\[(.*?)\]\((.*?)\)");
    Iterable<Match> matches = regex.allMatches(message);

    int lastIndex = 0;
    for (Match match in matches) {
      String prefix = message.substring(lastIndex, match.start);
      String label = match.group(1)!;
      String url = match.group(2)!;
      tokens[prefix] = null;
      tokens[label] = url;
      lastIndex = match.end;
    }
    String suffix = message.substring(lastIndex);
    tokens[suffix] = null;
    //
    ErrorAlertDialog(
      context: Get.context,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Get.theme.colorScheme.primary)),
      iconColor: Get.theme.colorScheme.primary,
      content: RichText(
        text: TextSpan(
          //text: message,
          children: [
            for (MapEntry<String, String?> entry in tokens.entries)
              entry.value != null && entry.value!.trim().isNotEmpty ? TextSpan(
                text: entry.key,
                style: const TextStyle(color: Colors.blue),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Utils.launchUri(entry.value!, mode: LaunchMode.externalApplication),
              ) : TextSpan(
                text: entry.key,
              )
          ]
        ),
      ),
    );
  }

  static CancelFunc showLoading(){
    return BotToast.showCustomLoading(
      toastBuilder: (CancelFunc func) => const _LoadingWidget(),
    );
  }

  static void showBottomStatus(
      String text,
      String description,
      {bool? loading, bool? success, VoidCallback? onClick, Duration duration = const Duration(seconds: 3)}
    ){
    Widget leading;
    if (loading ?? false){
     leading = Transform.scale(
       scale: 0.75,
       child: const CircularProgressIndicator(strokeWidth: 5,),
     );
    }else{
      if (success ?? true){
        leading = const Icon(Icons.check_circle_outline_rounded, size: 30, color: Colors.green,);
      }else{
        leading = const Icon(Icons.error_outline_rounded, size: 30, color: Colors.red,);
      }
    }
    BotToast.showCustomText(
      toastBuilder: (cancel){
        return Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: (){
                cancel();
                onClick?.call();
              },
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  leading,
                  const SizedBox(width: 10,),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(text, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold)),
                        const SizedBox(height: 3,),
                        Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      crossPage: true,
      duration: duration,
      align: const Alignment(0.0, 0.95),
      onlyOne: true,
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