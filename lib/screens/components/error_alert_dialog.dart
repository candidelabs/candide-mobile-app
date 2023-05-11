import 'package:flutter/material.dart';

class ErrorAlertDialog {
  final BuildContext? context;
  final Widget title;
  final IconData? icon;
  final Widget content;
  final Color? iconColor;
  final Color? messageTextColor;
  final Color? buttonColor;
  final Color? buttonTextColor;
  final String? buttonText;
  ErrorAlertDialog(
      {this.context,
        required this.title,
        required this.content,
        this.iconColor,
        this.messageTextColor,
        this.buttonColor,
        this.buttonText,
        this.buttonTextColor,
        this.icon}) {
    showDialog(
      barrierDismissible: false,
      context: context!,
      builder: (BuildContext context) {
        return SimpleDialog(
          shape: const Border(left: BorderSide(width: 2, color: Color(0xFFFF5455))),
          title: Row(
            children: <Widget>[
              Icon(Icons.error, color: iconColor ?? const Color(0xFFFF5455)),
              const SizedBox(width: 4.0,),
              Flexible(
                child: title,
              )
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          children: <Widget>[
            content,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(buttonColor ?? const Color(0xFFFF5455))
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    buttonText ?? "Close",
                    style: TextStyle(color: buttonTextColor ?? Colors.white),
                  ),
                )
              ],
            )
          ],
        );
      }
    );
  }
}