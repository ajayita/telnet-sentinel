import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'package:telnet_sentinel/models/audit_result.dart';

abstract class Probe {
  String get name;
  Future<AuditResult> run(TelnetTransport transport);
}
