import 'package:walletconnect_dart/walletconnect_dart.dart';

class SponsorData {
  bool sponsored;
  PeerMeta? sponsorMeta;

  SponsorData({required this.sponsored, this.sponsorMeta});
}