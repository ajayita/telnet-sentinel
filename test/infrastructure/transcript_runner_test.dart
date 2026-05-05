import 'package:test/test.dart';
import 'dart:io';
import '../fake_servers/good_server.dart';
import 'models.dart';
import 'transcript_runner.dart';

void main() {
  test('runSocket executes fixture against GoodServer', () async {
    final server = await GoodServer.bind();
    
    final fixture = TranscriptFixture(
      name: "SocketTest", description: "",
      steps: [
        TranscriptStep(clientSends: [255, 253, 1]), // send IAC DO 1
        TranscriptStep(expectEvents: [ExpectedEvent(type: 'iac', bytes: [255, 253, 1])])
      ]
    );
    
    await TranscriptRunner.runSocket(fixture, InternetAddress.loopbackIPv4, server.port);
    await server.close();
  });
}
