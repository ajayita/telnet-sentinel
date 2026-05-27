import 'dart:io';

void main() {
  final encoded = zlib.encode('Hello'.codeUnits);
  print('Encoded: $encoded');
  print('As String: ${String.fromCharCodes(encoded)}');
}
