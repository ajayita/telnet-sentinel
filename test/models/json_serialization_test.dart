import 'package:test/test.dart';
import 'package:telnet_sentinel/models/audit_result.dart';
import 'package:telnet_sentinel/models/audit_report.dart';

void main() {
  group('AuditResult JSON Serialization', () {
    test('toJson() returns correct map', () {
      final result = AuditResult(
        'Test Probe',
        AuditStatus.pass,
        'All good',
        metadata: {'key': 'value'},
      );

      final json = result.toJson();

      expect(json['probeName'], 'Test Probe');
      expect(json['status'], 'pass');
      expect(json['message'], 'All good');
      expect(json['metadata'], {'key': 'value'});
    });
  });

  group('AuditReport JSON Serialization', () {
    test('toJson() returns correct map', () {
      final results = [
        AuditResult('Probe 1', AuditStatus.pass, 'OK'),
        AuditResult(
          'Probe 2',
          AuditStatus.fail,
          'Failed',
          metadata: {'error': 'timeout'},
        ),
      ];
      final report = AuditReport('localhost:23', results);

      final json = report.toJson();

      expect(json['target'], 'localhost:23');
      expect(json['timestamp'], isA<String>());
      expect(json['results'], isA<List>());
      expect(json['results'].length, 2);
      expect(json['results'][0]['probeName'], 'Probe 1');
      expect(json['results'][1]['status'], 'fail');
      expect(json['results'][1]['metadata'], {'error': 'timeout'});
    });
  });
}
