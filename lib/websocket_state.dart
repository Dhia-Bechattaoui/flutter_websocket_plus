/// Enum representing the current state of a WebSocket connection.
enum WebSocketState {
  /// Initial state before connection attempt
  initial,

  /// Attempting to establish connection
  connecting,

  /// Connection is open and ready for communication
  connected,

  /// Connection is closing
  closing,

  /// Connection is closed
  closed,

  /// Connection failed to establish
  failed,

  /// Connection lost, attempting to reconnect
  reconnecting,

  /// Connection is in a suspended state
  suspended,
}

/// Extension methods for WebSocketState
extension WebSocketStateExtension on WebSocketState {
  /// Returns true if the connection is active (connected or connecting)
  bool get isActive =>
      this == WebSocketState.connected ||
      this == WebSocketState.connecting ||
      this == WebSocketState.reconnecting;

  /// Returns true if the connection is closed or failed
  bool get isClosed =>
      this == WebSocketState.closed || this == WebSocketState.failed;

  /// Returns true if the connection can send messages
  bool get canSend => this == WebSocketState.connected;

  /// Returns a human-readable description of the state
  String get description {
    switch (this) {
      case WebSocketState.initial:
        return 'Initial';
      case WebSocketState.connecting:
        return 'Connecting';
      case WebSocketState.connected:
        return 'Connected';
      case WebSocketState.closing:
        return 'Closing';
      case WebSocketState.closed:
        return 'Closed';
      case WebSocketState.failed:
        return 'Failed';
      case WebSocketState.reconnecting:
        return 'Reconnecting';
      case WebSocketState.suspended:
        return 'Suspended';
    }
  }
}
