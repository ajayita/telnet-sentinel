import 'dart:convert';
import 'dart:io';

abstract class ProbeScenarioServer {
  RawServerSocket? _server;
  final List<RawSocket> _clients = [];

  Future<void> bind() async {
    _server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen((client) {
      _clients.add(client);
      client.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            final data = client.read();
            if (data != null) {
              handleData(client, data);
            }
          }
        },
        onDone: () => _clients.remove(client),
        onError: (_) => _clients.remove(client),
      );
    });
  }

  int get port {
    final boundServer = _server;
    if (boundServer == null) {
      throw StateError(
        'ProbeScenarioServer must be bound before reading port.',
      );
    }
    return boundServer.port;
  }

  Future<void> close() async {
    for (final client in List<RawSocket>.from(_clients)) {
      client.close();
    }
    _clients.clear();
    await _server?.close();
    _server = null;
  }

  void handleData(RawSocket client, List<int> data);
}

class CompliantProbeScenarioServer extends ProbeScenarioServer {
  static const int iac = 255;
  static const int nop = 241;
  static const int se = 240;
  static const int sb = 250;
  static const int will = 251;
  static const int wont = 252;
  static const int ayt = 246;
  static const int ttype = 24;
  static const int gmcp = 201;

  @override
  void handleData(RawSocket client, List<int> data) {
    for (var i = 0; i < data.length; i++) {
      if (data[i] != iac || i + 1 >= data.length) {
        continue;
      }

      final command = data[i + 1];
      if (command == ayt) {
        client.write([iac, nop]);
        i += 1;
      } else if (command == 253 && i + 2 < data.length) {
        final option = data[i + 2];
        if (option == ttype) {
          client.write([iac, will, ttype]);
        } else if (option == gmcp) {
          client.write([iac, will, gmcp]);
          client.write([
            iac,
            sb,
            gmcp,
            ...utf8.encode('Core.Hello {}'),
            iac,
            se,
          ]);
        } else {
          client.write([iac, wont, option]);
        }
        i += 2;
      }
    }
  }
}

class NoResponseProbeScenarioServer extends ProbeScenarioServer {
  @override
  void handleData(RawSocket client, List<int> data) {}
}

class GmcpRefusalProbeScenarioServer extends ProbeScenarioServer {
  @override
  void handleData(RawSocket client, List<int> data) {
    _forEachThreeByteCommand(data, (command, option) {
      if (command == 253 && option == CompliantProbeScenarioServer.gmcp) {
        client.write([
          CompliantProbeScenarioServer.iac,
          CompliantProbeScenarioServer.wont,
          CompliantProbeScenarioServer.gmcp,
        ]);
      }
    });
  }
}

class NegotiationLoopStallProbeScenarioServer extends ProbeScenarioServer {
  var _answeredFirstToggle = false;

  @override
  void handleData(RawSocket client, List<int> data) {
    _forEachThreeByteCommand(data, (command, option) {
      if (option != 1 || _answeredFirstToggle) {
        return;
      }

      if (command == 253) {
        client.write([
          CompliantProbeScenarioServer.iac,
          CompliantProbeScenarioServer.will,
          option,
        ]);
      } else if (command == 254) {
        client.write([
          CompliantProbeScenarioServer.iac,
          CompliantProbeScenarioServer.wont,
          option,
        ]);
        _answeredFirstToggle = true;
      }
    });
  }
}

class MalformedIacFailureProbeScenarioServer extends ProbeScenarioServer {
  @override
  void handleData(RawSocket client, List<int> data) {
    if (data.contains(CompliantProbeScenarioServer.iac)) {
      client.close();
    }
  }
}

void _forEachThreeByteCommand(
  List<int> data,
  void Function(int command, int option) callback,
) {
  for (var i = 0; i < data.length - 2; i++) {
    if (data[i] == CompliantProbeScenarioServer.iac) {
      callback(data[i + 1], data[i + 2]);
      i += 2;
    }
  }
}
