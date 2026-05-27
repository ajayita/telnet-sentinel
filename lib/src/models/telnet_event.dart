enum TelnetEventType { iac, data }

class TelnetEvent {
  final TelnetEventType type;
  final List<int> bytes;

  TelnetEvent(this.type, this.bytes);

  @override
  String toString() => 'TelnetEvent(type: $type, bytes: $bytes)';
}
