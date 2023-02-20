import 'package:bot_toast/bot_toast.dart';
import 'package:candide_mobile_app/config/env.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/screens/home/components/magic_relayer_widget.dart';
import 'package:candide_mobile_app/screens/splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Env.initialize();
  await Hive.initFlutter();
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Stack(
        children: [
          GetMaterialApp(
            title: 'Candide',
            builder: BotToastInit(),
            navigatorObservers: [BotToastNavigatorObserver()],
            debugShowCheckedModeBanner: false,
            theme: AppThemes.darkTheme,
            home: const SplashScreen(),
          ),
          const MagicRelayerWidget(),
        ],
      ),
    );
  }
}