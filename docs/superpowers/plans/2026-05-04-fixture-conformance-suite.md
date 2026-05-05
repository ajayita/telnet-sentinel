# Fixture-Based Conformance Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a self-testing harness that uses YAML fixtures to prove our library (parsers, matchers, transcript runners) correctly detects valid and invalid protocol behavior.

**Architecture:** Create a `FixtureParser` to deserialize YAML transcripts into Dart models. Build a `TranscriptRunner` to execute these models either directly against the local parser or over a socket against minimal `FakeServers`. Finally, orchestrate this in `dart test` to prove known-good servers pass and known-bad servers fail with exact error messages.

**Tech Stack:** Dart, `test` package, `yaml` package.

---

### Task 1: Fixture Models & YAML Parser

**Files:**
- Create: `test/infrastructure/models.dart`
- Create: `test/infrastructure/fixture_parser.dart`
- Create: `test/infrastructure/fixture_parser_test.dart`

- [ ] **Step 1: Add YAML dependency**
Run: `dart pub add yaml`
Expected: Updates `pubspec.yaml`.

- [ ] **Step 2: Write the failing test for models and parser**
```dart
// test/infrastructure/fixture_parser_test.dart
import 'package:test/test.dart';
import 'models.dart';
import 'fixture_parser.dart';

void main() {
  test('parses simple fixture', () {
    final yaml = '''
name: "Test"
description: "Desc"
steps:
  - client_sends: [255, 253, 1]
  - expect_events:
      - type: "iac"
        bytes: [255, 253, 1]
''';
    final fixture = FixtureParser.parse(yaml);
    expect(fixture.name, "Test");
    expect(fixture.description, "Desc");
    expect(fixture.steps.length, 2);
    expect(fixture.steps[0].clientSends, [255, 253, 1]);
    expect(fixture.steps[1].expectEvents?.first.type, "iac");
    expect(fixture.steps[1].expectEvents?.first.bytes, [255, 253, 1]);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**
Run: `dart test test/infrastructure/fixture_parser_test.dart`
Expected: Compilation errors (files missing).

- [ ] **Step 4: Write minimal implementation for models**
```dart
// test/infrastructure/models.dart
class ExpectedEvent {
  final String type;
  final List<int> bytes;
  ExpectedEvent({required this.type, required this.bytes});
}

class TranscriptStep {
  final List<int>? clientSends;
  final List<ExpectedEvent>? expectEvents;
  final Map<String, dynamic>? expectState;
  
  TranscriptStep({this.clientSends, this.expectEvents, this.expectState});
}

class TranscriptFixture {
  final String name;
  final String description;
  final List<TranscriptStep> steps;

  TranscriptFixture({required this.name, required this.description, required this.steps});
}
```

- [ ] **Step 5: Write minimal implementation for parser**
```dart
// test/infrastructure/fixture_parser.dart
import 'package:yaml/yaml.dart';
import 'models.dart';

class FixtureParser {
  static TranscriptFixture parse(String yamlString) {
    final doc = loadYaml(yamlString);
    final steps = <TranscriptStep>[];
    
    for (var stepNode in doc['steps']) {
      if (stepNode.containsKey('client_sends')) {
        steps.add(TranscriptStep(
          clientSends: List<int>.from(stepNode['client_sends']),
        ));
      } else if (stepNode.containsKey('expect_events')) {
        final events = <ExpectedEvent>[];
        for (var eventNode in stepNode['expect_events']) {
          events.add(ExpectedEvent(
            type: eventNode['type'],
            bytes: List<int>.from(eventNode['bytes']),
          ));
        }
        steps.add(TranscriptStep(expectEvents: events));
      } else if (stepNode.containsKey('expect_state')) {
        steps.add(TranscriptStep(
          expectState: Map<String, dynamic>.from(stepNode['expect_state']),
        ));
      }
    }
    
    return TranscriptFixture(
      name: doc['name'],
      description: doc['description'],
      steps: steps,
    );
  }
}
```

- [ ] **Step 6: Run test to verify it passes**
Run: `dart test test/infrastructure/fixture_parser_test.dart`
Expected: All tests pass.

- [ ] **Step 7: Commit**
```bash
git add pubspec.yaml pubspec.lock test/infrastructure/
git commit -m "test: implement yaml fixture parser and models"
```

---

### Task 2: Fake Servers (Good and Broken)

**Files:**
- Create: `test/fake_servers/good_server.dart`
- Create: `test/fake_servers/broken_iac_server.dart`
- Create: `test/fake_servers/server_test.dart`

- [ ] **Step 1: Write failing test for server binding**
```dart
// test/fake_servers/server_test.dart
import 'dart:io';
import 'package:test/test.dart';
import 'good_server.dart';
import 'broken_iac_server.dart';

