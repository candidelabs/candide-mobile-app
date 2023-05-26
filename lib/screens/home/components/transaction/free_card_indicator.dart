import 'package:candide_mobile_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class FreeCardIndicator extends StatelessWidget {
  const FreeCardIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.green.withOpacity(0.2),
      color: Colors.green.withOpacity(0.2),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(
              color: Colors.green,
              width: 1.2
          )
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(PhosphorIcons.lightningBold, size: 15,),
            const SizedBox(width: 5,),
            Text("FREE", textAlign: TextAlign.center, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
          ],
        ),
      ),
    );
  }
}