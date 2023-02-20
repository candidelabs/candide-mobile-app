import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:wallet_dart/wallet/account.dart';
import 'package:wallet_dart/wallet/encrypted_signer.dart';
import 'package:web3dart/credentials.dart';

class SignersController {
  Map<String, EthPrivateKey> privateKeys = {};
  static int secondsBeforeClear = 30; // todo implement
  static SignersController instance = SignersController();

  EncryptedSigner? getSignerFromId(String id){
    return PersistentData.walletSigners[id];
  }

  List<EncryptedSigner?> getSignersFromAccount(Account account){
    List<EncryptedSigner?> result = [];
    for (String id in account.signersIds){
      result.add(PersistentData.walletSigners[id]);
    }
    return result;
  }

  List<EthereumAddress> getSignersAddressesFromAccount(Account account){
    List<EthereumAddress> result = [];
    for (String id in account.signersIds){
      if (PersistentData.walletSigners[id] == null) continue;
      result.add(PersistentData.walletSigners[id]!.publicAddress);
    }
    return result;
  }

  EthPrivateKey? getPrivateKeyFromSignerId(String id){
    return privateKeys[id];
  }

  List<EthPrivateKey?> getPrivateKeysFromAccount(Account account){
    List<EthPrivateKey?> result = [];
    for (String id in account.signersIds){
      result.add(privateKeys[id]);
    }
    return result;
  }

  void storePrivateKey(String signerId, EthPrivateKey privateKey){ // temporarily keeps private key in memory for `secondsBeforeClear` for auto-signing future session transactions
    privateKeys[signerId] = privateKey;
  }

  void clearPrivateKeys(){
    privateKeys.clear();
  }

}