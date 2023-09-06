import 'package:flutter/material.dart';

class CustomCheckboxListTile extends StatelessWidget {
  final bool value;
  final Widget title;
  final Widget? subtitle;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? contentPadding;
  final ValueChanged<bool?> onChanged;
  const CustomCheckboxListTile({Key? key, required this.value, required this.title, this.subtitle, this.shape, this.contentPadding, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListTileTheme(
        horizontalTitleGap: 2,
        child: CheckboxListTile(
          onChanged: onChanged,
          value: value,
          activeColor: Colors.blue,
          contentPadding: contentPadding ?? EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          dense: true,
          shape: shape,
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6)
          ),
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }
}
