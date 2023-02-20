import 'dart:async';
import 'dart:math';

import 'package:candide_mobile_app/config/network.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:candide_mobile_app/utils/events.dart';
import 'package:candide_mobile_app/utils/utils.dart';
import 'package:candide_mobile_app/services/security.dart';
import 'package:candide_mobile_app/models/recovery_request.dart';
import 'package:candide_mobile_app/screens/components/summary_table.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_dart/contracts/account.dart';
import 'package:wallet_dart/contracts/social_module.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:web3dart/web3dart.dart';

class RecoveryRequestPage extends StatefulWidget {
  final Account account;
  final RecoveryRequest request;
  const RecoveryRequestPage({Key? key, required this.account, required this.request}) : super(key: key);

  @override
  State<RecoveryRequestPage> createState() => _RecoveryRequestPageState();
}

class _RecoveryRequestPageState extends State<RecoveryRequestPage> {
  late RecoveryRequest request;
  bool refreshing = false;
  bool? finalizing; // null = not attempted, true = currently finalizing, false = tried and failed
  int? minimumApprovals;
  List<dynamic>? onChainRecovery;
  List<EthereumAddress> guardians = [];

  Future<void> fetchMinimumSignatures(EthereumAddress accountAddress) async {
    minimumApprovals = (await ISocialModule.interface(address: Networks.selected().socialRecoveryModule, client: Networks.selected().client).threshold(accountAddress)).toInt();
    setState(() {});
  }

  Future<void> getRecoveryRequestOnChain(EthereumAddress accountAddress) async {
    var result = await ISocialModule.interface(address: Networks.selected().socialRecoveryModule, client: Networks.selected().client).getRecoveryRequest(accountAddress);
    if (result[0] == BigInt.zero) return;
    if (result[3][0].toString().toLowerCase() != request.newOwner.toLowerCase()) return;
    setState(() {
      onChainRecovery = result;
    });
  }

  Future<void> getGuardians(EthereumAddress accountAddress) async {
    guardians = await ISocialModule.interface(address: Networks.selected().socialRecoveryModule, client: Networks.selected().client).getGuardians(accountAddress);
    setState(() {});
  }

  Future<void> regainAccess() async {
    widget.account.recoveryId = null;
    await PersistentData.saveAccounts();
    eventBus.fire(OnAccountChange());
    eventBus.fire(OnAccountDataEdit(recovered: true));
    return;
  }

