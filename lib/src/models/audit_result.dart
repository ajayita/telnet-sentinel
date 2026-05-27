enum AuditStatus { pass, fail, warning }

class AuditResult {
  final String probeName;
  final AuditStatus status;
  final String message;
  final Map<String, dynamic> metadata;

  AuditResult(
    this.probeName,
    this.status,
    this.message, {
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'probeName': probeName,
    'status': status.name,
    'message': message,
    'metadata': metadata,
  };
}
