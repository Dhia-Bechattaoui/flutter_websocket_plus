import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_websocket_plus/flutter_websocket_plus.dart';

void main() {
  group('WebSocketState', () {
    test('should have correct state values', () {
      expect(WebSocketState.initial, isA<WebSocketState>());
      expect(WebSocketState.connecting, isA<WebSocketState>());
      expect(WebSocketState.connected, isA<WebSocketState>());
      expect(WebSocketState.closing, isA<WebSocketState>());
      expect(WebSocketState.closed, isA<WebSocketState>());
      expect(WebSocketState.failed, isA<WebSocketState>());
      expect(WebSocketState.reconnecting, isA<WebSocketState>());
      expect(WebSocketState.suspended, isA<WebSocketState>());
    });

    test('should have correct extension methods', () {
      expect(WebSocketState.initial.isActive, false);
      expect(WebSocketState.connecting.isActive, true);
      expect(WebSocketState.connected.isActive, true);
      expect(WebSocketState.reconnecting.isActive, true);
      expect(WebSocketState.closed.isActive, false);
      expect(WebSocketState.failed.isActive, false);

      expect(WebSocketState.initial.isClosed, false);
      expect(WebSocketState.connected.isClosed, false);
      expect(WebSocketState.closed.isClosed, true);
      expect(WebSocketState.failed.isClosed, true);

      expect(WebSocketState.initial.canSend, false);
      expect(WebSocketState.connected.canSend, true);
      expect(WebSocketState.closed.canSend, false);
    });

    test('should have correct descriptions', () {
      expect(WebSocketState.initial.description, 'Initial');
      expect(WebSocketState.connected.description, 'Connected');
      expect(WebSocketState.failed.description, 'Failed');
    });
  });

  group('WebSocketException', () {
    test('should create exception with message', () {
      final exception = WebSocketException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.cause, null);
      expect(exception.stackTrace, null);
    });

    test('should create connection failed exception', () {
      final exception = WebSocketException.connectionFailed('Connection error');
      expect(exception.message, 'Connection failed: Connection error');
    });

    test('should create message send failed exception', () {
      final exception = WebSocketException.messageSendFailed('Send error');
      expect(exception.message, 'Failed to send message: Send error');
    });

    test('should create reconnection failed exception', () {
      final exception =
          WebSocketException.reconnectionFailed('Reconnection error');
      expect(exception.message, 'Reconnection failed: Reconnection error');
    });

    test('should create timeout exception', () {
      final exception = WebSocketException.timeout('Operation');
      expect(exception.message, 'Operation timed out');
    });

    test('should copy with new values', () {
      final original = WebSocketException('Original');
      final copy = original.copyWith(message: 'New message');
      expect(copy.message, 'New message');
      expect(copy.cause, original.cause);
    });

    test('should have correct string representation', () {
      final exception = WebSocketException('Test error');
      expect(exception.toString(), 'WebSocketException: Test error');
    });
  });

  group('WebSocketMessage', () {
    test('should create text message', () {
      final message = WebSocketMessage.text('Hello');
      expect(message.data, 'Hello');
      expect(message.type, 'text');
      expect(message.requiresAck, false);
      expect(message.retryCount, 0);
      expect(message.maxRetries, 3);
    });

    test('should create binary message', () {
      final bytes = [1, 2, 3, 4];
      final message = WebSocketMessage.binary(bytes);
      expect(message.data, bytes);
      expect(message.type, 'binary');
      expect(message.isBinary, true);
    });

    test('should create JSON message', () {
      final json = {'key': 'value'};
      final message = WebSocketMessage.json(json);
      expect(message.data, json);
      expect(message.type, 'json');
      expect(message.isJson, true);
    });

    test('should create ping message', () {
      final message = WebSocketMessage.ping();
      expect(message.data, 'ping');
      expect(message.type, 'ping');
      expect(message.isControl, true);
    });

    test('should create pong message', () {
      final message = WebSocketMessage.pong();
      expect(message.data, 'pong');
      expect(message.type, 'pong');
      expect(message.isControl, true);
    });

    test('should check retry capability', () {
      final message = WebSocketMessage.text('Test');
      expect(message.canRetry, true);

      final retriedMessage = message.withRetry();
      expect(retriedMessage.retryCount, 1);
      expect(retriedMessage.canRetry, true);

      final maxRetriedMessage = WebSocketMessage(
        data: 'Test',
        maxRetries: 1,
      ).withRetry();
      expect(maxRetriedMessage.canRetry, false);
    });

    test('should convert to and from JSON', () {
      final original = WebSocketMessage.text('Test', requiresAck: true);
      final json = original.toJson();
      final restored = WebSocketMessage.fromJson(json);

      expect(restored.data, original.data);
      expect(restored.type, original.type);
      expect(restored.requiresAck, original.requiresAck);
    });

    test('should have unique IDs', () {
      final message1 = WebSocketMessage.text('Test 1', id: 'id1');
      final message2 = WebSocketMessage.text('Test 2', id: 'id2');
      expect(message1.id, isNot(message2.id));
    });
  });

  group('WebSocketConfig', () {
    test('should create with default values', () {
      final config = WebSocketConfig(url: 'ws://test.com');
      expect(config.url, 'ws://test.com');
      expect(config.enableReconnection, true);
      expect(config.maxReconnectionAttempts, 10);
      expect(config.enableMessageQueue, true);
      expect(config.enableHeartbeat, true);
    });

    test('should create production config', () {
      final config = WebSocketConfig.production(url: 'ws://test.com');
      expect(config.url, 'ws://test.com');
      expect(config.enableReconnection, true);
      expect(config.enableMessageQueue, true);
    });

    test('should create aggressive config', () {
      final config = WebSocketConfig.aggressive(url: 'ws://test.com');
      expect(config.url, 'ws://test.com');
      expect(config.maxReconnectionAttempts, 20);
      expect(config.initialReconnectionDelay.inMilliseconds, 500);
    });

    test('should create testing config', () {
      final config = WebSocketConfig.testing(url: 'ws://test.com');
      expect(config.url, 'ws://test.com');
      expect(config.enableReconnection, false);
      expect(config.enableMessageQueue, false);
      expect(config.enableHeartbeat, false);
    });

    test('should copy with new values', () {
      final original = WebSocketConfig(url: 'ws://test.com');
      final copy = original.copyWith(
        enableReconnection: false,
        maxReconnectionAttempts: 5,
      );

      expect(copy.url, original.url);
      expect(copy.enableReconnection, false);
      expect(copy.maxReconnectionAttempts, 5);
    });

    test('should convert to and from JSON', () {
      final original = WebSocketConfig(url: 'ws://test.com');
      final json = original.toJson();
      final restored = WebSocketConfig.fromJson(json);

      expect(restored.url, original.url);
      expect(restored.enableReconnection, original.enableReconnection);
      expect(
          restored.maxReconnectionAttempts, original.maxReconnectionAttempts);
    });
  });

  group('ReconnectionStrategy', () {
    test('should create exponential backoff strategy', () {
      final strategy = ExponentialBackoffStrategy();
      expect(strategy.initialDelay, const Duration(seconds: 1));
      expect(strategy.maxDelay, const Duration(minutes: 5));
      expect(strategy.multiplier, 2.0);
    });

    test('should calculate exponential delays', () {
      final strategy = ExponentialBackoffStrategy();

      final delay1 = strategy.calculateDelay(1);
      final delay2 = strategy.calculateDelay(2);
      final delay3 = strategy.calculateDelay(3);

      expect(delay1.inMilliseconds, greaterThan(0));
      expect(delay2.inMilliseconds, greaterThan(delay1.inMilliseconds));
      expect(delay3.inMilliseconds, greaterThan(delay2.inMilliseconds));
    });

    test('should create linear backoff strategy', () {
      final strategy = LinearBackoffStrategy();
      expect(strategy.initialDelay, const Duration(seconds: 1));
      expect(strategy.increment, const Duration(seconds: 1));
    });

    test('should calculate linear delays', () {
      final strategy = LinearBackoffStrategy();

      final delay1 = strategy.calculateDelay(1);
      final delay2 = strategy.calculateDelay(2);
      final delay3 = strategy.calculateDelay(3);

      expect(delay1.inMilliseconds, 1000);
      expect(delay2.inMilliseconds, 2000);
      expect(delay3.inMilliseconds, 3000);
    });

    test('should create fixed delay strategy', () {
      final strategy = FixedDelayStrategy();
      expect(strategy.delay, const Duration(seconds: 5));
    });

    test('should calculate fixed delays', () {
      final strategy = FixedDelayStrategy();

      final delay1 = strategy.calculateDelay(1);
      final delay2 = strategy.calculateDelay(5);

      expect(delay1.inMilliseconds, 5000);
      expect(delay2.inMilliseconds, 5000);
    });

    test('should create no reconnection strategy', () {
      final strategy = NoReconnectionStrategy();
      expect(strategy.shouldReconnect(1, 10), false);
    });

    test('should use factory to create strategies', () {
      final exponential = ReconnectionStrategyFactory.create(
        type: ReconnectionStrategyType.exponential,
      );
      expect(exponential, isA<ExponentialBackoffStrategy>());

      final linear = ReconnectionStrategyFactory.create(
        type: ReconnectionStrategyType.linear,
      );
      expect(linear, isA<LinearBackoffStrategy>());

      final fixed = ReconnectionStrategyFactory.create(
        type: ReconnectionStrategyType.fixed,
      );
      expect(fixed, isA<FixedDelayStrategy>());

      final none = ReconnectionStrategyFactory.create(
        type: ReconnectionStrategyType.none,
      );
      expect(none, isA<NoReconnectionStrategy>());
    });
  });

  group('MessageQueue', () {
    test('should create empty queue', () {
      final queue = MessageQueue();
      expect(queue.isEmpty, true);
      expect(queue.size, 0);
      expect(queue.isFull, false);
    });

    test('should enqueue and dequeue messages', () {
      final queue = MessageQueue();
      final message = WebSocketMessage.text('Test');

      expect(queue.enqueue(message), true);
      expect(queue.size, 1);
      expect(queue.isEmpty, false);

      final dequeued = queue.dequeue();
      expect(dequeued, message);
      expect(queue.size, 0);
      expect(queue.isEmpty, true);
    });

    test('should respect max size', () {
      final queue = MessageQueue(maxSize: 2);

      expect(queue.enqueue(WebSocketMessage.text('1', id: 'msg-1')), true);
      expect(queue.enqueue(WebSocketMessage.text('2', id: 'msg-2')), true);
      expect(queue.enqueue(WebSocketMessage.text('3', id: 'msg-3')), false);
      expect(queue.size, 2);
    });

    test('should handle deduplication', () {
      final queue = MessageQueue(enableDeduplication: true);
      final message1 = WebSocketMessage.text('Test', id: 'same-id');
      final message2 = WebSocketMessage.text('Test', id: 'same-id');

      expect(queue.enqueue(message1), true);
      expect(queue.enqueue(message2), false);
      expect(queue.size, 1);
    });

    test('should prioritize messages', () {
      final queue = MessageQueue(enablePriority: true);

      final normalMessage = WebSocketMessage.text('Normal', id: 'normal-1');
      final priorityMessage = WebSocketMessage.text('Priority',
          requiresAck: true, id: 'priority-1');
      final controlMessage = WebSocketMessage.ping(id: 'ping-1');

      queue.enqueue(normalMessage);
      queue.enqueue(priorityMessage);
      queue.enqueue(controlMessage);

      // Control messages should have highest priority
      final first = queue.dequeue();
      expect(first?.type, 'ping');

      // Messages requiring ack should have higher priority than normal messages
      final second = queue.dequeue();
      expect(second?.requiresAck, true);

      // Normal message should be last
      final third = queue.dequeue();
      expect(third?.requiresAck, false);
      expect(third?.type, 'text');
    });

    test('should handle retry counts', () {
      final queue = MessageQueue();
      final message = WebSocketMessage.text('Test');

      queue.enqueue(message);
      expect(queue.retryableCount, 1);

      queue.updateRetryCount(message.id);
      expect(queue.retryableCount, 1); // Still retryable

      final updatedMessage = queue.peek();
      expect(updatedMessage?.retryCount, 1);
    });

    test('should provide statistics', () {
      final queue = MessageQueue();
      final stats = queue.getStatistics();

      expect(stats['size'], 0);
      expect(stats['isEmpty'], true);
      expect(stats['enablePriority'], true);
      expect(stats['enableDeduplication'], true);
    });

    test('should convert to and from JSON', () {
      final queue = MessageQueue();
      queue.enqueue(WebSocketMessage.text('Test'));

      final json = queue.toJson();
      final restored = MessageQueue.fromJson(json);

      expect(restored.size, queue.size);
      expect(restored.maxSize, queue.maxSize);
    });
  });

  group('WebSocketManager', () {
    test('should create manager with config', () {
      final config = WebSocketConfig(url: 'ws://test.com');
      final manager = WebSocketManager(config: config);

      expect(manager.config, config);
      expect(manager.connectionState, WebSocketState.initial);
      expect(manager.isConnected, false);
      expect(manager.isReconnecting, false);
    });

    test('should have correct stream properties', () {
      final config = WebSocketConfig(url: 'ws://test.com');
      final manager = WebSocketManager(config: config);

      expect(manager.stateStream, isA<Stream<WebSocketManagerState>>());
      expect(manager.eventStream, isA<Stream<WebSocketManagerEvent>>());
      expect(manager.connectionStateStream, isA<Stream<WebSocketState>>());
      expect(manager.messageStream, isA<Stream<WebSocketMessage>>());
      expect(manager.connectionEventStream, isA<Stream<WebSocketEvent>>());
    });

    test('should provide queue statistics', () {
      final config = WebSocketConfig(url: 'ws://test.com');
      final manager = WebSocketManager(config: config);

      final stats = manager.queueStatistics;
      expect(stats['size'], 0);
      expect(stats['isEmpty'], true);
    });

    test('should provide comprehensive statistics', () {
      final config = WebSocketConfig(url: 'ws://test.com');
      final manager = WebSocketManager(config: config);

      final stats = manager.getStatistics();
      expect(stats['connectionState'], 'initial');
      expect(stats['isConnected'], false);
      expect(stats['isReconnecting'], false);
      expect(stats['reconnectionAttempt'], 0);
      expect(stats['config'], isA<Map<String, dynamic>>());
    });
  });

  group('WebSocketManagerState', () {
    test('should create state with all properties', () {
      final state = WebSocketManagerState(
        connectionState: WebSocketState.connected,
        isReconnecting: false,
        reconnectionAttempt: 0,
        queueSize: 5,
      );

      expect(state.connectionState, WebSocketState.connected);
      expect(state.isReconnecting, false);
      expect(state.reconnectionAttempt, 0);
      expect(state.queueSize, 5);
    });

    test('should have correct string representation', () {
      final state = WebSocketManagerState(
        connectionState: WebSocketState.connected,
        isReconnecting: false,
        reconnectionAttempt: 0,
        queueSize: 0,
      );

      expect(state.toString(), contains('WebSocketManagerState'));
      expect(state.toString(), contains('connected'));
    });
  });

  group('WebSocketManagerEvent', () {
    test('should create connecting event', () {
      final event = WebSocketManagerEvent.connecting();
      expect(event.type, 'connecting');
      expect(event.data, null);
    });

    test('should create connected event', () {
      final event = WebSocketManagerEvent.connected();
      expect(event.type, 'connected');
      expect(event.data, null);
    });

    test('should create connection failed event', () {
      final event = WebSocketManagerEvent.connectionFailed('Test error');
      expect(event.type, 'connectionFailed');
      expect(event.data, 'Test error');
    });

    test('should create reconnecting event', () {
      final event = WebSocketManagerEvent.reconnecting(3);
      expect(event.type, 'reconnecting');
      expect(event.data, 3);
    });

    test('should create message sent event', () {
      final message = WebSocketMessage.text('Test');
      final event = WebSocketManagerEvent.messageSent(message);
      expect(event.type, 'messageSent');
      expect(event.data, message);
    });

    test('should create message queued event', () {
      final message = WebSocketMessage.text('Test');
      final event = WebSocketManagerEvent.messageQueued(message);
      expect(event.type, 'messageQueued');
      expect(event.data, message);
    });

    test('should create error event', () {
      final event = WebSocketManagerEvent.error('Test error');
      expect(event.type, 'error');
      expect(event.data, 'Test error');
    });

    test('should have correct string representation', () {
      final event = WebSocketManagerEvent.connecting();
      expect(event.toString(), contains('WebSocketManagerEvent'));
      expect(event.toString(), contains('connecting'));
    });
  });

  group('Integration Tests', () {
    test('should handle complete message flow', () {
      final config = WebSocketConfig.testing(url: 'ws://test.com');
      final manager = WebSocketManager(config: config);

      expect(manager.connectionState, WebSocketState.initial);
      expect(manager.isConnected, false);
      expect(manager.queueStatistics['size'], 0);
    });

    test('should handle configuration presets', () {
      final productionConfig = WebSocketConfig.production(url: 'ws://prod.com');
      expect(productionConfig.enableReconnection, true);
      expect(productionConfig.enableMessageQueue, true);

      final testingConfig = WebSocketConfig.testing(url: 'ws://test.com');
      expect(testingConfig.enableReconnection, false);
      expect(testingConfig.enableMessageQueue, false);
    });

    test('should handle message creation and serialization', () {
      final textMessage = WebSocketMessage.text('Hello');
      final jsonMessage = WebSocketMessage.json({'key': 'value'});
      final binaryMessage = WebSocketMessage.binary([1, 2, 3]);

      expect(textMessage.isText, true);
      expect(jsonMessage.isJson, true);
      expect(binaryMessage.isBinary, true);

      // Test JSON serialization
      final textJson = textMessage.toJson();
      final restoredText = WebSocketMessage.fromJson(textJson);
      expect(restoredText.data, textMessage.data);
    });
  });
}