void main() {
  test('Servers can bind to loopback', () async {
    final good = await GoodServer.bind();
    final broken = await BrokenIacServer.bind();
    
    expect(good.port, greaterThan(0));
    expect(broken.port, greaterThan(0));
    
    await good.close();
    await broken.close();
  });
}
```

- [ ] **Step 2: Run test**
Run: `dart test test/fake_servers/server_test.dart`
Expected: Compilation errors.

- [ ] **Step 3: Implement GoodServer**
```dart
// test/fake_servers/good_server.dart
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
```

- [ ] **Step 4: Implement BrokenIacServer**
```dart
// test/fake_servers/broken_iac_server.dart
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
            // Broken: Does not escape IACs in data!
            client.write(data);
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
    for (var c in _clients) c.close();
    await _server.close();
  }
}
```

- [ ] **Step 5: Run tests**
Run: `dart test test/fake_servers/server_test.dart`
Expected: Passes.

- [ ] **Step 6: Commit**
```bash
git add test/fake_servers/
git commit -m "test: add mock telnet servers for mutation testing"
```

---

### Task 3: Transcript Runner (Direct Mode)

**Files:**
- Create: `test/infrastructure/transcript_runner.dart`
- Create: `test/infrastructure/transcript_runner_test.dart`

- [ ] **Step 1: Write failing test**
```dart
// test/infrastructure/transcript_runner_test.dart
import 'package:test/test.dart';
import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'models.dart';
import 'transcript_runner.dart';
import 'dart:io';
import 'dart:async';

void main() {
  test('runDirect executes fixture', () async {
    final fixture = TranscriptFixture(
      name: "DirectTest", description: "",
      steps: [
        TranscriptStep(clientSends: [255, 253, 1]),
        TranscriptStep(expectEvents: [ExpectedEvent(type: 'iac', bytes: [255, 253, 1])])
      ]
    );
    
    // We need a dummy socket just to initialize transport, we won't write to it via OS
    final server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final socketFuture = RawSocket.connect(InternetAddress.loopbackIPv4, server.port);
    final clientSocket = await server.first;
    final socket = await socketFuture;
    
    final transport = TelnetTransport(socket);
    
    await expectLater(TranscriptRunner.runDirect(fixture, transport, socket), completes);
    
    await transport.close();
    clientSocket.close();
    await server.close();
  });
}
```

- [ ] **Step 2: Run test to verify failure**
Run: `dart test test/infrastructure/transcript_runner_test.dart`
Expected: Compilation errors.

- [ ] **Step 3: Implement Direct Mode Runner**
```dart
// test/infrastructure/transcript_runner.dart
import 'dart:async';
import 'package:test/test.dart';
import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'package:telnet_sentinel/models/telnet_event.dart';
import 'dart:io';
import 'models.dart';

class TranscriptRunner {
  static Future<void> runDirect(TranscriptFixture fixture, TelnetTransport transport, RawSocket rawSocket) async {
    final events = <TelnetEvent>[];
    final sub = transport.events.listen((e) => events.add(e));
    
    try {
      for (var step in fixture.steps) {
        if (step.clientSends != null) {
          // Push bytes directly into the parser by simulating socket read? 
          // Actually, if we use real socket, we must write to the other side.
          // The direct parser mode was meant to feed bytes directly. TelnetTransport 
          // currently only reads from RawSocket. So we write to the paired socket.
          // The alternative is writing to the rawSocket we hold (it goes out).
          // Wait, if transport wraps `socket`, to feed the parser, someone must write
          // to `clientSocket` (the server side). For true direct mode, we might need a StreamController.
          // Let's use the provided socket by writing to it if it's a paired stream, or just throw for now.
          throw UnimplementedError('Direct feed requires refactoring Transport to accept generic Streams. Skipping for now. Use Socket Mode.');
        }
      }
    } finally {
      await sub.cancel();
    }
  }
}
```
*Wait, as self-reviewed, writing to a real socket from the direct mode violates the architecture. Let's adapt TranscriptRunner to use a real socket connection to loopback in `runSocket` instead, since `TelnetTransport` requires a `RawSocket`.* Let's fix the step inline.

- [ ] **Step 4: Refactor to runSocket instead of runDirect**
```dart
// test/infrastructure/transcript_runner.dart
import 'dart:async';
import 'package:test/test.dart';
import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'package:telnet_sentinel/models/telnet_event.dart';
import 'dart:io';
import 'models.dart';

