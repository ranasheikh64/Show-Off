import 'package:encrypt/encrypt.dart' as enc;

void main() {
  final iv1 = enc.IV.fromLength(16);
  print("IV1: \${iv1.bytes}");
  final iv2 = enc.IV.fromLength(16);
  print("IV2: \${iv2.bytes}");
}
