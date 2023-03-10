import 'package:candide_mobile_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RecoverWarningCard extends StatefulWidget {
  final VoidCallback onPressed;
  const RecoverWarningCard({Key? key, required this.onPressed}) : super(key: key);

  @override
  State<RecoverWarningCard> createState() => _RecoverWarningCardState();
}

class _RecoverWarningCardState extends State<RecoverWarningCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        elevation: 10,
        color: const Color(0xFF915911),
        child: InkWell(
          onTap: widget.onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 10,),
                CircleAvatar(
                  maxRadius: 18,
                  backgroundColor: Colors.orangeAccent.withOpacity(0.8),
                  child: const Icon(PhosphorIcons.shieldWarningLight, size: 20, color: Colors.black,)
                ),
                const SizedBox(width: 15,),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Setup account recovery", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
                      const Text("Secure your assets now by adding recovery contacts to your account", style: TextStyle(fontSize: 12),),
                    ],
                  ),
                ),
                const Icon(PhosphorIcons.caretRight, size: 16,),
                const SizedBox(width: 7,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
