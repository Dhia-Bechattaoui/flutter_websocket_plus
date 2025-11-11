import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'websocket_state.dart';
import 'websocket_message.dart';
import 'websocket_exception.dart';
import 'websocket_config.dart';

// Conditional import for native platforms
import 'websocket_connection_io.dart'
    if (dart.library.html) 'websocket_connection_web.dart'
    as platform;

/// Manages a single WebSocket connection with state management and event handling.
class WebSocketConnection {
  /// The configuration for this connection.
  final WebSocketConfig config;

  /// The current state of the connection.
  WebSocketState _state = WebSocketState.initial;

  /// The underlying WebSocket channel.
  WebSocketChannel? _channel;

  /// Stream controller for connection state changes.
  final StreamController<WebSocketState> _stateController =
      StreamController<WebSocketState>.broadcast();

  /// Stream controller for incoming messages.
  final StreamController<WebSocketMessage> _messageController =
      StreamController<WebSocketMessage>.broadcast();

  /// Stream controller for connection events.
  final StreamController<WebSocketEvent> _eventController =
      StreamController<WebSocketEvent>.broadcast();

  /// Timer for connection timeout.
  Timer? _connectionTimer;

  /// Timer for heartbeat.
  Timer? _heartbeatTimer;

  /// Connection start time.
  DateTime? _connectionStartTime;

  /// Last message timestamp.
  DateTime? _lastMessageTime;

  /// Connection statistics.
  final Map<String, dynamic> _statistics = {};

  /// Message counters for statistics.
  int _messagesSent = 0;
  int _messagesReceived = 0;
  int _errorsCount = 0;
  int _pingSent = 0;
  int _pongReceived = 0;
  DateTime? _lastPongTime;
  DateTime? _lastPingTime;

  /// Creates a new WebSocketConnection.
  WebSocketConnection(this.config);

  /// Returns the current connection state.
  WebSocketState get state => _state;

  /// Returns true if the connection is active.
  bool get isActive => _state.isActive;

  /// Returns true if the connection is connected.
  bool get isConnected => _state == WebSocketState.connected;

  /// Returns true if the connection is closed.
  bool get isClosed => _state.isClosed;

  /// Returns the stream of state changes.
  Stream<WebSocketState> get stateStream => _stateController.stream;

  /// Returns the stream of incoming messages.
  Stream<WebSocketMessage> get messageStream => _messageController.stream;

  /// Returns the stream of connection events.
  Stream<WebSocketEvent> get eventStream => _eventController.stream;

  /// Returns connection statistics.
  Map<String, dynamic> get statistics => Map.unmodifiable(_statistics);

  /// Returns the connection duration if connected.
  Duration? get connectionDuration {
    if (_connectionStartTime == null) return null;
    return DateTime.now().difference(_connectionStartTime!);
  }

  /// Returns the time since the last message.
  Duration? get timeSinceLastMessage {
    if (_lastMessageTime == null) return null;
    return DateTime.now().difference(_lastMessageTime!);
  }

  /// Connects to the WebSocket server.
  Future<void> connect() async {
    if (_state == WebSocketState.connecting ||
        _state == WebSocketState.connected) {
      return;
    }

    _updateState(WebSocketState.connecting);
    _connectionStartTime = DateTime.now();

    try {
      // Set connection timeout
      _connectionTimer = Timer(config.connectionTimeout, () {
        if (_state == WebSocketState.connecting) {
          _handleConnectionFailure('Connection timeout');
        }
      });

      // Create WebSocket connection with headers and protocols
      final uri = Uri.parse(config.url);

      // Use platform-specific helper for cross-platform compatibility
      // Native platforms support headers, web platform has limitations
      if (config.headers.isNotEmpty || config.protocols.isNotEmpty) {
        _channel = platform.PlatformWebSocketHelper.connect(
          uri,
          protocols: config.protocols.isNotEmpty ? config.protocols : null,
          headers: config.headers.isNotEmpty ? config.headers : null,
        );
      } else {
        _channel = WebSocketChannel.connect(uri);
      }

      // Listen for messages
      _channel!.stream.listen(
        _handleIncomingMessage,
        onError: _handleError,
        onDone: _handleConnectionClosed,
      );

      // Wait for connection to be established
      await _waitForConnection();

      // Start heartbeat if enabled
      if (config.enableHeartbeat) {
        _startHeartbeat();
      }

      _updateState(WebSocketState.connected);
      _eventController.add(WebSocketEvent.connected());
    } catch (e) {
      _handleConnectionFailure('Connection failed: $e');
    }
  }

