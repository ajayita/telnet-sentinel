import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:telnet_sentinel/models/telnet_event.dart';

class TelnetTransport {
  static const int _maxRawBytes = 4096;

  final RawSocket _socket;
  final StreamController<TelnetEvent> _controller =
      StreamController<TelnetEvent>.broadcast();
  final List<int> _pendingBytes = [];
  final List<int> _rawBytesExchanged = [];

  bool _isDecompressing = false;
  ByteConversionSink? _decompressorSink;
  bool _isProcessing = false;

  /// Returns the raw bytes exchanged during this transport session,
  /// capped at [_maxRawBytes] to prevent unbounded memory growth.
  List<int> get rawBytesExchanged => List.unmodifiable(_rawBytesExchanged);

  TelnetTransport(this._socket) {
    _socket.listen(_onSocketEvent, onDone: _onDone, onError: _onError);
  }

  Stream<TelnetEvent> get events => _controller.stream;

  void _onSocketEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final bytes = _socket.read();
      if (bytes != null) {
        _appendRawBytes(bytes);
        if (_isDecompressing) {
          _decompressorSink?.add(bytes);
        } else {
          _processBytes(bytes);
        }
      }
    } else if (event == RawSocketEvent.readClosed) {
      _onDone();
    }
  }

  void _appendRawBytes(List<int> bytes) {
    final remaining = _maxRawBytes - _rawBytesExchanged.length;
    if (remaining > 0) {
      _rawBytesExchanged.addAll(
        bytes.take(remaining),
      );
    }
  }

  void _onDone() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  void _onError(Object error) {
    if (!_controller.isClosed) {
      _controller.addError(error);
    }
  }

  void _processBytes(List<int> bytes, {bool fromDecompressor = false}) {
    _pendingBytes.addAll(bytes);

    if (_isProcessing) {
      return;
    }
    _isProcessing = true;

    try {
      while (_pendingBytes.isNotEmpty) {
        if (_pendingBytes[0] == 255) {
          // IAC
          if (_pendingBytes.length >= 2) {
            int command = _pendingBytes[1];
            // 3-byte commands: WILL, WONT, DO, DONT (251-254)
            if (command >= 251 && command <= 254) {
              if (_pendingBytes.length >= 3) {
                _controller.add(
                  TelnetEvent(
                    TelnetEventType.iac,
                    Uint8List.fromList(_pendingBytes.sublist(0, 3)),
                  ),
                );
                _pendingBytes.removeRange(0, 3);
              } else {
                break; // Wait for more bytes
              }
            } else if (command == 250) {
              // SB (Subnegotiation)
              // Search for SE (IAC SE = 255 240)
              int seIndex = -1;
              for (int j = 2; j < _pendingBytes.length - 1; j++) {
                if (_pendingBytes[j] == 255) {
                  if (_pendingBytes[j + 1] == 240) {
                    seIndex = j + 1;
                    break;
                  } else if (_pendingBytes[j + 1] == 255) {
                    // Escaped IAC inside SB, skip the second IAC
                    j++;
                  }
                }
              }
              if (seIndex != -1) {
                final sbBytes = _pendingBytes.sublist(0, seIndex + 1);
                _controller.add(
                  TelnetEvent(TelnetEventType.iac, Uint8List.fromList(sbBytes)),
                );
                _pendingBytes.removeRange(0, seIndex + 1);

                // MCCP2 check: IAC SB 86 IAC SE
                if (sbBytes.length == 5 &&
                    sbBytes[2] == 86 &&
                    !_isDecompressing &&
                    !fromDecompressor) {
                  _startDecompression();
                  if (_pendingBytes.isNotEmpty) {
                    final remaining = List<int>.from(_pendingBytes);
                    _pendingBytes.clear();
                    _decompressorSink?.add(remaining);
                  }
                  continue;
                }
              } else {
                break; // Wait for more bytes
              }
            } else if (command == 255) {
              // Escaped IAC
              _controller.add(
                TelnetEvent(TelnetEventType.data, Uint8List.fromList([255])),
              );
              _pendingBytes.removeRange(0, 2);
            } else {
              // 2-byte command
              _controller.add(
                TelnetEvent(
                  TelnetEventType.iac,
                  Uint8List.fromList(_pendingBytes.sublist(0, 2)),
                ),
              );
              _pendingBytes.removeRange(0, 2);
            }
          } else {
            break; // Wait for more bytes
          }
        } else {
          // Data: find the next IAC or end of buffer
          int iacIndex = _pendingBytes.indexOf(255);
          if (iacIndex == -1) {
            _controller.add(
              TelnetEvent(
                TelnetEventType.data,
                Uint8List.fromList(_pendingBytes),
              ),
            );
            _pendingBytes.clear();
          } else {
            _controller.add(
              TelnetEvent(
                TelnetEventType.data,
                Uint8List.fromList(_pendingBytes.sublist(0, iacIndex)),
              ),
            );
            _pendingBytes.removeRange(0, iacIndex);
          }
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> close() async {
    _decompressorSink?.close();
    try {
      _socket.shutdown(SocketDirection.both);
    } finally {
      _socket.close();
      _onDone();
    }
  }

  void write(List<int> bytes) {
    _appendRawBytes(bytes);
    _socket.write(bytes);
  }

  void _startDecompression() {
    _isDecompressing = true;
    _decompressorSink = zlib.decoder.startChunkedConversion(
      _DecompressionSink((decompressed) {
        _processBytes(decompressed, fromDecompressor: true);
      }),
    );
  }
}

class _DecompressionSink implements Sink<List<int>> {
  final void Function(List<int>) onData;
  _DecompressionSink(this.onData);

  @override
  void add(List<int> chunk) {
    onData(chunk);
  }

  @override
  void close() {}
}
