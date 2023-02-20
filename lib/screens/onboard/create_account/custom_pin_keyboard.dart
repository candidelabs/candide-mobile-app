import 'package:candide_mobile_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CustomPinKeyboard extends StatefulWidget {
  final bool showFingerprintAction;
  final Function(String) onKeyPress;
  const CustomPinKeyboard({Key? key, required this.onKeyPress, required this.showFingerprintAction}) : super(key: key);

  @override
  State<CustomPinKeyboard> createState() => _CustomPinKeyboardState();
}

class _CustomPinKeyboardState extends State<CustomPinKeyboard> {
  final List<List<String>> keyboardLayout = [
    ["1", "2", "3"],
    ["4", "5", "6"],
    ["7", "8", "9"],
    ["",  "0", "action:backspace"],
  ];

  @override
  void initState() {
    if (widget.showFingerprintAction){
      keyboardLayout[3][2] = "action:fingerprint";
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showFingerprintAction){
      keyboardLayout[3][2] = "action:fingerprint";
    }else{
      keyboardLayout[3][2] = "action:backspace";
    }
    return Column(
      children: [
        for (List<String> row in keyboardLayout)
          Row(
            children: [
              for (String key in row)
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 4.75/3,
                    child: Builder(
                      builder: (context){
                        if (key.startsWith("action")){
                          String action = key.split(":")[1];
                          IconData iconData = PhosphorIcons.backspace; // default
                          if (action == "fingerprint"){
                            iconData = PhosphorIcons.fingerprint;
                          }
                          return IconButton(
                            onPressed: () => widget.onKeyPress.call(key),
                            icon: Icon(iconData),
                          );
                        }
                        return TextButton(
                          onPressed: () => widget.onKeyPress.call(key),
                          child: Text(key, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),),
                        );
                      },
                    ),
                  ),
                )
            ],
          )
      ],
    );
  }
}