  /// Disconnects from the WebSocket server.
  Future<void> disconnect() async {
    if (_state == WebSocketState.closed || _state == WebSocketState.failed) {
      return;
    }

    _updateState(WebSocketState.closing);

    // Stop timers
    _connectionTimer?.cancel();
    _heartbeatTimer?.cancel();

    // Close channel
    await _channel?.sink.close();
    _channel = null;

    _updateState(WebSocketState.closed);
    _eventController.add(WebSocketEvent.disconnected());
  }

  /// Sends a message through the WebSocket connection.
  Future<bool> send(WebSocketMessage message) async {
    if (!isConnected) {
      throw const WebSocketException.messageSendFailed(
        'Connection not established',
      );
    }

    try {
      if (message.isText) {
        _channel!.sink.add(message.data as String);
      } else if (message.isBinary) {
        _channel!.sink.add(message.data as List<int>);
      } else if (message.isJson) {
        // Properly serialize JSON using jsonEncode
        _channel!.sink.add(jsonEncode(message.data));
      } else if (message.isControl) {
        // For ping/pong, send as text message for application-level heartbeat
        _channel!.sink.add(message.data as String);
      } else {
        _channel!.sink.add(message.data.toString());
      }

      _lastMessageTime = DateTime.now();
      _messagesSent++;

      // Track ping/pong for heartbeat statistics
      if (message.type == 'ping') {
        _pingSent++;
        _lastPingTime = DateTime.now();
      }

      _eventController.add(WebSocketEvent.messageSent(message));
      _updateStatistics();

      return true;
    } catch (e) {
      _errorsCount++;
      _updateStatistics();
      throw WebSocketException.messageSendFailed('Failed to send message: $e');
    }
  }

  /// Sends a text message.
  Future<bool> sendText(String text) async {
    return send(WebSocketMessage.text(text));
  }

  /// Sends a binary message.
  Future<bool> sendBinary(List<int> bytes) async {
    return send(WebSocketMessage.binary(bytes));
  }

  /// Sends a JSON message.
  Future<bool> sendJson(Map<String, dynamic> json) async {
    return send(WebSocketMessage.json(json));
  }

  /// Sends a ping message.
  Future<bool> sendPing() async {
    return send(WebSocketMessage.ping());
  }

  /// Sends a pong message.
  Future<bool> sendPong() async {
    return send(WebSocketMessage.pong());
  }

