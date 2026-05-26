import 'dart:typed_data';

enum OptionState { no, wantYes, wantYesOpposite, yes, wantNo, wantNoOpposite }

class NegotiationStateManager {
  static const int iac = 255;
  static const int dont = 254;
  static const int doCmd = 253;
  static const int wont = 252;
  static const int will = 251;
  static const int sb = 250;
  static const int ga = 249;
  static const int el = 248;
  static const int ec = 247;
  static const int ayt = 246;
  static const int ao = 245;
  static const int ip = 244;
  static const int brk = 243;
  static const int dm = 242;
  static const int nop = 241;
  static const int se = 240;

  static const int transmitBinary = 0;

  final void Function(Uint8List) onSend;
  final Map<int, OptionState> usStates = {};
  final Map<int, OptionState> themStates = {};

  NegotiationStateManager({required this.onSend});

  void handleDo(int option) {
    final state = usStates[option] ?? OptionState.no;
    switch (state) {
      case OptionState.no:
        // We agree to enable: send WILL, transition to yes
        _send(will, option);
        usStates[option] = OptionState.yes;
        break;
      case OptionState.wantYes:
        usStates[option] = OptionState.yes;
        break;
      case OptionState.wantYesOpposite:
        _send(wont, option);
        usStates[option] = OptionState.wantNo;
        break;
      case OptionState.yes:
        // Already enabled, do nothing
        break;
      case OptionState.wantNo:
        // Error. Accept anyway: transition to yes.
        usStates[option] = OptionState.yes;
        break;
      case OptionState.wantNoOpposite:
        usStates[option] = OptionState.yes;
        break;
    }
  }

  void handleDont(int option) {
    final state = usStates[option] ?? OptionState.no;
    switch (state) {
      case OptionState.no:
        // Already disabled, do nothing
        break;
      case OptionState.wantYes:
        usStates[option] = OptionState.no;
        break;
      case OptionState.wantYesOpposite:
        usStates[option] = OptionState.no;
        break;
      case OptionState.yes:
        // Required acknowledgement: send WONT, transition to no
        _send(wont, option);
        usStates[option] = OptionState.no;
        break;
      case OptionState.wantNo:
        usStates[option] = OptionState.no;
        break;
      case OptionState.wantNoOpposite:
        _send(will, option);
        usStates[option] = OptionState.wantYes;
        break;
    }
  }

  void handleWill(int option) {
    final state = themStates[option] ?? OptionState.no;
    switch (state) {
      case OptionState.no:
        // We agree to enable: send DO, transition to yes
        _send(doCmd, option);
        themStates[option] = OptionState.yes;
        break;
      case OptionState.wantYes:
        themStates[option] = OptionState.yes;
        break;
      case OptionState.wantYesOpposite:
        _send(dont, option);
        themStates[option] = OptionState.wantNo;
        break;
      case OptionState.yes:
        // Already enabled, do nothing
        break;
      case OptionState.wantNo:
        // Error. Accept anyway: transition to yes.
        themStates[option] = OptionState.yes;
        break;
      case OptionState.wantNoOpposite:
        themStates[option] = OptionState.yes;
        break;
    }
  }

  void handleWont(int option) {
    final state = themStates[option] ?? OptionState.no;
    switch (state) {
      case OptionState.no:
        // Already disabled, do nothing
        break;
      case OptionState.wantYes:
        themStates[option] = OptionState.no;
        break;
      case OptionState.wantYesOpposite:
        themStates[option] = OptionState.no;
        break;
      case OptionState.yes:
        // Required acknowledgement: send DONT, transition to no
        _send(dont, option);
        themStates[option] = OptionState.no;
        break;
      case OptionState.wantNo:
        themStates[option] = OptionState.no;
        break;
      case OptionState.wantNoOpposite:
        _send(doCmd, option);
        themStates[option] = OptionState.wantYes;
        break;
    }
  }

  void requestDo(int option) {
    final state = themStates[option] ?? OptionState.no;
    switch (state) {
      case OptionState.no:
        themStates[option] = OptionState.wantYes;
        _send(doCmd, option);
        break;
      case OptionState.wantNo:
        themStates[option] = OptionState.wantNoOpposite;
        break;
      case OptionState.wantYesOpposite:
        themStates[option] = OptionState.wantYes;
        break;
      case OptionState.yes:
      case OptionState.wantYes:
      case OptionState.wantNoOpposite:
        break;
    }
  }

  void requestDont(int option) {
    final state = themStates[option] ?? OptionState.no;
    switch (state) {
      case OptionState.yes:
        themStates[option] = OptionState.wantNo;
        _send(dont, option);
        break;
      case OptionState.wantYes:
        themStates[option] = OptionState.wantYesOpposite;
        break;
      case OptionState.wantNoOpposite:
        themStates[option] = OptionState.wantNo;
        break;
      case OptionState.no:
      case OptionState.wantNo:
      case OptionState.wantYesOpposite:
        break;
    }
  }

  void requestWill(int option) {
    final state = usStates[option] ?? OptionState.no;
    switch (state) {
      case OptionState.no:
        usStates[option] = OptionState.wantYes;
        _send(will, option);
        break;
      case OptionState.wantNo:
        usStates[option] = OptionState.wantNoOpposite;
        break;
      case OptionState.wantYesOpposite:
        usStates[option] = OptionState.wantYes;
        break;
      case OptionState.yes:
      case OptionState.wantYes:
      case OptionState.wantNoOpposite:
        break;
    }
  }

  void requestWont(int option) {
    final state = usStates[option] ?? OptionState.no;
    switch (state) {
      case OptionState.yes:
        usStates[option] = OptionState.wantNo;
        _send(wont, option);
        break;
      case OptionState.wantYes:
        usStates[option] = OptionState.wantYesOpposite;
        break;
      case OptionState.wantNoOpposite:
        usStates[option] = OptionState.wantNo;
        break;
      case OptionState.no:
      case OptionState.wantNo:
      case OptionState.wantYesOpposite:
        break;
    }
  }

  void _send(int command, int option) {
    onSend(Uint8List.fromList([iac, command, option]));
  }

  void handleCommand(List<int> bytes) {
    if (bytes.length < 2 || bytes[0] != iac) return;
    int command = bytes[1];

    if (command >= 251 && command <= 254) {
      if (bytes.length < 3) return;
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
    } else if (command == ayt) {
      handleAyt();
    }
  }

  void handleAyt() {
    // Respond with NOP as a default "I am here"
    onSend(Uint8List.fromList([iac, nop]));
  }
}
