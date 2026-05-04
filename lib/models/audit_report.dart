import 'audit_result.dart';

class AuditReport {
  final String target;
  final DateTime timestamp;
  final List<AuditResult> results;

  AuditReport(this.target, this.results) : timestamp = DateTime.now();

  bool get hasFailures => results.any((r) => r.status == AuditStatus.fail);
}