  void refreshData() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    RecoveryRequest? _updatedRequest = (await SecurityGateway.fetchById(request.id!));
    if (_updatedRequest == null){
      setState(() => refreshing = false);
      return;
    }
    request = _updatedRequest;
    bool _isOwner = false;
    await Future.wait([
      fetchMinimumSignatures(EthereumAddress.fromHex(request.accountAddress)),
      getRecoveryRequestOnChain(EthereumAddress.fromHex(request.accountAddress)),
      isOwner().then((value) => _isOwner = value)
    ]);
    setState(() => refreshing = false);
    if (_isOwner){
      await regainAccess();
    }else{
      if (onChainRecovery == null) return;
      checkOwnership(5);
    }
  }

  Future<void> checkOwnership(int seconds) async {
    int executeAfter = onChainRecovery![2].toInt();
    int currentLocalTimestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    if (currentLocalTimestamp < executeAfter){
      Timer(Duration(seconds: seconds), () => checkOwnership(seconds));
      return;
    }
    if (finalizing == null){
      int currentTimestamp = ((await Networks.selected().client.getBlockInformation(blockNumber: 'latest')).timestamp.millisecondsSinceEpoch / 1000).floor();
      if ((currentTimestamp - 15) <= executeAfter){ // let 15 seconds pass to finalization period before finalizing
        Timer(Duration(seconds: seconds), () => checkOwnership(seconds));
        return;
      }
      setState(() {
        finalizing = true;
      });
      bool success = await SecurityGateway.finalize(request.id!);
      if (!success){
        setState(() {
          finalizing = false;
        });
      }else{
        await Future.delayed(const Duration(seconds: 3)); // give time for the node to sync to check for ownership // todo check for delete
      }
    }
    bool _isOwner = await isOwner();
    if (_isOwner){
      await regainAccess();
      return;
    }
    int newSeconds = (seconds * 1.25).floor();
    newSeconds = min(newSeconds, 20);
    Timer(Duration(seconds: seconds), () => checkOwnership(seconds));
  }

  Future<bool> isOwner() async {
    String currentOwner = (await IAccount.interface(address: EthereumAddress.fromHex(request.accountAddress), client: Networks.selected().client).getOwners())[0].hex.toLowerCase();
    if (currentOwner == request.newOwner.toLowerCase()){
      return true;
    }
    return false;
  }

  @override
  void initState() {
    request = widget.request;
    refreshData();
    getGuardians(EthereumAddress.fromHex(request.accountAddress));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: onChainRecovery == null ? Column(
        children: [
          const SizedBox(height: 10,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  text: "Ask your recovery contacts to approve your recovery request on ",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroy, fontSize: 18),
                  children: [
                    TextSpan(
                      text: "security.candidewallet.com",
                      style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          Utils.launchUri("https://security.candidewallet.com/", mode: LaunchMode.externalApplication);
                        }
                    )
                  ]
              ),
            ),
          ),
          const SizedBox(height: 15,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  text: "Ensure you and your recovery contact see matching ",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),
                  children: const [
                    TextSpan(
                      text: "emojis",
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ]
              ),
            ),
          ),
          const SizedBox(height: 10,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Utils.copyText(request.emoji.toString(), message: "Emojis copied to clipboard!"),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Get.theme.cardColor),
                      shape: MaterialStateProperty.all(const ContinuousRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(35)),
                      )),
                      minimumSize: const MaterialStatePropertyAll(Size(0, 45)),
                      overlayColor: MaterialStateProperty.all(Get.theme.colorScheme.primary.withOpacity(0.1)),
                    ),
                    child: Text(
                      request.emoji!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(letterSpacing: 4, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 5,),
                ElevatedButton(
                  onPressed: () {
                    final box = context.findRenderObject() as RenderBox?;
                    Share.share(
                      "Here's my public address: ${widget.request.accountAddress}.\n I need you to approve my recovery request on https://security.candidewallet.com.\nInsure you are approving the same set of emojis ${widget.request.emoji!}",
                      sharePositionOrigin:
                      box!.localToGlobal(Offset.zero) & box.size,
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Get.theme.cardColor),
                    shape: MaterialStateProperty.all(const ContinuousRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(35)),
                    )),
                    minimumSize: const MaterialStatePropertyAll(Size(0, 45)),
                    overlayColor: MaterialStateProperty.all(Get.theme.colorScheme.primary.withOpacity(0.1)),
                  ),
                  child: Icon(PhosphorIcons.shareLight, color: Get.theme.colorScheme.primary, size: 20,),
                )
              ],
            ),
          ),
          const SizedBox(height: 15,),
          Row(
            children: [
              const SizedBox(width: 10,),
              Text("Recovery info", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),),
              const Spacer(),
              IconButton(
                onPressed: refreshData,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 10,),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: SummaryTable(
              entries: [
                SummaryTableEntry(
                  title: "Account address",
                  value: refreshing ? "..." : request.accountAddress,
                ),
                SummaryTableEntry(
                  title: "Recovery status",
                  value: refreshing ? "..." : request.status!,
                ),
                SummaryTableEntry(
                  title: "Minimum approvals",
                  value: refreshing ? "..." : minimumApprovals?.toString() ?? "...",
                ),
              ],
            ),
          ),
          const SizedBox(height: 10,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: _GuardiansSignaturesCard(
              request: request,
              minimumApprovals: minimumApprovals,
              guardians: guardians,
            )
          ),
          const SizedBox(height: 10,),
        ],
      ) : finalizing == true ? Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20,),
          Text("Please wait", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 12, color: Colors.grey),),
          const SizedBox(height: 3,),
          Text("Finalizing recovery...", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 25),),
        ],
      ) : Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "Congrats! Your recovery request has been approved 🎉\n",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18)
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: "A grace period has started.\n",
                style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 18),
                children: [
                  const TextSpan(
                    text: "The recovery will be finalized on\n",
                  ),
                  TextSpan(
                    text: DateFormat("EEE, MMM d, yyyy hh:mm aaa").format(DateTime.fromMillisecondsSinceEpoch(onChainRecovery![2].toInt() * 1000)),
                  ),
                ]
              ),
            ),
          ),
          const SizedBox(height: 15,),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  text: "You'll regain access to the account once it is finalized, understand more about account recovery ",
                  style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 12, color: Colors.grey),
                  children: [
                    TextSpan(
                      text: "here",
                      style: TextStyle(color: Colors.blue.withOpacity(0.7)),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Utils.launchUri("", mode: LaunchMode.externalApplication), // todo add link
                    ),
                  ]
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuardiansSignaturesCard extends StatelessWidget {
  final List<EthereumAddress> guardians;
  final int? minimumApprovals;
  final RecoveryRequest request;
  const _GuardiansSignaturesCard({Key? key, required this.guardians, this.minimumApprovals, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(5),
        child: ExpandablePanel(
          header: Row(
            children: [
              RichText(
                text: TextSpan(
                    text: "Approvals ",
                    style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 15),
                    children: [
                      TextSpan(
                          text: "from ${guardians.length} guardians",
                          style: const TextStyle(fontSize: 12, color: Colors.grey)
                      )
                    ]
                ),
              ),
              const Spacer(),
              Text("${request.signatures.length}/${minimumApprovals ?? "..."}", style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 12, color: Colors.grey),),
            ],
          ),
          collapsed: const SizedBox.shrink(),
          expanded: Column(
            children: [
              for (EthereumAddress guardian in guardians)
                Builder(
                  builder: (context){
                    var signature = request.signatures.firstWhereOrNull((element) => (element[0] as String).toLowerCase() == guardian.hex);
                    bool acquired = signature != null;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: (){
                          Utils.copyText(guardian.hexEip55, message: "Address copied to clipboard!");
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Row(
                            children: [
                              Text(Utils.truncate(guardian.hexEip55), style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, fontSize: 13)),
                              const SizedBox(width: 5,),
                              const Icon(PhosphorIcons.copyLight, size: 14,),
                              const Spacer(),
                              Icon(acquired ? PhosphorIcons.checkBold : PhosphorIcons.xBold, size: 15, color: acquired ? Colors.green : Colors.red,),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
            ],
          ),
          theme: const ExpandableThemeData(
            hasIcon: true,
            iconColor: Colors.white,
            iconSize: 25,
            tapBodyToCollapse: true,
            tapHeaderToExpand: true,
            headerAlignment: ExpandablePanelHeaderAlignment.center,
          ),
        ),
      ),
    );
  }
}

