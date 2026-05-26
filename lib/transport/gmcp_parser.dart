import 'dart:convert';
import 'package:telnet_sentinel/models/gmcp_event.dart';

class GmcpParser {
  /// Parses raw GMCP subnegotiation bytes into a [GmcpEvent].
  ///
  /// The [bytes] should include the IAC SB 201 prefix and IAC SE suffix.
  static GmcpEvent? parse(List<int> bytes) {
    // Basic validation: IAC SB 201 ... IAC SE
    // Minimum length: IAC SB 201 (3) + "A.B" (3) + IAC SE (2) = 8
    if (bytes.length < 5 ||
        bytes[0] != 255 ||
        bytes[1] != 250 ||
        bytes[2] != 201 ||
        bytes[bytes.length - 2] != 255 ||
        bytes[bytes.length - 1] != 240) {
      return null;
    }

    // Extract the payload (everything between option 201 and IAC SE)
    final payloadBytes = bytes.sublist(3, bytes.length - 2);
    if (payloadBytes.isEmpty) return null;

    String rawString;
    try {
      rawString = utf8.decode(payloadBytes, allowMalformed: true).trim();
    } catch (_) {
      return null;
    }
    if (rawString.isEmpty) return null;

    // GMCP format: Package.Message [JSON]
    // Example: Core.Welcome {"version": "1.0"}

    String packageMessage;
    Map<String, dynamic> data = {};

    final spaceIndex = rawString.indexOf(' ');
    if (spaceIndex != -1) {
      packageMessage = rawString.substring(0, spaceIndex);
      final jsonPart = rawString.substring(spaceIndex + 1).trim();
      if (jsonPart.isNotEmpty) {
        try {
          final decoded = jsonDecode(jsonPart);
          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (_) {
          // If JSON is invalid, we return the event with empty data
          // or we could potentially throw an error depending on requirements.
          // For now, let's keep it robust.
        }
      }
    } else {
      packageMessage = rawString;
    }

    // Split Package.Message
    final dotIndex = packageMessage.lastIndexOf('.');
    String package;
    String message;

    if (dotIndex != -1) {
      package = packageMessage.substring(0, dotIndex);
      message = packageMessage.substring(dotIndex + 1);
    } else {
      package = '';
      message = packageMessage;
    }

    return GmcpEvent(package, message, data);
  }
}
