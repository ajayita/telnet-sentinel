class GmcpEvent {
  final String package;
  final String message;
  final Map<String, dynamic> data;

  GmcpEvent(this.package, this.message, this.data);

  @override
  String toString() =>
      'GmcpEvent(package: $package, message: $message, data: $data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GmcpEvent &&
          runtimeType == other.runtimeType &&
          package == other.package &&
          message == other.message &&
          data.toString() == other.data.toString(); // Simple way to compare maps for tests

  @override
  int get hashCode =>
      package.hashCode ^ message.hashCode ^ data.toString().hashCode;
}
