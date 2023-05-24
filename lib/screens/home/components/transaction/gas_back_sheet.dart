import 'package:animated_emoji/animated_emoji.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:flutter/material.dart';

class GasBackSheet extends StatelessWidget {
  const GasBackSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          const SizedBox(height: 20,),
          const AnimatedEmoji(
            AnimatedEmojis.partyingFace,
            size: 85,
          ),
          const SizedBox(height: 10,),
          Text("Congratulations!", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 22),),
          const SizedBox(height: 5,),
          const Text(
            "You're quite the explorer!\nYou just earned a special gift, a FREE transaction.\nEnjoy fee-free transactions and keep exploring!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 35,),
        ],
      ),
    );
  }
}
