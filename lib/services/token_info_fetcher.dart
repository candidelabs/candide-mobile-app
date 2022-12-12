import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:candide_mobile_app/utils/constants.dart';
import 'package:wallet_dart/contracts/factories/ERC20.g.dart';
import 'package:web3dart/credentials.dart';

class TokenInfoFetcher {

  static Future<TokenInfo?> fetchTokenInfo(String address, int chainId) async {
    ERC20 tokenContract = ERC20(address: EthereumAddress.fromHex(address), client: Constants.client);
    String name;
    String symbol;
    int decimals;
    try {
      symbol = await tokenContract.symbol();
    } catch (e) {
      return null;
    }
    try {
      name = await tokenContract.name();
    } catch (e) {
      return null;
    }
    try {
      decimals = (await tokenContract.decimals()).toInt();
    } catch (e) {
      return null;
    }
    return TokenInfo(name: name, symbol: symbol, address: address, logoUri: null, decimals: decimals);
  }

  static Future<String?> _fetchLogoUri(String address) async {
    // todo: fetch tokens logo
    throw UnimplementedError("Fetch Token Logo: Not yet implemented");
  }

}