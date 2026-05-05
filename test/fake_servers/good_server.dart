import 'dart:io';
import 'dart:async';

class GoodServer {
  final RawServerSocket _server;
  final List<RawSocket> _clients = [];
  
  GoodServer._(this._server) {
    _server.listen((client) {
      _clients.add(client);
      client.listen((event) {
        if (event == RawSocketEvent.read) {
          final data = client.read();
          if (data != null) {
            // Very simple echo for now, but properly escapes IACs
            final response = <int>[];
            for (var b in data) {
              response.add(b);
              if (b == 255) response.add(255); // escape IAC
            }
            client.write(response);
          }
        }
      });
    });
  }
  
  static Future<GoodServer> bind() async {
    final s = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    return GoodServer._(s);
  }
  
  int get port => _server.port;
  
  Future<void> close() async {
    for (var c in _clients) c.close();
    await _server.close();
  }
}
