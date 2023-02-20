class RecoveryRequest {
  String? id;
  String? emoji;
  String accountAddress;
  String newOwner;
  String network;
  String? status;
  List<dynamic> signatures;
  DateTime? createdAt;

  RecoveryRequest(
      {this.id,
      this.emoji,
      required this.accountAddress,
      required this.newOwner,
      required this.network,
      this.status,
      required this.signatures,
      this.createdAt});

  RecoveryRequest.fromJson(Map json)
      : id = json['id'],
        emoji = json['emoji'],
        accountAddress = json['accountAddress'],
        newOwner = json['newOwner'],
        network = json['network'],
        status = json['status'],
        signatures = json['signatures'],
        createdAt = json['createdAt'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'emoji': emoji,
    'accountAddress': accountAddress,
    'newOwner': newOwner,
    'network': network,
    'status': status,
    'signatures': signatures,
    'createdAt': createdAt,
  };
}