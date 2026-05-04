import '../transport/telnet_transport.dart';
import '../models/audit_result.dart';

abstract class Probe {
  String get name;
  Future<AuditResult> run(TelnetTransport transport);
}
