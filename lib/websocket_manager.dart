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

  /// Subscription to connection state stream.
  StreamSubscription<WebSocketState>? _stateSubscription;

  /// Subscription to connection event stream.
  StreamSubscription<WebSocketEvent>? _eventSubscription;

  /// Whether the manager is disposed.
  bool _isDisposed = false;

  /// Creates a new WebSocketManager.
  WebSocketManager({
    required this.config,
    ReconnectionStrategy? reconnectionStrategy,
    MessageQueue? messageQueue,
  }) : _reconnectionStrategy =
           reconnectionStrategy ??
           ReconnectionStrategyFactory.create(
             type: config.enableReconnection
                 ? ReconnectionStrategyType.exponential
                 : ReconnectionStrategyType.none,
             initialDelay: config.initialReconnectionDelay,
             maxDelay: config.maxReconnectionDelay,
           ),
       _messageQueue =
           messageQueue ??
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

    _addEvent(WebSocketManagerEvent.connecting());

    try {
      _connection = WebSocketConnection(config);

      // Listen to connection state changes
      _stateSubscription = _connection!.stateStream.listen(
        _handleConnectionStateChange,
      );

      // Listen to connection events
      _eventSubscription = _connection!.eventStream.listen(
        _handleConnectionEvent,
      );

      // Connect to the server
      await _connection!.connect();

      // Process queued messages
      _processQueuedMessages();
    } catch (e) {
      _addEvent(WebSocketManagerEvent.connectionFailed(e.toString()));

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

    _addEvent(WebSocketManagerEvent.disconnected());
  }

  /// Sends a message through the WebSocket connection.
  /// If the connection is not available, the message is queued.
  Future<bool> send(WebSocketMessage message) async {
    if (isConnected) {
      try {
        final success = await _connection!.send(message);
        if (success) {
          _addEvent(WebSocketManagerEvent.messageSent(message));
          return true;
        }
      } catch (e) {
        _addEvent(WebSocketManagerEvent.error('Failed to send message: $e'));
      }
    }

    // Queue message if connection is not available
    if (config.enableMessageQueue) {
      final queued = _messageQueue.enqueue(message);
      if (queued) {
        _addEvent(WebSocketManagerEvent.messageQueued(message));
        return true;
      } else {
        _addEvent(WebSocketManagerEvent.error('Message queue is full'));
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

  /// Safely adds a state to the state controller.
  void _addState(WebSocketManagerState state) {
    if (!_isDisposed && !_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// Safely adds an event to the event controller.
  void _addEvent(WebSocketManagerEvent event) {
    if (!_isDisposed && !_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Handles connection state changes.
  void _handleConnectionStateChange(WebSocketState state) {
    _addState(
      WebSocketManagerState(
        connectionState: state,
        isReconnecting: _isReconnecting,
        reconnectionAttempt: _reconnectionAttempt,
        queueSize: _messageQueue.size,
      ),
    );

    switch (state) {
      case WebSocketState.connected:
        _isReconnecting = false;
        _reconnectionAttempt = 0;
        _reconnectionStrategy.reset();
        _addEvent(WebSocketManagerEvent.connected());
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
    _addEvent(WebSocketManagerEvent.fromConnectionEvent(event));
  }

  /// Schedules a reconnection attempt.
  void _scheduleReconnection() {
    if (_isReconnecting || !config.enableReconnection) {
      return;
    }

    _reconnectionAttempt++;

    if (!_reconnectionStrategy.shouldReconnect(
      _reconnectionAttempt,
      config.maxReconnectionAttempts,
    )) {
      _addEvent(
        WebSocketManagerEvent.reconnectionFailed(
          'Max reconnection attempts reached',
        ),
      );
      return;
    }

    _isReconnecting = true;
    _addEvent(WebSocketManagerEvent.reconnecting(_reconnectionAttempt));

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
      _addEvent(WebSocketManagerEvent.reconnectionFailed(e.toString()));

      // Schedule next reconnection attempt
      if (_reconnectionStrategy.shouldReconnect(
        _reconnectionAttempt + 1,
        config.maxReconnectionAttempts,
      )) {
        _scheduleReconnection();
      }
    }
  }

  /// Processes queued messages when connection is established.
  /// Uses efficient batch processing for better performance.
  void _processQueuedMessages() {
    if (!config.enableMessageQueue) return;

    // Process messages in batches to avoid blocking
    const batchSize = 10;
    int processed = 0;

    while (!_messageQueue.isEmpty && isConnected && processed < batchSize) {
      final message = _messageQueue.dequeue();
      if (message != null) {
        send(message).catchError((e) {
          // Re-queue message if sending fails and it can be retried
          if (message.canRetry) {
            _messageQueue.enqueue(message.withRetry());
            _addEvent(
              WebSocketManagerEvent.error(
                'Failed to send queued message, retrying: ${message.id}',
              ),
            );
          } else {
            _addEvent(
              WebSocketManagerEvent.error(
                'Failed to send queued message, max retries reached: ${message.id}',
              ),
            );
          }
          return false; // Return value for catchError
        });
        processed++;
      }
    }

    // If there are more messages, schedule another batch
    if (!_messageQueue.isEmpty && isConnected) {
      Future.microtask(() => _processQueuedMessages());
    }
  }

  /// Returns comprehensive statistics about the manager.
  Map<String, dynamic> getStatistics() {
    final connectionStats = _connection?.statistics ?? <String, dynamic>{};

    return {
      'connectionState': connectionState.name,
      'isConnected': isConnected,
      'isReconnecting': _isReconnecting,
      'reconnectionAttempt': _reconnectionAttempt,
      'queueStatistics': queueStatistics,
      'connectionStatistics': connectionStats,
      'config': config.toJson(),
      'uptime': _connection?.connectionDuration?.inMilliseconds,
    };
  }

  /// Disposes of the manager and all resources.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;

    // Cancel stream subscriptions first
    await _stateSubscription?.cancel();
    await _eventSubscription?.cancel();
    _stateSubscription = null;
    _eventSubscription = null;

    // Cancel reconnection timer
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;

    // Disconnect and dispose connection
    await _connection?.dispose();
    _connection = null;

    // Close controllers last
    if (!_stateController.isClosed) {
      await _stateController.close();
    }
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
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
  WebSocketManagerEvent({required this.type, this.data, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  /// Event when connecting.
  WebSocketManagerEvent.connecting() : this(type: 'connecting');

  /// Event when connected.
  WebSocketManagerEvent.connected() : this(type: 'connected');

  /// Event when disconnected.
  WebSocketManagerEvent.disconnected() : this(type: 'disconnected');

  /// Event when connection fails.
  WebSocketManagerEvent.connectionFailed(String reason)
    : this(type: 'connectionFailed', data: reason);

  /// Event when reconnecting.
  WebSocketManagerEvent.reconnecting(int attempt)
    : this(type: 'reconnecting', data: attempt);

  /// Event when reconnection fails.
  WebSocketManagerEvent.reconnectionFailed(String reason)
    : this(type: 'reconnectionFailed', data: reason);

  /// Event when a message is sent.
  WebSocketManagerEvent.messageSent(WebSocketMessage message)
    : this(type: 'messageSent', data: message);

  /// Event when a message is queued.
  WebSocketManagerEvent.messageQueued(WebSocketMessage message)
    : this(type: 'messageQueued', data: message);

  /// Event when an error occurs.
  WebSocketManagerEvent.error(String error) : this(type: 'error', data: error);

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
