import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';

class SummaryTable extends StatelessWidget {
  final List<SummaryTableEntry> entries;
  const SummaryTable({Key? key, required this.entries}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              for (SummaryTableEntry entry in entries)
                entry,
            ],
          ),
        ),
      ),
    );
  }
}

class SummaryTableEntry extends StatelessWidget {
  final String title;
  final TextStyle? titleStyle;
  final String value;
  final TextStyle? valueStyle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPress;
  const SummaryTableEntry({Key? key, required this.title, required this.value, this.leading, this.trailing, this.onPress, this.titleStyle, this.valueStyle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPress,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            const SizedBox(width: 5,),
            leading ?? const SizedBox.shrink(),
            Text(title, style: titleStyle ?? TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.grey),),
            const Spacer(),
            Text(Utils.truncateIfAddress(value), style: valueStyle ?? TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.white),),
            trailing ?? const SizedBox.shrink(),
            const SizedBox(width: 5,),
          ],
        ),
      ),
    );
  }
}

