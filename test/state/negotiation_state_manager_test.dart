import 'dart:typed_data';
import 'package:test/test.dart';
import '../../lib/state/negotiation_state_manager.dart';

void main() {
  group('NegotiationStateManager', () {
    late List<int> sentBytes;
    late NegotiationStateManager manager;

    void onSend(Uint8List data) {
      sentBytes.addAll(data);
    }

    setUp(() {
      sentBytes = [];
      manager = NegotiationStateManager(onSend: onSend);
    });

    test('receiving DO ECHO when state is NO should send WILL ECHO', () {
      const echoOption = 1;
      const doCmd = 253;
      const willCmd = 251;
      const iac = 255;

      manager.handleDo(echoOption);

      expect(sentBytes, equals([iac, willCmd, echoOption]));
    });

    test('receiving DO ECHO when state is already YES should do nothing', () {
      const echoOption = 1;
      const doCmd = 253;
      const iac = 255;

      // Set state to YES
      manager.handleDo(echoOption);
      sentBytes.clear();

      manager.handleDo(echoOption);

      expect(sentBytes, isEmpty);
    });

    test('local request to DO BINARY should send DO BINARY and update state to WANT_YES', () {
      const binaryOption = 0;
      const doCmd = 253;
      const iac = 255;

      manager.requestDo(binaryOption);

      expect(sentBytes, equals([iac, doCmd, binaryOption]));
      // We can't directly check state unless we expose it or use another method.
      // But we can verify what happens when we receive WILL BINARY.
    });

    test('receiving WILL BINARY after local DO should update state to YES and send nothing', () {
      const binaryOption = 0;
      const iac = 255;
      const willCmd = 251;

      manager.requestDo(binaryOption);
      sentBytes.clear();

      manager.handleWill(binaryOption);

      expect(sentBytes, isEmpty);
      
      // If we receive another WILL, it should still do nothing.
      manager.handleWill(binaryOption);
      expect(sentBytes, isEmpty);
    });

    test('receiving WONT BINARY should update state to NO and send nothing if already NO', () {
      const binaryOption = 0;
      manager.handleWont(binaryOption);
      expect(sentBytes, isEmpty);
    });

    test('receiving WONT BINARY when state is YES should send DONT BINARY and update state to NO', () {
      const binaryOption = 0;
      const iac = 255;
      const dontCmd = 254;

      // Force state to YES
      manager.handleWill(binaryOption);
      sentBytes.clear();

      manager.handleWont(binaryOption);
      expect(sentBytes, equals([iac, dontCmd, binaryOption]));
    });

    test('receiving DONT ECHO when state is YES should send WONT ECHO and update state to NO', () {
      const echoOption = 1;
      const iac = 255;
      const wontCmd = 252;

      // Force state to YES
      manager.handleDo(echoOption);
      sentBytes.clear();

      manager.handleDont(echoOption);
      expect(sentBytes, equals([iac, wontCmd, echoOption]));
    });

    test('requesting WILL should send WILL and update state to WANT_YES', () {
      const option = 3; // Suppress Go Ahead
      manager.requestWill(option);
      expect(sentBytes, equals([255, 251, 3]));
    });

    test('receiving DO after local WILL should update state to YES and send nothing', () {
      const option = 3;
      manager.requestWill(option);
      sentBytes.clear();
      manager.handleDo(option);
      expect(sentBytes, isEmpty);
    });

    test('receiving DONT after local WILL should update state to NO and send nothing', () {
      const option = 3;
      manager.requestWill(option);
      sentBytes.clear();
      manager.handleDont(option);
      expect(sentBytes, isEmpty);
    });

    test('requesting WONT when state is YES should send WONT and update state to WANT_NO', () {
      const option = 3;
      manager.handleDo(option); // Become YES
      sentBytes.clear();
      
      manager.requestWont(option);
      expect(sentBytes, equals([255, 252, 3]));
    });

    test('receiving DONT after local WONT should update state to NO and send nothing', () {
      const option = 3;
      manager.handleDo(option);
      manager.requestWont(option);
      sentBytes.clear();
      
      manager.handleDont(option);
      expect(sentBytes, isEmpty);
    });
  });
}
