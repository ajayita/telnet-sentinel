import 'audit_result.dart';

class AuditReport {
  final String target;
  final DateTime timestamp;
  final List<AuditResult> results;

  AuditReport(this.target, this.results) : timestamp = DateTime.now();

  bool get hasFailures => results.any((r) => r.status == AuditStatus.fail);

  Map<String, dynamic> toJson() => {
        'target': target,
        'timestamp': timestamp.toIso8601String(),
        'results': results.map((r) => r.toJson()).toList(),
      };
}
