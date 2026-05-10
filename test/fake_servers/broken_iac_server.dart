import 'dart:io';
import 'dart:async';

class BrokenIacServer {
  final RawServerSocket _server;
  final List<RawSocket> _clients = [];

  BrokenIacServer._(this._server) {
    _server.listen((client) {
      _clients.add(client);
      client.listen((event) {
        if (event == RawSocketEvent.read) {
          final data = client.read();
          if (data != null) {
            if (data.length == 1 && data[0] == 101) {
              client.write([255, 10]); // broken escaped IAC, becomes a command
            } else {
              client.write(data);
            }
          }
        }
      });
    });
  }

  static Future<BrokenIacServer> bind() async {
    final s = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    return BrokenIacServer._(s);
  }

  int get port => _server.port;

  Future<void> close() async {
    for (var c in _clients) {
      c.close();
    }
    await _server.close();
  }
}
