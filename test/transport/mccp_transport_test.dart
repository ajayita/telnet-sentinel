import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:telnet_sentinel/src/transport/telnet_transport.dart';
import 'package:telnet_sentinel/src/models/telnet_event.dart';

class MockRawSocket extends Stream<RawSocketEvent> implements RawSocket {
  final StreamController<RawSocketEvent> _controller =
      StreamController<RawSocketEvent>();
  final List<Uint8List> _readBuffer = [];

  void simulateRead(List<int> bytes) {
    _readBuffer.add(Uint8List.fromList(bytes));
    _controller.add(RawSocketEvent.read);
  }

  @override
  StreamSubscription<RawSocketEvent> listen(
    void Function(RawSocketEvent event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Uint8List? read([int? len]) {
    if (_readBuffer.isEmpty) return null;
    return _readBuffer.removeAt(0);
  }

  @override
  int available() {
    return _readBuffer.fold(0, (sum, list) => sum + list.length);
  }

  @override
  void shutdown(SocketDirection direction) {}

  @override
  Future<RawSocket> close() async {
    _controller.close();
    return this;
  }

  @override
  int write(List<int> buffer, [int offset = 0, int? count]) {
    return count ?? (buffer.length - offset);
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
    final helloBytes = 'Hello'.codeUnits;
    final compressedHello = zlib.encode(helloBytes);
    mockSocket.simulateRead(compressedHello);

    // Allow some time for processing
    await Future.delayed(Duration(milliseconds: 200));

    // Verify MCCP2 SB was received
    expect(
      events.any(
        (e) =>
            e.type == TelnetEventType.iac &&
            e.bytes.length == 5 &&
            e.bytes[2] == 86,
      ),
      isTrue,
    );

    // Verify "Hello" was decompressed
    final dataEvents = events
        .where((e) => e.type == TelnetEventType.data)
        .toList();
    final allData = dataEvents.expand((e) => e.bytes).toList();
    expect(String.fromCharCodes(allData), contains('Hello'));
  });
}
