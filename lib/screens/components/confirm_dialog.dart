import 'package:flutter/material.dart';

Future<bool> confirm(
  BuildContext context, {
  Widget? title,
  Widget? content,
  Widget? textYes,
  Widget? textNo,
}) async {
  final bool? isConfirm = await showDialog<bool>(
    context: context,
    useRootNavigator: false,
    builder: (_) => WillPopScope(
      child: AlertDialog(
        title: title,
        content: content ?? const Text('Are you sure continue?'),
        actions: <Widget>[
          TextButton(
            child: textNo ?? const Text('No'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: textYes ?? const Text('Yes'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
      onWillPop: () async {
        Navigator.pop(context, false);
        return true;
      },
    ),
  );

  return isConfirm ?? false;
}
