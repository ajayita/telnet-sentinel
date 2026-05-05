import 'dart:convert';
import 'package:test/test.dart';
import 'package:telnet_sentinel/transport/gmcp_parser.dart';
import 'package:telnet_sentinel/models/gmcp_event.dart';

void main() {
  group('GmcpParser', () {
    test('should parse valid GMCP with JSON data', () {
      final payload = 'Core.Welcome {"version": "1.0"}';
      final bytes = [255, 250, 201, ...utf8.encode(payload), 255, 240];
      
      final event = GmcpParser.parse(bytes);
      
      expect(event, isNotNull);
      expect(event!.package, equals('Core'));
      expect(event.message, equals('Welcome'));
      expect(event.data, equals({'version': '1.0'}));
    });

    test('should parse GMCP with complex JSON data', () {
      final payload = 'Char.Vitals {"hp": 100, "mp": 50, "items": ["sword", "shield"]}';
      final bytes = [255, 250, 201, ...utf8.encode(payload), 255, 240];
      
      final event = GmcpParser.parse(bytes);
      
      expect(event, isNotNull);
      expect(event!.package, equals('Char'));
      expect(event.message, equals('Vitals'));
      expect(event.data, equals({
        'hp': 100,
        'mp': 50,
        'items': ['sword', 'shield']
      }));
    });

    test('should parse GMCP without JSON data', () {
      final payload = 'Core.Ping';
      final bytes = [255, 250, 201, ...utf8.encode(payload), 255, 240];
      
      final event = GmcpParser.parse(bytes);
      
      expect(event, isNotNull);
      expect(event!.package, equals('Core'));
      expect(event.message, equals('Ping'));
      expect(event.data, isEmpty);
    });

    test('should handle GMCP with no package (only message)', () {
      final payload = 'Ping';
      final bytes = [255, 250, 201, ...utf8.encode(payload), 255, 240];
      
      final event = GmcpParser.parse(bytes);
      
      expect(event, isNotNull);
      expect(event!.package, isEmpty);
      expect(event.message, equals('Ping'));
      expect(event.data, isEmpty);
    });

    test('should return null for non-GMCP subnegotiation', () {
      final bytes = [255, 250, 86, 1, 2, 3, 255, 240]; // MCCP
      
      final event = GmcpParser.parse(bytes);
      
      expect(event, isNull);
    });

    test('should return null for malformed telnet sequence', () {
      final bytes = [255, 250, 201, 65, 66, 67]; // Missing IAC SE
      
      final event = GmcpParser.parse(bytes);
      
      expect(event, isNull);
    });

    test('should handle invalid JSON gracefully', () {
      final payload = 'Core.Welcome {invalid:json}';
      final bytes = [255, 250, 201, ...utf8.encode(payload), 255, 240];
      
      final event = GmcpParser.parse(bytes);
      
      expect(event, isNotNull);
      expect(event!.package, equals('Core'));
      expect(event.message, equals('Welcome'));
      expect(event.data, isEmpty);
    });
  });
}
