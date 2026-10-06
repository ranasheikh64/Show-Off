import 'package:encrypt/encrypt.dart' as enc;

void main() {
  final key = enc.Key.fromUtf8('my32charpasswordforaes256authkey'); 
  final iv = enc.IV.fromLength(16);
  final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  
  final base64String = "ti/SUilSkf5zqvhaEZaxkg==";
  try {
    final decrypted = encrypter.decrypt64(base64String, iv: iv);
    print("Decrypted: \$decrypted");
  } catch (e) {
    print("Decryption failed: \$e");
  }
}
