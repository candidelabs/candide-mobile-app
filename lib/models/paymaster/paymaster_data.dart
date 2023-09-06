import 'package:candide_mobile_app/controller/wallet_connect/wc_peer_meta.dart';
import 'package:web3dart/credentials.dart';

class PaymasterMetadata {
  WCPeerMeta? peerMeta;
  EthereumAddress address;
  String sponsoredEventTopic;
  late String dummyPaymasterAndData;

  PaymasterMetadata({this.peerMeta, required this.address, required this.sponsoredEventTopic, String? dummyPaymasterAndData}){
    this.dummyPaymasterAndData = dummyPaymasterAndData ?? "0x${address.hexNo0x}7ddefa2f027691116d0a7aa6418246622d70b12a0100000000ffff000000000000000000000000000000000000000000000000000000000000ffff000000000000000000000000000000000000000000000000000000000000ffff010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101011c";
  }
}