import 'dart:typed_data';

enum OptionState {
  no,
  wantYes,
  yes,
  wantNo,
}

class NegotiationStateManager {
  static const int iac = 255;
  static const int dont = 254;
  static const int doCmd = 253;
  static const int wont = 252;
  static const int will = 251;

  final void Function(Uint8List) onSend;
  final Map<int, OptionState> usStates = {};
  final Map<int, OptionState> themStates = {};

  NegotiationStateManager({required this.onSend});

  void handleDo(int option) {
    final state = usStates[option] ?? OptionState.no;
    switch (state) {
      case OptionState.no:
        // For now, we agree to everything requested unless it's a security risk.
        // But for Task 2, we just follow the state transitions.
        _send(will, option);
        usStates[option] = OptionState.yes;
        break;
      case OptionState.wantYes:
        usStates[option] = OptionState.yes;
        break;
      case OptionState.yes:
        // Already enabled, do nothing.
        break;
      case OptionState.wantNo:
        // Should not happen?
        usStates[option] = OptionState.no;
        break;
    }
  }

  void handleDont(int option) {
    final state = usStates[option] ?? OptionState.no;
    switch (state) {
      case OptionState.no:
        // Already disabled, do nothing.
        break;
      case OptionState.wantYes:
        // They rejected our request to enable it.
        usStates[option] = OptionState.no;
        break;
      case OptionState.yes:
        // They want us to stop. Mandatory acknowledgment.
        _send(wont, option);
        usStates[option] = OptionState.no;
        break;
      case OptionState.wantNo:
        // Acknowledgment of our request to disable.
        usStates[option] = OptionState.no;
        break;
    }
  }

  void handleWill(int option) {
    final state = themStates[option] ?? OptionState.no;
    switch (state) {
      case OptionState.no:
        // Remote side says WILL. If we want them to do it, we say DO.
        // For now, we'll agree.
        _send(doCmd, option);
        themStates[option] = OptionState.yes;
        break;
      case OptionState.wantYes:
        themStates[option] = OptionState.yes;
        break;
      case OptionState.yes:
        // Already enabled.
        break;
      case OptionState.wantNo:
        // Should not happen?
        themStates[option] = OptionState.no;
        break;
    }
  }

  void handleWont(int option) {
    final state = themStates[option] ?? OptionState.no;
    switch (state) {
      case OptionState.no:
        // Already disabled.
        break;
      case OptionState.wantYes:
        // They rejected our request to have them enable it.
        themStates[option] = OptionState.no;
        break;
      case OptionState.yes:
        // They stopped doing it. Mandatory acknowledgment.
        _send(dont, option);
        themStates[option] = OptionState.no;
        break;
      case OptionState.wantNo:
        // Acknowledgment of our request to have them stop.
        themStates[option] = OptionState.no;
        break;
    }
  }

  void requestDo(int option) {
    final state = themStates[option] ?? OptionState.no;
    if (state == OptionState.no) {
      themStates[option] = OptionState.wantYes;
      _send(doCmd, option);
    }
  }

  void requestDont(int option) {
    final state = themStates[option] ?? OptionState.no;
    if (state == OptionState.yes) {
      themStates[option] = OptionState.wantNo;
      _send(dont, option);
    }
  }

  void requestWill(int option) {
    final state = usStates[option] ?? OptionState.no;
    if (state == OptionState.no) {
      usStates[option] = OptionState.wantYes;
      _send(will, option);
    }
  }

  void requestWont(int option) {
    final state = usStates[option] ?? OptionState.no;
    if (state == OptionState.yes) {
      usStates[option] = OptionState.wantNo;
      _send(wont, option);
    }
  }

  void _send(int command, int option) {
    onSend(Uint8List.fromList([iac, command, option]));
  }

  void handleCommand(List<int> bytes) {
    if (bytes.length < 3 || bytes[0] != iac) return;
    int command = bytes[1];
    int option = bytes[2];
    switch (command) {
      case will:
        handleWill(option);
        break;
      case wont:
        handleWont(option);
        break;
      case doCmd:
        handleDo(option);
        break;
      case dont:
        handleDont(option);
        break;
    }
  }
}
