import 'dart:io';

import 'package:args/args.dart';
import 'package:telnet_sentinel/src/models/audit_result.dart';
import 'package:telnet_sentinel/src/probes/ayt_probe.dart';
import 'package:telnet_sentinel/src/probes/binary_mode_probe.dart';
import 'package:telnet_sentinel/src/probes/gmcp_probe.dart';
import 'package:telnet_sentinel/src/probes/handshake_probe.dart';
import 'package:telnet_sentinel/src/probes/malformed_iac_probe.dart';
import 'package:telnet_sentinel/src/probes/mccp_probe.dart';
import 'package:telnet_sentinel/src/probes/negotiation_loop_probe.dart';
import 'package:telnet_sentinel/src/probes/probe_interface.dart';
import 'package:telnet_sentinel/src/transport/telnet_transport.dart';

const _localHost = '127.0.0.1';
const _localPort = 2323;
const _connectionTimeout = Duration(seconds: 5);

Future<void> main(List<String> arguments) async {
  final parser = _buildParser();
  late final ArgResults results;

  try {
    results = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln('');
    stderr.writeln(_usage(parser));
    exitCode = 64;
    return;
  }

  if (results.flag('help')) {
    print(_usage(parser));
    return;
  }

  final target = results.option('target')!;
  if (target != 'local') {
    stderr.writeln(
      'Unsupported target "$target". Only "--target local" is supported.',
    );
    exitCode = 64;
    return;
  }

  final debug = results.flag('debug');
  final targetLabel = '$_localHost:$_localPort';

  print('Manual Telnet verification target: $targetLabel');
  print('Running full current probe suite against controlled local target.');
  print('');

  final outcomes = <_ProbeOutcome>[];
  for (final probe in _buildProbes()) {
    outcomes.add(await _runProbe(probe, debug: debug));
  }

  var hasFailure = false;
  for (final outcome in outcomes) {
    if (outcome.result.status == AuditStatus.fail) {
      hasFailure = true;
    }

    print(
      '${_statusLabel(outcome.result.status)} '
      '[${outcome.result.probeName}] ${outcome.result.message}',
    );

    if (debug && outcome.error != null) {
      print('DEBUG ${outcome.error}');
    }
  }

  print('');
  print(
    'TODO Public live verification requires a future configurable/safe mode '
    'because the current CLI exposes only the full audit suite.',
  );

  if (hasFailure) {
    exitCode = 1;
  }
}

ArgParser _buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'debug',
      negatable: false,
      help: 'Print connection or execution error details after failures.',
    )
    ..addOption(
      'target',
      allowed: ['local'],
      defaultsTo: 'local',
      help: 'Verification target alias.',
    );
}

String _usage(ArgParser parser) {
  return [
    'Usage: dart run tool/manual_telnet_verification/verify_telnet_targets.dart [flags]',
    '',
    parser.usage,
  ].join('\n');
}

List<Probe> _buildProbes() {
  return [
    HandshakeProbe(),
    AytProbe(),
    BinaryModeProbe(),
    GmcpProbe(),
    MccpProbe(),
    MalformedIacProbe(),
    NegotiationLoopProbe(),
  ];
}

Future<_ProbeOutcome> _runProbe(Probe probe, {required bool debug}) async {
  RawSocket? socket;
  TelnetTransport? transport;

  try {
    if (debug) {
      print('DEBUG Connecting for ${probe.name}...');
    }

    socket = await RawSocket.connect(
      _localHost,
      _localPort,
      timeout: _connectionTimeout,
    );
    transport = TelnetTransport(socket);

    final result = await probe.run(transport);
    return _ProbeOutcome(result);
  } catch (error) {
    return _ProbeOutcome(
      AuditResult(
        probe.name,
        AuditStatus.fail,
        'Connection/Execution error against $_localHost:$_localPort: $error',
      ),
      error: error,
    );
  } finally {
    if (transport != null) {
      await transport.close();
    } else {
      socket?.close();
    }
  }
}

String _statusLabel(AuditStatus status) {
  switch (status) {
    case AuditStatus.pass:
      return 'PASS';
    case AuditStatus.fail:
      return 'FAIL';
    case AuditStatus.warning:
      return 'WARN';
  }
}

class _ProbeOutcome {
  final AuditResult result;
  final Object? error;

  _ProbeOutcome(this.result, {this.error});
}
