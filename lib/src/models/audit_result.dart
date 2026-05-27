enum AuditStatus { pass, fail, warning }

class AuditResult {
  final String probeName;
  final AuditStatus status;
  final String message;
  final Duration latency;
  final List<int>? rawBytesExchanged;
  final Map<String, dynamic> metadata;

  AuditResult(
    this.probeName,
    this.status,
    this.message, {
    this.latency = Duration.zero,
    this.rawBytesExchanged,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'probeName': probeName,
    'status': status.name,
    'message': message,
    'latency_ms': latency.inMilliseconds,
    if (rawBytesExchanged != null && rawBytesExchanged!.isNotEmpty)
      'rawBytesExchanged': rawBytesExchanged,
    'metadata': metadata,
  };
}
