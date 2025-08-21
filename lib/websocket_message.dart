/// Represents a WebSocket message with metadata and content.
class WebSocketMessage {
  /// The message content/payload.
  final dynamic data;

  /// The message type (text, binary, etc.).
  final String type;

  /// Timestamp when the message was created.
  final DateTime timestamp;

  /// Unique identifier for the message.
  final String id;

  /// Whether this message requires acknowledgment.
  final bool requiresAck;

  /// Retry count for failed message delivery.
  final int retryCount;

  /// Maximum number of retry attempts.
  final int maxRetries;

  /// Creates a new WebSocketMessage.
  WebSocketMessage({
    required this.data,
    this.type = 'text',
    DateTime? timestamp,
    String? id,
    this.requiresAck = false,
    this.retryCount = 0,
    this.maxRetries = 3,
  })  : timestamp = timestamp ?? DateTime.now(),
        id = id ?? _generateId();

  /// Creates a text message.
  WebSocketMessage.text(
    String text, {
    DateTime? timestamp,
    String? id,
    bool requiresAck = false,
  }) : this(
          data: text,
          type: 'text',
          timestamp: timestamp,
          id: id,
          requiresAck: requiresAck,
        );

  /// Creates a binary message.
  WebSocketMessage.binary(
    List<int> bytes, {
    DateTime? timestamp,
    String? id,
    bool requiresAck = false,
  }) : this(
          data: bytes,
          type: 'binary',
          timestamp: timestamp,
          id: id,
          requiresAck: requiresAck,
        );

  /// Creates a JSON message.
  WebSocketMessage.json(
    Map<String, dynamic> json, {
    DateTime? timestamp,
    String? id,
    bool requiresAck = false,
  }) : this(
          data: json,
          type: 'json',
          timestamp: timestamp,
          id: id,
          requiresAck: requiresAck,
        );

  /// Creates a ping message.
  WebSocketMessage.ping({
    DateTime? timestamp,
    String? id,
  }) : this(
          data: 'ping',
          type: 'ping',
          timestamp: timestamp,
          id: id,
          requiresAck: false,
        );

  /// Creates a pong message.
  WebSocketMessage.pong({
    DateTime? timestamp,
    String? id,
  }) : this(
          data: 'pong',
          type: 'pong',
          timestamp: timestamp,
          id: id,
          requiresAck: false,
        );

  /// Returns true if this message can be retried.
  bool get canRetry => retryCount < maxRetries;

  /// Returns true if this message is a control message (ping/pong).
  bool get isControl => type == 'ping' || type == 'pong';

  /// Returns true if this message is a text message.
  bool get isText => type == 'text';

  /// Returns true if this message is a binary message.
  bool get isBinary => type == 'binary';

  /// Returns true if this message is a JSON message.
  bool get isJson => type == 'json';

  /// Creates a copy of this message with updated retry count.
  WebSocketMessage withRetry() {
    return WebSocketMessage(
      data: data,
      type: type,
      timestamp: timestamp,
      id: id,
      requiresAck: requiresAck,
      retryCount: retryCount + 1,
      maxRetries: maxRetries,
    );
  }

  /// Converts the message to a JSON representation.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'requiresAck': requiresAck,
      'retryCount': retryCount,
      'maxRetries': maxRetries,
    };
  }

  /// Creates a message from JSON representation.
  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      id: json['id'] as String,
      type: json['type'] as String,
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp'] as String),
      requiresAck: json['requiresAck'] as bool? ?? false,
      retryCount: json['retryCount'] as int? ?? 0,
      maxRetries: json['maxRetries'] as int? ?? 3,
    );
  }

  @override
  String toString() {
    return 'WebSocketMessage(id: $id, type: $type, data: $data, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebSocketMessage &&
        other.id == id &&
        other.type == type &&
        other.data == data &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(id, type, data, timestamp);
  }

  /// Generates a unique ID for the message.
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (DateTime.now().microsecond % 1000)).toString();
  }
}
