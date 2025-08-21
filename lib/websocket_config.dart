/// Configuration for WebSocket connections.
class WebSocketConfig {
  /// The WebSocket URL to connect to.
  final String url;

  /// Connection timeout in milliseconds.
  final Duration connectionTimeout;

  /// Whether to enable automatic reconnection.
  final bool enableReconnection;

  /// Maximum number of reconnection attempts.
  final int maxReconnectionAttempts;

  /// Initial delay before first reconnection attempt.
  final Duration initialReconnectionDelay;

  /// Maximum delay between reconnection attempts.
  final Duration maxReconnectionDelay;

  /// Multiplier for exponential backoff.
  final double backoffMultiplier;

  /// Whether to enable message queuing.
  final bool enableMessageQueue;

  /// Maximum queue size for pending messages.
  final int maxQueueSize;

  /// Heartbeat interval in milliseconds.
  final Duration heartbeatInterval;

  /// Whether to enable ping/pong heartbeat.
  final bool enableHeartbeat;

  /// Custom headers for the WebSocket connection.
  final Map<String, String> headers;

  /// Protocols to use for the WebSocket connection.
  final List<String> protocols;

  /// Whether to enable compression.
  final bool enableCompression;

  /// Creates a new WebSocketConfig.
  const WebSocketConfig({
    required this.url,
    this.connectionTimeout = const Duration(seconds: 30),
    this.enableReconnection = true,
    this.maxReconnectionAttempts = 10,
    this.initialReconnectionDelay = const Duration(seconds: 1),
    this.maxReconnectionDelay = const Duration(minutes: 5),
    this.backoffMultiplier = 2.0,
    this.enableMessageQueue = true,
    this.maxQueueSize = 1000,
    this.heartbeatInterval = const Duration(seconds: 30),
    this.enableHeartbeat = true,
    this.headers = const {},
    this.protocols = const [],
    this.enableCompression = false,
  });

  /// Creates a WebSocketConfig with default settings for production use.
  const WebSocketConfig.production({
    required this.url,
    this.headers = const {},
    this.protocols = const [],
  })  : connectionTimeout = const Duration(seconds: 30),
        enableReconnection = true,
        maxReconnectionAttempts = 10,
        initialReconnectionDelay = const Duration(seconds: 1),
        maxReconnectionDelay = const Duration(minutes: 5),
        backoffMultiplier = 2.0,
        enableMessageQueue = true,
        maxQueueSize = 1000,
        heartbeatInterval = const Duration(seconds: 30),
        enableHeartbeat = true,
        enableCompression = false;

  /// Creates a WebSocketConfig with aggressive reconnection settings.
  const WebSocketConfig.aggressive({
    required this.url,
    this.headers = const {},
    this.protocols = const [],
  })  : connectionTimeout = const Duration(seconds: 15),
        enableReconnection = true,
        maxReconnectionAttempts = 20,
        initialReconnectionDelay = const Duration(milliseconds: 500),
        maxReconnectionDelay = const Duration(minutes: 2),
        backoffMultiplier = 1.5,
        enableMessageQueue = true,
        maxQueueSize = 2000,
        heartbeatInterval = const Duration(seconds: 15),
        enableHeartbeat = true,
        enableCompression = false;

  /// Creates a WebSocketConfig with minimal settings for testing.
  const WebSocketConfig.testing({
    required this.url,
    this.headers = const {},
    this.protocols = const [],
  })  : connectionTimeout = const Duration(seconds: 5),
        enableReconnection = false,
        maxReconnectionAttempts = 0,
        initialReconnectionDelay = Duration.zero,
        maxReconnectionDelay = Duration.zero,
        backoffMultiplier = 1.0,
        enableMessageQueue = false,
        maxQueueSize = 0,
        heartbeatInterval = Duration.zero,
        enableHeartbeat = false,
        enableCompression = false;