class TranscriptRunner {
  static Future<void> runSocket(TranscriptFixture fixture, InternetAddress address, int port) async {
    final socket = await RawSocket.connect(address, port);
    final transport = TelnetTransport(socket);
    
    final events = <TelnetEvent>[];
    final sub = transport.events.listen((e) => events.add(e));
    
    try {
      for (var step in fixture.steps) {
        if (step.clientSends != null) {
          socket.write(step.clientSends!);
          // Give it a tiny bit to roundtrip
          await Future.delayed(Duration(milliseconds: 50));
        } else if (step.expectEvents != null) {
          // Wait until we have enough events
          int retries = 10;
          while (events.length < step.expectEvents!.length && retries > 0) {
            await Future.delayed(Duration(milliseconds: 10));
            retries--;
          }
          
          expect(events.length, greaterThanOrEqualTo(step.expectEvents!.length), 
            reason: 'Did not receive expected number of events');
            
          for (int i = 0; i < step.expectEvents!.length; i++) {
            final expected = step.expectEvents![i];
            final actual = events.removeAt(0);
            
            final expectedType = expected.type == 'iac' ? TelnetEventType.iac : TelnetEventType.data;
            expect(actual.type, expectedType, reason: 'Event type mismatch');
            expect(actual.bytes, expected.bytes, reason: 'Event bytes mismatch');
          }
        } else if (step.expectState != null) {
           // Not implemented in parser yet, skip
        }
      }
    } finally {
      await sub.cancel();
      await transport.close();
    }
  }
}
```

- [ ] **Step 5: Fix the test to use GoodServer and runSocket**
```dart
// test/infrastructure/transcript_runner_test.dart
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
        TranscriptStep(clientSends: [255, 255]), // send 255
        // GoodServer echoes it, but escapes the IAC: 255 -> 255, 255
        TranscriptStep(expectEvents: [ExpectedEvent(type: 'iac', bytes: [255, 255])])
      ]
    );
    
    await TranscriptRunner.runSocket(fixture, InternetAddress.loopbackIPv4, server.port);
    await server.close();
  });
}
```

- [ ] **Step 6: Run tests**
Run: `dart test test/infrastructure/transcript_runner_test.dart`
Expected: Passes.

- [ ] **Step 7: Commit**
```bash
git add test/infrastructure/transcript_runner*
git commit -m "test: implement socket mode transcript runner"
```

---

### Task 4: The Self-Test Loop

**Files:**
- Create: `test/golden/iac_escape.yaml`
- Create: `test/self_tests/self_test.dart`

- [ ] **Step 1: Create a YAML fixture**
```yaml
# test/golden/iac_escape.yaml
name: "IAC Escaping Basic"
description: "Ensures parser correctly handles 0xFF 0xFF as a literal 0xFF."
steps:
  - client_sends: [255, 255] # Send single 255 byte
  - expect_events:
      - type: "iac"
        bytes: [255, 255]    # Expected echo with IAC escaped by server
```

- [ ] **Step 2: Write the self test file**
```dart
// test/self_tests/self_test.dart
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
```

- [ ] **Step 3: Run the suite**
Run: `dart test test/self_tests/self_test.dart`
Expected: Both tests pass (GoodServer passes the fixture, BrokenIacServer correctly fails the fixture).

- [ ] **Step 4: Commit**
```bash
git add test/golden/ test/self_tests/
git commit -m "test: orchestrate dynamic self-test suite"
```
