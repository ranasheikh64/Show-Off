import 'package:encrypt/encrypt.dart' as enc;

void main() {
  final key = enc.Key.fromUtf8('my32charpasswordforaes256authkey'); 
  final iv = enc.IV.fromLength(16);
  final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  
  final encrypted = encrypter.encrypt("Hello", iv: iv);
  print("Encrypted: \${encrypted.base64}");
  
  try {
    final decrypted = encrypter.decrypt64(encrypted.base64, iv: iv);
    print("Decrypted: \$decrypted");
  } catch (e) {
    print("Decryption failed: \$e");
  }
}
