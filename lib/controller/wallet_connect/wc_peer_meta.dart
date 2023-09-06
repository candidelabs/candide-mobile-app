import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:walletconnect_flutter_v2/apis/core/pairing/utils/pairing_models.dart';

class WCPeerMeta {
  final String url;
  final String name;
  final String description;
  final List<String>? icons;

  const WCPeerMeta({required this.url, required this.name, required this.description, this.icons});

  factory WCPeerMeta.fromPeerMeta(PeerMeta? peerMeta) =>
      WCPeerMeta(
        name: peerMeta?.name ?? "Unknown",
        url: peerMeta?.url ?? "",
        description: peerMeta?.description ?? "",
        icons: peerMeta?.icons,
      );

  factory WCPeerMeta.fromPairingMetadata(PairingMetadata? pairingMetadata) =>
      WCPeerMeta(
        name: pairingMetadata?.name ?? "Unknown",
        url: pairingMetadata?.url ?? "",
        description: pairingMetadata?.description ?? "",
        icons: pairingMetadata?.icons,
      );

  factory WCPeerMeta.fromJson(Map metadata) =>
      WCPeerMeta(
        name: metadata["name"] ?? "Unknown",
        url: metadata["url"] ?? "",
        description: metadata["description"] ?? "",
        icons: (metadata["icons"] as List<dynamic>).cast<String>(),
      );

  @override
  String toString() {
    return 'WCPeerMeta{url: $url, name: $name, description: $description, icons: $icons}';
  }
}