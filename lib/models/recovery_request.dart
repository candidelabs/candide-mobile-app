class RecoveryRequest {
  String? id;
  String? emoji;
  String walletAddress;
  String socialRecoveryAddress;
  String oldOwner;
  String newOwner;
  String network;
  String? status;
  int? signaturesAcquired;
  DateTime? createdAt;

  RecoveryRequest(
      {this.id,
      this.emoji,
      required this.walletAddress,
      required this.socialRecoveryAddress,
      required this.oldOwner,
      required this.newOwner,
      required this.network,
      this.status,
      this.signaturesAcquired,
      this.createdAt});

  RecoveryRequest.fromJson(Map json)
      : id = json['id'],
        emoji = json['emoji'],
        walletAddress = json['walletAddress'],
        socialRecoveryAddress = json['socialRecoveryAddress'],
        oldOwner = json['oldOwner'],
        newOwner = json['newOwner'],
        network = json['network'],
        status = json['status'],
        signaturesAcquired = json['signaturesAcquired'],
        createdAt = json['createdAt'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'emoji': emoji,
    'walletAddress': walletAddress,
    'socialRecoveryAddress': socialRecoveryAddress,
    'oldOwner': oldOwner,
    'newOwner': newOwner,
    'network': network,
    'status': status,
    'signaturesAcquired': signaturesAcquired,
    'createdAt': createdAt,
  };
}