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
          Text("You got a Reward!", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),),
          const SizedBox(height: 20,),          
          Image.asset("assets/images/zerofee_pass.png" , height: 300),
          const SizedBox(height: 10,),
          const SizedBox(height: 5,),
          const Text(
            "Your sense of exploration unlocked a valuable ZeroFee Pass, granting you a feeless transaction. Enjoy the freedom to transact without worrying about gas fees!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 35,),
        ],
      ),
    );
  }
}