  /// Updates the connection state and notifies listeners.
  void _updateState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
      _updateStatistics();
    }
  }

  /// Handles incoming messages from the WebSocket.
  void _handleIncomingMessage(dynamic data) {
    _lastMessageTime = DateTime.now();
    _messagesReceived++;

    WebSocketMessage message;
    if (data is String) {
      // Try to parse as JSON if it looks like JSON
      if (data.trim().startsWith('{') || data.trim().startsWith('[')) {
        try {
          final jsonData = jsonDecode(data);
          message = WebSocketMessage.json(jsonData);
        } catch (e) {
          // Not valid JSON, treat as text
          message = WebSocketMessage.text(data);
        }
      } else {
        message = WebSocketMessage.text(data);
      }
    } else if (data is List<int>) {
      message = WebSocketMessage.binary(data);
    } else {
      message = WebSocketMessage(data: data);
    }

    _messageController.add(message);
    _eventController.add(WebSocketEvent.messageReceived(message));

    // Handle control messages
    if (message.isControl) {
      _handleControlMessage(message);
    }

    _updateStatistics();
  }

  /// Handles control messages (ping/pong).
  void _handleControlMessage(WebSocketMessage message) {
    if (message.type == 'ping') {
      // Respond to ping with pong
      sendPong();
    } else if (message.type == 'pong') {
      // Update heartbeat statistics
      _lastPongTime = DateTime.now();
      _pongReceived++;
      _statistics['lastPongTime'] = _lastPongTime!.toIso8601String();
      _statistics['heartbeatLatency'] = _lastPingTime != null
          ? _lastPongTime!.difference(_lastPingTime!).inMilliseconds
          : null;
      _updateStatistics();
    }
  }

  /// Handles connection errors.
  void _handleError(dynamic error) {
    _errorsCount++;
    _eventController.add(WebSocketEvent.error(error.toString()));
    _updateStatistics();

    if (_state == WebSocketState.connecting) {
      _handleConnectionFailure('Connection error: $error');
    } else if (_state == WebSocketState.connected) {
      _handleConnectionFailure('Connection error: $error');
    }
  }

  /// Handles connection closure.
  void _handleConnectionClosed() {
    _connectionTimer?.cancel();
    _heartbeatTimer?.cancel();

    if (_state != WebSocketState.closed) {
      _updateState(WebSocketState.closed);
      _eventController.add(WebSocketEvent.disconnected());
    }
  }

  /// Handles connection failures.
  void _handleConnectionFailure(String reason) {
    _connectionTimer?.cancel();
    _heartbeatTimer?.cancel();

    _updateState(WebSocketState.failed);
    _eventController.add(WebSocketEvent.connectionFailed(reason));
  }

  /// Waits for the connection to be established.
  Future<void> _waitForConnection() async {
    // Simple wait for connection - in a real implementation,
    // you might want to check the actual connection state
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Starts the heartbeat timer.
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(config.heartbeatInterval, (timer) {
      if (isConnected) {
        // Check if we haven't received a pong in time (heartbeat timeout)
        if (_lastPingTime != null && _lastPongTime != null) {
          final timeSincePing = DateTime.now().difference(_lastPingTime!);
          final timeSincePong = DateTime.now().difference(_lastPongTime!);

          // If we sent a ping but haven't received pong in 2x heartbeat interval, consider it failed
          if (timeSincePing.inMilliseconds >
                  config.heartbeatInterval.inMilliseconds * 2 &&
              timeSincePong.inMilliseconds >
                  config.heartbeatInterval.inMilliseconds * 2) {
            _eventController.add(
              WebSocketEvent.error('Heartbeat timeout - no pong received'),
            );
            _errorsCount++;
            _updateStatistics();
          }
        }

        sendPing();
      } else {
        timer.cancel();
      }
    });
  }

  /// Updates connection statistics.
  void _updateStatistics() {
    _statistics['currentState'] = _state.name;
    _statistics['lastStateChange'] = DateTime.now().toIso8601String();
    _statistics['messagesSent'] = _messagesSent;
    _statistics['messagesReceived'] = _messagesReceived;
    _statistics['errorsCount'] = _errorsCount;
    _statistics['pingSent'] = _pingSent;
    _statistics['pongReceived'] = _pongReceived;

    if (_connectionStartTime != null) {
      _statistics['connectionStartTime'] = _connectionStartTime!
          .toIso8601String();
      _statistics['connectionDuration'] = DateTime.now()
          .difference(_connectionStartTime!)
          .inMilliseconds;
    }

    if (_lastMessageTime != null) {
      _statistics['lastMessageTime'] = _lastMessageTime!.toIso8601String();
      _statistics['timeSinceLastMessage'] = DateTime.now()
          .difference(_lastMessageTime!)
          .inMilliseconds;
    }

    if (_lastPongTime != null) {
      _statistics['lastPongTime'] = _lastPongTime!.toIso8601String();
      _statistics['timeSinceLastPong'] = DateTime.now()
          .difference(_lastPongTime!)
          .inMilliseconds;
    }

    if (_lastPingTime != null) {
      _statistics['lastPingTime'] = _lastPingTime!.toIso8601String();
      _statistics['timeSinceLastPing'] = DateTime.now()
          .difference(_lastPingTime!)
          .inMilliseconds;
    }

    // Calculate heartbeat health
    if (_pingSent > 0 && _pongReceived > 0) {
      _statistics['heartbeatHealth'] =
          '${(_pongReceived / _pingSent * 100).toStringAsFixed(2)}%';
    }
  }

  /// Disposes of the connection and all resources.
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _messageController.close();
    await _eventController.close();
  }
}

/// Represents different types of WebSocket events.
class WebSocketEvent {
  /// The event type.
  final String type;

  /// Event data.
  final dynamic data;

  /// Timestamp when the event occurred.
  final DateTime timestamp;

  /// Creates a new WebSocketEvent.
  WebSocketEvent({required this.type, this.data, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  /// Event when connection is established.
  WebSocketEvent.connected() : this(type: 'connected');

  /// Event when connection is lost.
  WebSocketEvent.disconnected() : this(type: 'disconnected');

  /// Event when connection fails.
  WebSocketEvent.connectionFailed(String reason)
    : this(type: 'connectionFailed', data: reason);

  /// Event when a message is sent.
  WebSocketEvent.messageSent(WebSocketMessage message)
    : this(type: 'messageSent', data: message);

  /// Event when a message is received.
  WebSocketEvent.messageReceived(WebSocketMessage message)
    : this(type: 'messageReceived', data: message);

  /// Event when an error occurs.
  WebSocketEvent.error(String error) : this(type: 'error', data: error);

  @override
  String toString() {
    return 'WebSocketEvent(type: $type, data: $data, timestamp: $timestamp)';
  }
}
