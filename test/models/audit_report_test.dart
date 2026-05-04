import 'package:test/test.dart';
import 'package:telnet_sentinel/models/audit_report.dart';
import 'package:telnet_sentinel/models/audit_result.dart';

void main() {
  group('AuditReport', () {
    test('should identify failures correctly', () {
      final results = [
        AuditResult('Probe 1', AuditStatus.pass, 'OK'),
        AuditResult('Probe 2', AuditStatus.fail, 'Failed'),
      ];
      final report = AuditReport('localhost:23', results);
      expect(report.hasFailures, isTrue);
    });

    test('should identify success correctly', () {
      final results = [
        AuditResult('Probe 1', AuditStatus.pass, 'OK'),
        AuditResult('Probe 2', AuditStatus.pass, 'OK'),
      ];
      final report = AuditReport('localhost:23', results);
      expect(report.hasFailures, isFalse);
    });

    test('should include timestamp and target', () {
      final report = AuditReport('localhost:23', []);
      expect(report.target, equals('localhost:23'));
      expect(report.timestamp, isA<DateTime>());
    });
  });
}
