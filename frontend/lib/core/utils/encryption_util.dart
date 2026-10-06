import 'package:encrypt/encrypt.dart' as enc;

class EncryptionUtil {
  // 32 chars long key for AES-256
  static final _key = enc.Key.fromUtf8('my32charpasswordforaes256authkey'); 
  // 16 chars long fixed IV
  static final _iv = enc.IV.fromUtf8('my16charauthkey!');
  static final _encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));

  static String encrypt(String plainText) {
    if (plainText.isEmpty) return plainText;
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  static String decrypt(String encryptedBase64) {
    if (encryptedBase64.isEmpty) return encryptedBase64;
    try {
      final decrypted = _encrypter.decrypt64(encryptedBase64, iv: _iv);
      return decrypted;
    } catch (e) {
      print('Decryption failed for $encryptedBase64: $e');
      // If decryption fails, it might be an older unencrypted plain text message in the database.
      return encryptedBase64;
    }
  }
}
