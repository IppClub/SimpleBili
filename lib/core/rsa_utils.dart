import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

class RsaUtils {
  static String encryptPassword(String password, String publicKeyStr, String hash) {
    // Bilibili's password encryption: hash + password
    final content = hash + password;
    
    // Parse public key
    final parser = RSAKeyParser();
    final publicKey = parser.parse(publicKeyStr) as RSAPublicKey;
    
    final encrypter = Encrypter(RSA(publicKey: publicKey, encoding: RSAEncoding.PKCS1));
    final encrypted = encrypter.encrypt(content);
    
    return encrypted.base64;
  }
}
