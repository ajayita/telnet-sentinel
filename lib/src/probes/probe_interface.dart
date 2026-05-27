import 'package:telnet_sentinel/src/transport/telnet_transport.dart';
import 'package:telnet_sentinel/src/models/audit_result.dart';

abstract class Probe {
  String get name;
  Future<AuditResult> run(TelnetTransport transport);
}
