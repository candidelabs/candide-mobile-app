import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:candide_mobile_app/config/theme.dart';
import 'package:candide_mobile_app/controller/token_info_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:web3dart/crypto.dart';

class TokenLogo extends StatelessWidget {
  final TokenInfo token;
  final double size;
  const TokenLogo({Key? key, required this.token, required this.size}) : super(key: key);

  Widget _getTokenWidget([bool forceGeneric=false]) {
    String? logoUri = token.logoUri;
    if (logoUri != null && !forceGeneric){
      if (!logoUri.contains(".svg")){
        return CachedNetworkImage(
          imageUrl: logoUri,
        );
      }else{
        return FutureBuilder(
          future: DefaultCacheManager().getSingleFile(logoUri),
          builder: (_, AsyncSnapshot snapshot){
            if (snapshot.connectionState != ConnectionState.done){
              return const SizedBox.shrink();
            }
            if (snapshot.hasData){
              return SvgPicture.file(snapshot.data);
            }else{
              return _getTokenWidget(true);
            }
          },
        );
      }
    }else{
      /*return ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: Blockies(
          seed: token.address,
        ),
      );*/
      String seed = bytesToHex(keccak256(
        Uint8List.fromList(token.address.toLowerCase().codeUnits + token.name.toLowerCase().codeUnits + token.symbol.toLowerCase().codeUnits)
      )).substring(0, 8);
      Random random = Random(BigInt.parse(seed, radix: 16).toInt());
      return Center(
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size),
            color: AppThemes.miscColors.randomColors[random.nextInt(AppThemes.miscColors.randomColors.length)],
          ),
          child: FittedBox(
            fit: BoxFit.fitWidth,
            child: Text(token.symbol, textAlign: TextAlign.center, style: TextStyle(fontFamily: AppThemes.fonts.gilroyBold, color: Get.theme.colorScheme.primary),)
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: _getTokenWidget(),
    );
  }
}
