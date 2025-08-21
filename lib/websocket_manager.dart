import 'dart:async';
import 'websocket_connection.dart';
import 'websocket_config.dart';
import 'websocket_state.dart';
import 'websocket_message.dart';
import 'reconnection_strategy.dart';
import 'message_queue.dart';

/// Main manager class for WebSocket connections with reconnection and message queuing.
class WebSocketManager {
  /// The configuration for this manager.
  final WebSocketConfig config;

  /// The underlying WebSocket connection.
  WebSocketConnection? _connection;

  /// The reconnection strategy.
  final ReconnectionStrategy _reconnectionStrategy;

  /// The message queue for pending messages.
  final MessageQueue _messageQueue;

  /// Timer for reconnection attempts.
  Timer? _reconnectionTimer;

  /// Current reconnection attempt number.
  int _reconnectionAttempt = 0;

  /// Whether reconnection is in progress.
  bool _isReconnecting = false;

  /// Stream controller for manager state changes.
  final StreamController<WebSocketManagerState> _stateController =
      StreamController<WebSocketManagerState>.broadcast();

  /// Stream controller for manager events.
  final StreamController<WebSocketManagerEvent> _eventController =
      StreamController<WebSocketManagerEvent>.broadcast();

  /// Creates a new WebSocketManager.
  WebSocketManager({
    required WebSocketConfig config,
    ReconnectionStrategy? reconnectionStrategy,
    MessageQueue? messageQueue,
  })  : config = config,
        _reconnectionStrategy = reconnectionStrategy ??
            ReconnectionStrategyFactory.create(
              type: config.enableReconnection
                  ? ReconnectionStrategyType.exponential
                  : ReconnectionStrategyType.none,
              initialDelay: config.initialReconnectionDelay,
              maxDelay: config.maxReconnectionDelay,
            ),
        _messageQueue = messageQueue ??
            MessageQueue(
              maxSize: config.maxQueueSize,
              enablePriority: config.enableMessageQueue,
              enableDeduplication: config.enableMessageQueue,
            );

  /// Returns the current connection state.
  WebSocketState get connectionState =>
      _connection?.state ?? WebSocketState.initial;

  /// Returns true if the connection is active.
  bool get isConnected => _connection?.isConnected ?? false;

  /// Returns true if reconnection is in progress.
  bool get isReconnecting => _isReconnecting;

  /// Returns the current reconnection attempt number.
  int get reconnectionAttempt => _reconnectionAttempt;

  /// Returns the message queue statistics.
  Map<String, dynamic> get queueStatistics => _messageQueue.getStatistics();

  /// Returns the stream of manager state changes.
  Stream<WebSocketManagerState> get stateStream => _stateController.stream;

  /// Returns the stream of manager events.
  Stream<WebSocketManagerEvent> get eventStream => _eventController.stream;

  /// Returns the stream of connection state changes.
  Stream<WebSocketState> get connectionStateStream =>
      _connection?.stateStream ?? const Stream.empty();

  /// Returns the stream of incoming messages.
  Stream<WebSocketMessage> get messageStream =>
      _connection?.messageStream ?? const Stream.empty();

  /// Returns the stream of connection events.
  Stream<WebSocketEvent> get connectionEventStream =>
      _connection?.eventStream ?? const Stream.empty();

  /// Connects to the WebSocket server.
  Future<void> connect() async {
    if (_connection != null && _connection!.isActive) {
      return;
    }

    _eventController.add(WebSocketManagerEvent.connecting());

    try {
      _connection = WebSocketConnection(config);

      // Listen to connection state changes
      _connection!.stateStream.listen(_handleConnectionStateChange);

      // Listen to connection events
      _connection!.eventStream.listen(_handleConnectionEvent);

      // Connect to the server
      await _connection!.connect();

      // Process queued messages
      _processQueuedMessages();
    } catch (e) {
      _eventController
          .add(WebSocketManagerEvent.connectionFailed(e.toString()));

      if (config.enableReconnection) {
        _scheduleReconnection();
      }
    }
  }

  /// Disconnects from the WebSocket server.
  Future<void> disconnect() async {
    _isReconnecting = false;
    _reconnectionTimer?.cancel();
    _reconnectionStrategy.reset();
    _reconnectionAttempt = 0;

    await _connection?.disconnect();
    _connection = null;

    _eventController.add(WebSocketManagerEvent.disconnected());
  }

