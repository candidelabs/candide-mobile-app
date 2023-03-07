import 'package:flutter/material.dart';

Future<bool> confirm(
  BuildContext context, {
  Widget? title,
  required Widget content,
  Widget? confirm,
  Widget? cancel,
}) async {
  final bool? isConfirm = await showDialog<bool>(
    context: context,
    useRootNavigator: false,
    builder: (_) => WillPopScope(
      child: AlertDialog(
        title: title,
        content: content,
        actions: <Widget>[
          TextButton(
            child: cancel ?? const Text('No'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: confirm ?? const Text('Yes'),
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
