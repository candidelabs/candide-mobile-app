import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/screens/home/settings/developer_settings/manage_networks_page.dart';
import 'package:candide_mobile_app/screens/onboard/create_account/create_account_main_screen.dart';
import 'package:candide_mobile_app/screens/onboard/recovery/recover_account_sheet.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/guardian_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class InvisibleAccountsScreen extends StatefulWidget {
  const InvisibleAccountsScreen({Key? key}) : super(key: key);

  @override
  State<InvisibleAccountsScreen> createState() => _InvisibleAccountsScreenState();
}

class _InvisibleAccountsScreenState extends State<InvisibleAccountsScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          CircleAvatar(
            backgroundColor: Colors.grey[900],
            maxRadius: 40,
            child: const Icon(PhosphorIcons.wallet, size: 35,),
          ),
          const SizedBox(height: 25,),
          const Text("You have no accounts on enabled networks.", textAlign: TextAlign.center),
          const Text("However, you have some on disabled networks.", textAlign: TextAlign.center),
          const SizedBox(height: 15,),
          ElevatedButton(
            onPressed: (){
              Get.to(CreateAccountMainScreen(baseAccount: PersistentData.selectedAccount));
            },
            style: ButtonStyle(
              shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              )),
            ),
            child: const Text("Create account"),
          ),
          ElevatedButton(
            onPressed: () async {
              var result = await showBarModalBottomSheet(
                context: context,
                backgroundColor: Get.theme.canvasColor,
                builder: (context) {
                  Get.put<ScrollController>(ModalScrollController.of(context)!, tag: "recovery_account_modal");
                  return const RecoverAccountSheet(
                      method: "social-recovery",
                      onNext: GuardianRecoveryHelper.setupRecoveryAccount
                  );
                },
              );
              if (result == true){
                Get.back(result: true);
                eventBus.fire(OnAccountChange());
              }
            },
            style: ButtonStyle(
              shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              )),
              backgroundColor: MaterialStateProperty.all<Color>(Get.theme.cardColor),
            ),
            child: Text("Recover account", style: TextStyle(color: Get.theme.colorScheme.primary),),
          ),
          const Spacer(),
          Material(
            child: InkWell(
              onTap: (){
                Get.to(const ManageNetworksPage());
              },
              child: Container(
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  border: Border(
                    top: BorderSide(color: Colors.black38)
                  )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(PhosphorIcons.eye, size: 20, color: Colors.grey),
                    SizedBox(width: 10,),
                    Text("Manage networks", style: TextStyle(color: Colors.grey),),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