  /// Sends a message through the WebSocket connection.
  /// If the connection is not available, the message is queued.
  Future<bool> send(WebSocketMessage message) async {
    if (isConnected) {
      try {
        final success = await _connection!.send(message);
        if (success) {
          _eventController.add(WebSocketManagerEvent.messageSent(message));
          return true;
        }
      } catch (e) {
        _eventController
            .add(WebSocketManagerEvent.error('Failed to send message: $e'));
      }
    }

    // Queue message if connection is not available
    if (config.enableMessageQueue) {
      final queued = _messageQueue.enqueue(message);
      if (queued) {
        _eventController.add(WebSocketManagerEvent.messageQueued(message));
        return true;
      } else {
        _eventController
            .add(WebSocketManagerEvent.error('Message queue is full'));
        return false;
      }
    }

    return false;
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

  /// Handles connection state changes.
  void _handleConnectionStateChange(WebSocketState state) {
    _stateController.add(WebSocketManagerState(
      connectionState: state,
      isReconnecting: _isReconnecting,
      reconnectionAttempt: _reconnectionAttempt,
      queueSize: _messageQueue.size,
    ));

    switch (state) {
      case WebSocketState.connected:
        _isReconnecting = false;
        _reconnectionAttempt = 0;
        _reconnectionStrategy.reset();
        _eventController.add(WebSocketManagerEvent.connected());
        break;

      case WebSocketState.failed:
      case WebSocketState.closed:
        if (config.enableReconnection && !_isReconnecting) {
          _scheduleReconnection();
        }
        break;

      default:
        break;
    }
  }

  /// Handles connection events.
  void _handleConnectionEvent(WebSocketEvent event) {
    _eventController.add(WebSocketManagerEvent.fromConnectionEvent(event));
  }

  /// Schedules a reconnection attempt.
  void _scheduleReconnection() {
    if (_isReconnecting || !config.enableReconnection) {
      return;
    }

    _reconnectionAttempt++;

    if (!_reconnectionStrategy.shouldReconnect(
        _reconnectionAttempt, config.maxReconnectionAttempts)) {
      _eventController.add(WebSocketManagerEvent.reconnectionFailed(
          'Max reconnection attempts reached'));
      return;
    }

    _isReconnecting = true;
    _eventController
        .add(WebSocketManagerEvent.reconnecting(_reconnectionAttempt));

    final delay = _reconnectionStrategy.calculateDelay(_reconnectionAttempt);
    _reconnectionTimer = Timer(delay, () {
      _performReconnection();
    });
  }

  /// Performs the actual reconnection.
  Future<void> _performReconnection() async {
    try {
      await _connection?.disconnect();
      _connection = null;

      await connect();
    } catch (e) {
      _isReconnecting = false;
      _eventController
          .add(WebSocketManagerEvent.reconnectionFailed(e.toString()));

      // Schedule next reconnection attempt
      if (_reconnectionStrategy.shouldReconnect(
          _reconnectionAttempt + 1, config.maxReconnectionAttempts)) {
        _scheduleReconnection();
      }
    }
  }

  /// Processes queued messages when connection is established.
  void _processQueuedMessages() {
    if (!config.enableMessageQueue) return;

    while (!_messageQueue.isEmpty && isConnected) {
      final message = _messageQueue.dequeue();
      if (message != null) {
        send(message).catchError((e) {
          // Re-queue message if sending fails
          if (message.canRetry) {
            _messageQueue.enqueue(message.withRetry());
          }
          return false; // Return value for catchError
        });
      }
    }
  }

  /// Returns comprehensive statistics about the manager.
  Map<String, dynamic> getStatistics() {
    return {
      'connectionState': connectionState.name,
      'isConnected': isConnected,
      'isReconnecting': _isReconnecting,
      'reconnectionAttempt': _reconnectionAttempt,
      'queueStatistics': queueStatistics,
      'config': config.toJson(),
    };
  }

  /// Disposes of the manager and all resources.
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _eventController.close();
  }
}

/// Represents the state of the WebSocket manager.
class WebSocketManagerState {
  /// The current connection state.
  final WebSocketState connectionState;

  /// Whether reconnection is in progress.
  final bool isReconnecting;

  /// The current reconnection attempt number.
  final int reconnectionAttempt;

  /// The current queue size.
  final int queueSize;

  /// Creates a new WebSocketManagerState.
  const WebSocketManagerState({
    required this.connectionState,
    required this.isReconnecting,
    required this.reconnectionAttempt,
    required this.queueSize,
  });

  @override
  String toString() {
    return 'WebSocketManagerState(connectionState: $connectionState, isReconnecting: $isReconnecting, reconnectionAttempt: $reconnectionAttempt, queueSize: $queueSize)';
  }
}

/// Represents different types of WebSocket manager events.
class WebSocketManagerEvent {
  /// The event type.
  final String type;

  /// Event data.
  final dynamic data;

  /// Timestamp when the event occurred.
  final DateTime timestamp;

  /// Creates a new WebSocketManagerEvent.
  WebSocketManagerEvent({
    required this.type,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Event when connecting.
  WebSocketManagerEvent.connecting() : this(type: 'connecting');

  /// Event when connected.
  WebSocketManagerEvent.connected() : this(type: 'connected');

  /// Event when disconnected.
  WebSocketManagerEvent.disconnected() : this(type: 'disconnected');

  /// Event when connection fails.
  WebSocketManagerEvent.connectionFailed(String reason)
      : this(
          type: 'connectionFailed',
          data: reason,
        );

  /// Event when reconnecting.
  WebSocketManagerEvent.reconnecting(int attempt)
      : this(
          type: 'reconnecting',
          data: attempt,
        );

  /// Event when reconnection fails.
  WebSocketManagerEvent.reconnectionFailed(String reason)
      : this(
          type: 'reconnectionFailed',
          data: reason,
        );

  /// Event when a message is sent.
  WebSocketManagerEvent.messageSent(WebSocketMessage message)
      : this(
          type: 'messageSent',
          data: message,
        );

  /// Event when a message is queued.
  WebSocketManagerEvent.messageQueued(WebSocketMessage message)
      : this(
          type: 'messageQueued',
          data: message,
        );

  /// Event when an error occurs.
  WebSocketManagerEvent.error(String error)
      : this(
          type: 'error',
          data: error,
        );

  /// Creates an event from a connection event.
  WebSocketManagerEvent.fromConnectionEvent(WebSocketEvent event)
      : this(
          type: 'connection_${event.type}',
          data: event.data,
          timestamp: event.timestamp,
        );

  @override
  String toString() {
    return 'WebSocketManagerEvent(type: $type, data: $data, timestamp: $timestamp)';
  }
}