  /// Returns a copy of this config with updated values.
  WebSocketConfig copyWith({
    String? url,
    Duration? connectionTimeout,
    bool? enableReconnection,
    int? maxReconnectionAttempts,
    Duration? initialReconnectionDelay,
    Duration? maxReconnectionDelay,
    double? backoffMultiplier,
    bool? enableMessageQueue,
    int? maxQueueSize,
    Duration? heartbeatInterval,
    bool? enableHeartbeat,
    Map<String, String>? headers,
    List<String>? protocols,
    bool? enableCompression,
  }) {
    return WebSocketConfig(
      url: url ?? this.url,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      enableReconnection: enableReconnection ?? this.enableReconnection,
      maxReconnectionAttempts:
          maxReconnectionAttempts ?? this.maxReconnectionAttempts,
      initialReconnectionDelay:
          initialReconnectionDelay ?? this.initialReconnectionDelay,
      maxReconnectionDelay: maxReconnectionDelay ?? this.maxReconnectionDelay,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      enableMessageQueue: enableMessageQueue ?? this.enableMessageQueue,
      maxQueueSize: maxQueueSize ?? this.maxQueueSize,
      heartbeatInterval: heartbeatInterval ?? this.heartbeatInterval,
      enableHeartbeat: enableHeartbeat ?? this.enableHeartbeat,
      headers: headers ?? this.headers,
      protocols: protocols ?? this.protocols,
      enableCompression: enableCompression ?? this.enableCompression,
    );
  }

  /// Converts the config to a JSON representation.
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'connectionTimeout': connectionTimeout.inMilliseconds,
      'enableReconnection': enableReconnection,
      'maxReconnectionAttempts': maxReconnectionAttempts,
      'initialReconnectionDelay': initialReconnectionDelay.inMilliseconds,
      'maxReconnectionDelay': maxReconnectionDelay.inMilliseconds,
      'backoffMultiplier': backoffMultiplier,
      'enableMessageQueue': enableMessageQueue,
      'maxQueueSize': maxQueueSize,
      'heartbeatInterval': heartbeatInterval.inMilliseconds,
      'enableHeartbeat': enableHeartbeat,
      'headers': headers,
      'protocols': protocols,
      'enableCompression': enableCompression,
    };
  }

  /// Creates a config from JSON representation.
  factory WebSocketConfig.fromJson(Map<String, dynamic> json) {
    return WebSocketConfig(
      url: json['url'] as String,
      connectionTimeout:
          Duration(milliseconds: json['connectionTimeout'] as int? ?? 30000),
      enableReconnection: json['enableReconnection'] as bool? ?? true,
      maxReconnectionAttempts: json['maxReconnectionAttempts'] as int? ?? 10,
      initialReconnectionDelay: Duration(
          milliseconds: json['initialReconnectionDelay'] as int? ?? 1000),
      maxReconnectionDelay: Duration(
          milliseconds: json['maxReconnectionDelay'] as int? ?? 300000),
      backoffMultiplier: json['backoffMultiplier'] as double? ?? 2.0,
      enableMessageQueue: json['enableMessageQueue'] as bool? ?? true,
      maxQueueSize: json['maxQueueSize'] as int? ?? 1000,
      heartbeatInterval:
          Duration(milliseconds: json['heartbeatInterval'] as int? ?? 30000),
      enableHeartbeat: json['enableHeartbeat'] as bool? ?? true,
      headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
      protocols: List<String>.from(json['protocols'] as List? ?? []),
      enableCompression: json['enableCompression'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'WebSocketConfig(url: $url, enableReconnection: $enableReconnection, maxReconnectionAttempts: $maxReconnectionAttempts)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebSocketConfig &&
        other.url == url &&
        other.connectionTimeout == connectionTimeout &&
        other.enableReconnection == enableReconnection &&
        other.maxReconnectionAttempts == maxReconnectionAttempts &&
        other.initialReconnectionDelay == initialReconnectionDelay &&
        other.maxReconnectionDelay == maxReconnectionDelay &&
        other.backoffMultiplier == backoffMultiplier &&
        other.enableMessageQueue == enableMessageQueue &&
        other.maxQueueSize == maxQueueSize &&
        other.heartbeatInterval == heartbeatInterval &&
        other.enableHeartbeat == enableHeartbeat &&
        other.headers == headers &&
        other.protocols == protocols &&
        other.enableCompression == enableCompression;
  }

  @override
  int get hashCode {
    return Object.hash(
      url,
      connectionTimeout,
      enableReconnection,
      maxReconnectionAttempts,
      initialReconnectionDelay,
      maxReconnectionDelay,
      backoffMultiplier,
      enableMessageQueue,
      maxQueueSize,
      heartbeatInterval,
      enableHeartbeat,
      headers,
      protocols,
      enableCompression,
    );
  }
}
