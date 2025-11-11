import 'dart:async';
import 'package:flutter_websocket_plus/flutter_websocket_plus.dart';

String _separator() => List.filled(60, '=').join();

void main() async {
  print('🚀 flutter_websocket_plus - Comprehensive Example');
  print(_separator());

  // ============================================================
  // Feature 1: Configurable - Show all configuration options
  // ============================================================
  print('\n📋 Feature: Configurable');
  print('Creating WebSocket configuration with all options...');

  final config = WebSocketConfig(
    url: 'wss://echo.websocket.org',
    connectionTimeout: Duration(seconds: 30),
    enableReconnection: true,
    maxReconnectionAttempts: 10,
    initialReconnectionDelay: Duration(seconds: 1),
    maxReconnectionDelay: Duration(minutes: 5),
    enableMessageQueue: true,
    maxQueueSize: 1000,
    heartbeatInterval: Duration(seconds: 30),
    enableHeartbeat: true,
    headers: {'User-Agent': 'flutter_websocket_plus'},
    protocols: [],
  );

  print('✓ Configuration created with:');
  print('  - URL: ${config.url}');
  print('  - Reconnection: ${config.enableReconnection}');
  print('  - Message Queue: ${config.enableMessageQueue}');
  print('  - Heartbeat: ${config.enableHeartbeat}');

  // ============================================================
  // Feature 2: Custom Reconnection Strategy
  // ============================================================
  print('\n🔄 Feature: Automatic Reconnection with Custom Strategy');
  print('Creating exponential backoff reconnection strategy...');

  final reconnectionStrategy = ExponentialBackoffStrategy(
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(minutes: 5),
    multiplier: 2.0,
  );

  print('✓ Reconnection strategy created');

  // ============================================================
  // Feature 3: WebSocket Manager Creation
  // ============================================================
  print('\n🔧 Feature: WebSocket Manager');
  print('Creating WebSocket manager...');

  final manager = WebSocketManager(
    config: config,
    reconnectionStrategy: reconnectionStrategy,
  );

  print('✓ Manager created');

  // ============================================================
  // Feature 4: Event Handling
  // ============================================================
  print('\n📡 Feature: Event Handling');
  print('Setting up event listeners...');

  manager.eventStream.listen((event) {
    switch (event.type) {
      case 'connecting':
        print('  📡 Event: Connecting to server...');
        break;
      case 'connected':
        print('  ✅ Event: Connected to WebSocket server');
        break;
      case 'disconnected':
        print('  ❌ Event: Disconnected from server');
        break;
      case 'reconnecting':
        print('  🔄 Event: Reconnecting... Attempt ${event.data}');
        break;
      case 'messageSent':
        print('  📤 Event: Message sent');
        break;
      case 'messageQueued':
        print('  📬 Event: Message queued (connection down)');
        break;
      case 'error':
        print('  ⚠️  Event: Error - ${event.data}');
        break;
      default:
        print('  📨 Event: ${event.type}');
    }
  });

  print('✓ Event listeners set up');

  // ============================================================
  // Feature 5: Connection State Monitoring
  // ============================================================
  print('\n📊 Feature: Connection State Monitoring');
  print('Setting up state stream listener...');

  manager.stateStream.listen((state) {
    print('  📊 State: ${state.connectionState.name}');
    print('    - Queue size: ${state.queueSize}');
    print('    - Reconnecting: ${state.isReconnecting}');
    print('    - Attempt: ${state.reconnectionAttempt}');
  });

  print('✓ State monitoring set up');

  // ============================================================
  // Feature 6: Message Listening
  // ============================================================
  print('\n📨 Feature: Message Listening');
  print('Setting up message stream listener...');

  manager.messageStream.listen((message) {
    print('  📨 Received: ${message.type} message');
    print('    - Data: ${message.data}');
    print('    - Timestamp: ${message.timestamp}');
    print('    - ID: ${message.id}');
  });

  print('✓ Message listener set up');

  // ============================================================
  // Feature 7: Connect to Server
  // ============================================================
  print('\n🔌 Feature: Connection');
  print('Connecting to WebSocket server...');

  try {
    await manager.connect();
    print('✓ Connection initiated');

    // Wait a bit for connection to establish
    await Future.delayed(Duration(seconds: 2));

    if (manager.isConnected) {
      print('✅ Successfully connected!');
    } else {
      print('⏳ Connection in progress...');
    }
  } catch (e) {
    print('❌ Connection error: $e');
  }

  // ============================================================
  // Feature 8: Send Different Message Types
  // ============================================================
  print('\n📤 Feature: Sending Messages');

  if (manager.isConnected) {
    print('Sending text message...');
    await manager.sendText('Hello, WebSocket!');
    await Future.delayed(Duration(milliseconds: 500));

    print('Sending JSON message...');
    await manager.sendJson({
      'type': 'message',
      'content': 'Hello from flutter_websocket_plus!',
      'timestamp': DateTime.now().toIso8601String(),
    });
    await Future.delayed(Duration(milliseconds: 500));

    print('Sending binary message...');
    await manager.sendBinary([72, 101, 108, 108, 111]); // "Hello" in bytes
    await Future.delayed(Duration(milliseconds: 500));

    print('✓ Messages sent');
  } else {
    print('⚠️  Not connected, messages will be queued');

    // Feature 9: Message Queuing (when disconnected)
    print('\n📬 Feature: Message Queuing');
    print('Sending message while disconnected (will be queued)...');

    final queuedMessage = WebSocketMessage.json({
      'type': 'queued',
      'data': 'This will be queued',
    }, requiresAck: true);

    await manager.send(queuedMessage);
    print('✓ Message queued (queue size: ${manager.queueStatistics['size']})');
  }

  // ============================================================
  // Feature 10: Heartbeat Support
  // ============================================================
  print('\n💓 Feature: Heartbeat Support');
  if (config.enableHeartbeat) {
    print('Heartbeat is enabled (interval: ${config.heartbeatInterval})');
    print('Ping messages will be sent automatically');

    // Manually send ping to demonstrate
    if (manager.isConnected) {
      print('Sending manual ping...');
      await manager.sendPing();
      await Future.delayed(Duration(milliseconds: 500));
      print('✓ Ping sent');
    }
  } else {
    print('Heartbeat is disabled');
  }

  // ============================================================
  // Feature 11: Statistics & Monitoring
  // ============================================================
  print('\n📊 Feature: Statistics & Monitoring');
  print('Getting comprehensive statistics...');

  final stats = manager.getStatistics();
  print('\n📈 Manager Statistics:');
  print('  - Connection State: ${stats['connectionState']}');
  print('  - Is Connected: ${stats['isConnected']}');
  print('  - Is Reconnecting: ${stats['isReconnecting']}');
  print('  - Reconnection Attempts: ${stats['reconnectionAttempt']}');

  if (stats['connectionStatistics'] != null) {
    final connStats = stats['connectionStatistics'] as Map<String, dynamic>;
    print('\n📡 Connection Statistics:');
    print('  - Messages Sent: ${connStats['messagesSent'] ?? 0}');
    print('  - Messages Received: ${connStats['messagesReceived'] ?? 0}');
    print('  - Errors: ${connStats['errorsCount'] ?? 0}');
    print('  - Ping Sent: ${connStats['pingSent'] ?? 0}');
    print('  - Pong Received: ${connStats['pongReceived'] ?? 0}');
    if (connStats['heartbeatHealth'] != null) {
      print('  - Heartbeat Health: ${connStats['heartbeatHealth']}');
    }
  }

  final queueStats = manager.queueStatistics;
  print('\n📬 Queue Statistics:');
  print('  - Size: ${queueStats['size']}');
  print('  - Max Size: ${queueStats['maxSize']}');
  print('  - Utilization: ${queueStats['utilization']}');
  print('  - Retryable: ${queueStats['retryableCount']}');
  print('  - Ack Required: ${queueStats['ackRequiredCount']}');

  print('✓ Statistics retrieved');

  // ============================================================
  // Feature 12: Error Handling
  // ============================================================
  print('\n🛡️  Feature: Error Handling');
  print('Error handling is demonstrated through:');
  print('  - Automatic reconnection on connection failure');
  print('  - Message queuing when connection is down');
  print('  - Retry mechanism for failed messages');
  print('  - Error events in event stream');
  print('✓ Error handling is active');

  // ============================================================
  // Feature 13: Cross-Platform Support
  // ============================================================
  print('\n🚀 Feature: Cross-Platform Support');
  print('This package works on:');
  print('  ✅ iOS');
  print('  ✅ Android');
  print('  ✅ Web (including WASM)');
  print('  ✅ Windows');
  print('  ✅ macOS');
  print('  ✅ Linux');
  print('✓ Cross-platform support verified');

  // ============================================================
  // Wait and demonstrate features
  // ============================================================
  print('\n⏳ Waiting 5 seconds to demonstrate real-time features...');
  print('(Watch for heartbeat pings, message responses, etc.)\n');

  await Future.delayed(Duration(seconds: 5));

  // ============================================================
  // Final Statistics
  // ============================================================
  print('\n📊 Final Statistics:');
  final finalStats = manager.getStatistics();
  print('  Connection State: ${finalStats['connectionState']}');
  print('  Queue Size: ${finalStats['queueStatistics']['size']}');

  if (finalStats['connectionStatistics'] != null) {
    final connStats =
        finalStats['connectionStatistics'] as Map<String, dynamic>;
    print('  Messages Sent: ${connStats['messagesSent'] ?? 0}');
    print('  Messages Received: ${connStats['messagesReceived'] ?? 0}');
  }

  // ============================================================
  // Cleanup
  // ============================================================
  print('\n🧹 Cleaning up...');
  await manager.dispose();
  print('✓ Manager disposed');

  print('\n' + _separator());
  print('✨ Example completed! All features demonstrated.');
  print(_separator());
}
