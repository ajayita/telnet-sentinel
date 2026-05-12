# MCCP2 Zlib Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable `TelnetTransport` to transition to a decompressing stream upon detecting the MCCP2 sub-negotiation start (`IAC SB MCCP2 IAC SE`).

**Architecture:** Introduce an optional `ZLibDecoder` into the data pipeline of `TelnetTransport`. When the MCCP2 trigger sequence is detected in the raw byte stream, subsequent bytes are routed through the decoder before being parsed as Telnet events.

**Tech Stack:** Dart, `dart:io` (ZLibCodec), `package:telnet_sentinel`.

---

### Task 1: Create failing test for MCCP2 decompression

**Files:**
- Create: `test/transport/mccp_transport_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'package:telnet_sentinel/models/telnet_event.dart';

class MockRawSocket extends Stream<RawSocketEvent> implements RawSocket {
  final StreamController<RawSocketEvent> _controller = StreamController<RawSocketEvent>();
  final List<List<int>> _readBuffer = [];

  void simulateRead(List<int> bytes) {
    _readBuffer.add(bytes);
    _controller.add(RawSocketEvent.read);
  }

  @override
  StreamSubscription<RawSocketEvent> listen(void Function(RawSocketEvent event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _controller.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  List<int>? read([int? len]) {
    if (_readBuffer.isEmpty) return null;
    return _readBuffer.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('TelnetTransport decompresses data after MCCP2 SB', () async {
    final mockSocket = MockRawSocket();
    final transport = TelnetTransport(mockSocket);
    
    final events = <TelnetEvent>[];
    transport.events.listen(events.add);

    // IAC SB MCCP2 IAC SE
    final mccpTrigger = [255, 250, 86, 255, 240];
    mockSocket.simulateRead(mccpTrigger);

    // Compressed "Hello" using zlib
    // Using ZLibCodec().encode() but for MCCP we often need raw zlib (no zlib header/checksum)
    // Actually MCCP2 uses standard zlib (RFC 1950), not raw deflate (RFC 1951).
    final helloBytes = 'Hello'.codeUnits;
    final compressedHello = zlib.encode(helloBytes);
    mockSocket.simulateRead(compressedHello);

    // Allow some time for processing
    await Future.delayed(Duration(milliseconds: 100));

    expect(events.any((e) => e.type == TelnetEventType.iac && e.bytes.length == 5 && e.bytes[2] == 86), isTrue);
    expect(events.any((e) => e.type == TelnetEventType.data && String.fromCharCodes(e.bytes) == 'Hello'), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/transport/mccp_transport_test.dart`
Expected: FAIL (The "Hello" bytes will likely be emitted as raw compressed bytes or cause parser confusion)

- [ ] **Step 3: Commit**

```bash
git add test/transport/mccp_transport_test.dart
git commit -m "test: add failing test for MCCP2 decompression"
```

---

### Task 2: Implement Zlib Decompression Logic in TelnetTransport

**Files:**
- Modify: `lib/transport/telnet_transport.dart`

- [ ] **Step 1: Add decompression state and sink**

```dart
class TelnetTransport {
  // ...
  bool _isDecompressing = false;
  ByteConversionSink? _decompressorSink;
  // ...
}
```

- [ ] **Step 2: Update `_processBytes` to detect MCCP2 SB**

Update the SB handling to check for option 86.

```dart
// inside _processBytes, in the SB handling:
            if (seIndex != -1) {
              final sbBytes = _pendingBytes.sublist(0, seIndex + 1);
              _controller.add(TelnetEvent(TelnetEventType.iac, sbBytes));
              
              // MCCP2 check: IAC SB 86 IAC SE
              if (sbBytes.length == 5 && sbBytes[2] == 86) {
                _startDecompression();
                _pendingBytes.removeRange(0, seIndex + 1);
                // After IAC SE, the rest of _pendingBytes is compressed
                if (_pendingBytes.isNotEmpty) {
                  final compressed = List<int>.from(_pendingBytes);
                  _pendingBytes.clear();
                  _decompressorSink!.add(compressed);
                }
                return; // Exit _processBytes loop, it will be re-entered via decompressor callback
              }
              
              _pendingBytes.removeRange(0, seIndex + 1);
            }
```

- [ ] **Step 3: Implement `_startDecompression` and `_onSocketEvent` update**

```dart
  void _startDecompression() {
    _isDecompressing = true;
    _decompressorSink = zlib.decoder.startChunkedConversion(
      ByteConversionSink.withCallback((decompressed) {
        _processBytes(decompressed, fromDecompressor: true);
      })
    );
  }

  void _onSocketEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final bytes = _socket.read();
      if (bytes != null) {
        if (_isDecompressing) {
          _decompressorSink!.add(bytes);
        } else {
          _processBytes(bytes);
        }
      }
    } // ...
  }
```

- [ ] **Step 4: Refactor `_processBytes` signature**

```dart
  void _processBytes(List<int> bytes, {bool fromDecompressor = false}) {
    _pendingBytes.addAll(bytes);
    
    while (_pendingBytes.isNotEmpty) {
      // ... same logic ...
      // But make sure that if we detect MCCP2 and we are ALREADY decompressing, something is wrong or we ignore it.
      // Actually, if fromDecompressor is true, we should NOT trigger _startDecompression again.
    }
  }
```

- [ ] **Step 5: Run tests to verify it passes**

Run: `dart test test/transport/mccp_transport_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/transport/telnet_transport.dart
git commit -m "feat: implement MCCP2 decompression in TelnetTransport"
```

---

### Task 3: Handle edge cases (partial packets)

- [ ] **Step 1: Update test to include partial compressed packets**

```dart
  test('TelnetTransport handles partial compressed packets', () async {
    final mockSocket = MockRawSocket();
    final transport = TelnetTransport(mockSocket);
    
    final events = <TelnetEvent>[];
    transport.events.listen(events.add);

    mockSocket.simulateRead([255, 250, 86, 255, 240]);
    
    final compressedHello = zlib.encode('Hello World'.codeUnits);
    final part1 = compressedHello.sublist(0, compressedHello.length ~/ 2);
    final part2 = compressedHello.sublist(compressedHello.length ~/ 2);
    
    mockSocket.simulateRead(part1);
    await Future.delayed(Duration(milliseconds: 50));
    mockSocket.simulateRead(part2);
    
    await Future.delayed(Duration(milliseconds: 100));
    expect(events.any((e) => e.type == TelnetEventType.data && String.fromCharCodes(e.bytes).contains('Hello World')), isTrue);
  });
```

- [ ] **Step 2: Run tests**
- [ ] **Step 3: Commit**
