import 'package:test/test.dart';
import 'dart:io';
import '../infrastructure/fixture_parser.dart';
import '../infrastructure/transcript_runner.dart';
import '../fake_servers/good_server.dart';
import '../fake_servers/broken_iac_server.dart';

void main() {
  late GoodServer goodServer;
  late BrokenIacServer brokenServer;
  
  setUpAll(() async {
    goodServer = await GoodServer.bind();
    brokenServer = await BrokenIacServer.bind();
  });
  
  tearDownAll(() async {
    await goodServer.close();
    await brokenServer.close();
  });

  group('Self-Tests:', () {
    final fixturesDir = Directory('test/golden');
    if (!fixturesDir.existsSync()) {
      fixturesDir.createSync();
    }
    
    for (var file in fixturesDir.listSync().where((e) => e.path.endsWith('.yaml'))) {
      final yamlString = File(file.path).readAsStringSync();
      final fixture = FixtureParser.parse(yamlString);
      
      test('\${fixture.name} passes against GoodServer', () async {
        await TranscriptRunner.runSocket(fixture, InternetAddress.loopbackIPv4, goodServer.port);
      });
      
      test('\${fixture.name} FAILS against BrokenIacServer (Mutation check)', () async {
        // Should throw TestFailure due to byte mismatch
        expect(
          TranscriptRunner.runSocket(fixture, InternetAddress.loopbackIPv4, brokenServer.port),
          throwsA(isA<TestFailure>()),
        );
      });
    }
  });
}
