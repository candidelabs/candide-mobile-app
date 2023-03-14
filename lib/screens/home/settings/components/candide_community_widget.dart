import 'package:candide_mobile_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class CandideCommunityWidget extends StatelessWidget {
  const CandideCommunityWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)
      ),
      color: Get.theme.cardColor,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xff7289da),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: IconButton(
                  onPressed: () => Utils.launchUri("https://discord.gg/QQ6R9Ac5ah"),
                  icon: const Icon(Icons.discord, color: Colors.white,),
                ),
              ),
            ),
            const SizedBox(width: 10,),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xff1DA1F2),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: IconButton(
                  onPressed: () => Utils.launchUri("https://twitter.com/candidewallet"),
                  icon: const Icon(FontAwesomeIcons.twitter, color: Colors.white, size: 22,),
                ),
              ),
            ),
            const SizedBox(width: 10,),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xff333333),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: IconButton(
                  onPressed: () => Utils.launchUri("https://github.com/candidelabs"),
                  icon: const Icon(FontAwesomeIcons.github, color: Colors.white, size: 22,),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}