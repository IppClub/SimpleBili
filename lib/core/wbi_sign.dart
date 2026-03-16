import 'dart:convert';
import 'package:crypto/crypto.dart';

class WbiSign {
  static const List<int> mixinKeyEncTab = [
    46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35, 27, 43, 5, 49,
    33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13, 37, 48, 7, 16, 24, 55, 40,
    61, 26, 17, 0, 1, 60, 51, 30, 4, 22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11,
    36, 20, 34, 44, 52
  ];

  static String getMixinKey(String imgKey, String subKey) {
    String s = imgKey + subKey;
    String res = "";
    for (int i = 0; i < 64; i++) {
      res += s[mixinKeyEncTab[i]];
    }
    return res.substring(0, 32);
  }

  static Map<String, dynamic> sign(
      Map<String, dynamic> params, String imgKey, String subKey) {
    final mixinKey = getMixinKey(imgKey, subKey);
    final currTime = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final Map<String, dynamic> queryParams = Map.from(params);
    queryParams['wts'] = currTime.toString();

    final sortedKeys = queryParams.keys.toList()..sort();
    
    String queryStr = "";
    for (final key in sortedKeys) {
      final value = queryParams[key].toString();
      final sanitizedValue = value.replaceAll(RegExp(r"[!'()*]"), "");
      if (queryStr.isNotEmpty) queryStr += "&";
      queryStr += "${Uri.encodeComponent(key)}=${Uri.encodeComponent(sanitizedValue)}";
    }

    final wbiSig = md5.convert(utf8.encode(queryStr + mixinKey)).toString();
    queryParams['w_rid'] = wbiSig;

    return queryParams;
  }
}
