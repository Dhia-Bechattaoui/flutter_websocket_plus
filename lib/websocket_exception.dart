/// Exception thrown when WebSocket operations fail.
class WebSocketException implements Exception {
  /// The error message describing what went wrong.
  final String message;

  /// The underlying error that caused this exception.
  final Object? cause;

  /// The stack trace at the time this exception was created.
  final StackTrace? stackTrace;

  /// Creates a new WebSocketException.
  const WebSocketException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  /// Creates a WebSocketException for connection failures.
  const WebSocketException.connectionFailed(
    String reason, {
    Object? cause,
    StackTrace? stackTrace,
  }) : this('Connection failed: $reason', cause: cause, stackTrace: stackTrace);

  /// Creates a WebSocketException for message sending failures.
  const WebSocketException.messageSendFailed(
    String reason, {
    Object? cause,
    StackTrace? stackTrace,
  }) : this('Failed to send message: $reason',
            cause: cause, stackTrace: stackTrace);

  /// Creates a WebSocketException for reconnection failures.
  const WebSocketException.reconnectionFailed(
    String reason, {
    Object? cause,
    StackTrace? stackTrace,
  }) : this('Reconnection failed: $reason',
            cause: cause, stackTrace: stackTrace);

  /// Creates a WebSocketException for timeout errors.
  const WebSocketException.timeout(
    String operation, {
    Object? cause,
    StackTrace? stackTrace,
  }) : this('$operation timed out', cause: cause, stackTrace: stackTrace);

  @override
  String toString() {
    if (cause != null) {
      return 'WebSocketException: $message (caused by: $cause)';
    }
    return 'WebSocketException: $message';
  }

  /// Returns a copy of this exception with updated fields.
  WebSocketException copyWith({
    String? message,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return WebSocketException(
      message ?? this.message,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }
}
