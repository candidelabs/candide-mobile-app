import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/screens/components/custom_switch.dart';
import 'package:candide_mobile_app/screens/components/painters/outlined_circle_painter.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:wallet_dart/wallet/account.dart';

class ManageNetworksPage extends StatefulWidget {
  const ManageNetworksPage({Key? key}) : super(key: key);

  @override
  State<ManageNetworksPage> createState() => _ManageNetworksPageState();
}

class _ManageNetworksPageState extends State<ManageNetworksPage> {


  Widget getNetworkCard(Network network){
    return _NetworkCard(
      onToggle: (visible) async {
        if (visible){
          PersistentData.hiddenNetworks.remove(network.chainId.toInt());
        }else{
          PersistentData.hiddenNetworks.add(network.chainId.toInt());
        }
        await PersistentData.storeHiddenNetworks();
        setState(() {
          network.visible = visible;
        });
      },
      network: network,
      editable: !network.visible || PersistentData.hiddenNetworks.length < Networks.instances.length - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!Networks.selected().visible){
          int chainId = Networks.instances.firstWhere((element) => element.visible).chainId.toInt();
          Account? account = PersistentData.accounts.firstWhereOrNull((element) => element.chainId == chainId);
          if (account != null){
            PersistentData.selectAccount(address: account.address, chainId: account.chainId);
          }
        }
        eventBus.fire(OnAccountChange());
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Manage networks", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 40,
          leading: Container(
            margin: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[800],
            ),
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              padding: const EdgeInsets.all(0),
              splashRadius: 15,
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(PhosphorIcons.caretLeftBold, size: 17,),
            ),
          ),
        ),
        body: Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (Network network in Networks.instances.where((element) => element.testnetData == null))
                getNetworkCard(network),
              const SizedBox(height: 10,),
              Text("Testnets", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
              for (Network network in Networks.instances.where((element) => element.testnetData != null))
                getNetworkCard(network),
            ],
          ),
        ),
      ),
    );
  }
}


class _NetworkCard extends StatelessWidget {
  final Network network;
  final bool editable;
  final Function(bool) onToggle;
  const _NetworkCard({Key? key, required this.network, required this.editable, required this.onToggle}) : super(key: key);

  int getNetworkAccountsCount(){
    int count = 0;
    for (Account account in PersistentData.accounts){
      if (account.chainId == network.chainId.toInt()){
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    int accountsCount = getNetworkAccountsCount();
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            CustomPaint(
              painter: OutlinedCirclePainter(color: network.color),
              child: CircleAvatar(
                backgroundColor: network.color,
                child: network.logo ?? SvgPicture.asset("assets/images/ethereum.svg", width: 20, color: Colors.white,),
              ),
            ),
            const SizedBox(width: 10,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(network.name, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold),),
                  const SizedBox(height: 1,),
                  Text("You have ${accountsCount == 0 ? "no" : accountsCount} account${accountsCount == 1 ? "" : "s"} on this\nnetwork", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            AnimatedContainer(
              width: 44,
              height: 21,
              decoration: BoxDecoration(
                color: editable ? Colors.transparent : Colors.blueAccent,
                borderRadius: BorderRadius.circular(25)
              ),
              duration: const Duration(milliseconds: 250),
              child: Stack(
                children: [
                  AnimatedOpacity(
                    opacity: !editable ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Center(child: Icon(PhosphorIcons.lock, size: 15,)),
                  ),
                  AnimatedOpacity(
                    opacity: editable ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: CustomSwitch(
                      onChanged: editable ? onToggle : (_){},
                      activeColor: Colors.blueAccent,
                      inactiveColor: Colors.grey[850],
                      value: network.visible,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
