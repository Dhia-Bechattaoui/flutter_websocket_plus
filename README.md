# flutter_websocket_plus

[![Pub Version](https://img.shields.io/pub/v/flutter_websocket_plus)](https://pub.dev/packages/flutter_websocket_plus)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8+-blue.svg)](https://dart.dev)

A powerful and feature-rich WebSocket package for Flutter with automatic reconnection, message queuing, and cross-platform support.

<img src="assets/example.gif" width="300" alt="Example demonstration of flutter_websocket_plus">

## Features

🚀 **Cross-Platform Support**: Works on all 6 platforms (iOS, Android, Web, Windows, macOS, Linux)
🔄 **Automatic Reconnection**: Smart reconnection strategies with exponential backoff  
📬 **Message Queuing**: Reliable message delivery with priority queuing  
💓 **Heartbeat Support**: Built-in ping/pong for connection health monitoring  
⚡ **High Performance**: Optimized for real-time applications  
🛡️ **Error Handling**: Comprehensive error handling and recovery  
📊 **Statistics & Monitoring**: Detailed connection and queue statistics  
🔧 **Configurable**: Highly customizable connection parameters  
🌐 **WASM Compatible**: Full support for web platform including WASM  

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_websocket_plus: ^0.1.0
```

### Basic Usage

```dart
import 'package:flutter_websocket_plus/flutter_websocket_plus.dart';

// Create configuration
final config = WebSocketConfig(
  url: 'wss://echo.websocket.org',
  enableReconnection: true,
  enableMessageQueue: true,
);

// Create manager
final manager = WebSocketManager(config: config);

// Connect to WebSocket server
await manager.connect();

// Send messages
await manager.sendText('Hello, WebSocket!');
await manager.sendJson({'type': 'message', 'content': 'Hello'});

// Listen to messages
manager.messageStream.listen((message) {
  print('Received: ${message.data}');
});

// Listen to connection state changes
manager.stateStream.listen((state) {
  print('Connection state: ${state.connectionState}');
});

// Clean up when done
await manager.dispose();
```

## Advanced Usage

### Custom Reconnection Strategy

```dart
// Create custom reconnection strategy
final strategy = ExponentialBackoffStrategy(
  initialDelay: Duration(seconds: 1),
  maxDelay: Duration(minutes: 5),
  multiplier: 2.0,
);

// Use with manager
final manager = WebSocketManager(
  config: config,
  reconnectionStrategy: strategy,
);
```

### Message Queuing

```dart
// Create message with acknowledgment requirement
final message = WebSocketMessage.json(
  {'type': 'important', 'data': 'critical info'},
  requiresAck: true,
);

// Send message (will be queued if connection is down)
await manager.send(message);
```

### Configuration Options

```dart
final config = WebSocketConfig(
  url: 'wss://your-server.com',
  connectionTimeout: Duration(seconds: 30),
  enableReconnection: true,
  maxReconnectionAttempts: 10,
  initialReconnectionDelay: Duration(seconds: 1),
  maxReconnectionDelay: Duration(minutes: 5),
  enableMessageQueue: true,
  maxQueueSize: 1000,
  heartbeatInterval: Duration(seconds: 30),
  enableHeartbeat: true,
  headers: {'Authorization': 'Bearer token'},
  protocols: ['protocol1', 'protocol2'],
);
```

### Event Handling

```dart
// Listen to all events
manager.eventStream.listen((event) {
  switch (event.type) {
    case 'connected':
      print('Connected to WebSocket server');
      break;
    case 'disconnected':
      print('Disconnected from WebSocket server');
      break;
    case 'reconnecting':
      print('Reconnecting... Attempt ${event.data}');
      break;
    case 'messageSent':
      print('Message sent: ${event.data}');
      break;
    case 'messageQueued':
      print('Message queued: ${event.data}');
      break;
    case 'error':
      print('Error: ${event.data}');
      break;
  }
});
```

### Statistics and Monitoring

```dart
// Get comprehensive statistics
final stats = manager.getStatistics();
print('Connection state: ${stats['connectionState']}');
print('Is connected: ${stats['isConnected']}');
print('Reconnection attempts: ${stats['reconnectionAttempt']}');

// Get connection statistics
final connStats = stats['connectionStatistics'];
if (connStats != null) {
  print('Messages sent: ${connStats['messagesSent']}');
  print('Messages received: ${connStats['messagesReceived']}');
  print('Errors: ${connStats['errorsCount']}');
  print('Heartbeat health: ${connStats['heartbeatHealth']}');
}

// Get queue statistics
final queueStats = manager.queueStatistics;
print('Queue size: ${queueStats['size']}');
print('Max size: ${queueStats['maxSize']}');
print('Utilization: ${queueStats['utilization']}');
print('Retryable messages: ${queueStats['retryableCount']}');
print('Ack required: ${queueStats['ackRequiredCount']}');
```

## Platform Support

| Platform | Support | Notes |
|----------|---------|-------|
| **iOS** | ✅ Full | Native WebSocket implementation |
| **Android** | ✅ Full | Native WebSocket implementation |
| **Web** | ✅ Full | Browser WebSocket + WASM compatible |
| **Windows** | ✅ Full | Native WebSocket implementation |
| **macOS** | ✅ Full | Native WebSocket implementation |
| **Linux** | ✅ Full | Native WebSocket implementation |

## Architecture

The package is built with a layered architecture:

- **WebSocketManager**: High-level manager with reconnection and queuing
- **WebSocketConnection**: Low-level connection management
- **MessageQueue**: Priority-based message queuing system
- **ReconnectionStrategy**: Pluggable reconnection algorithms
- **WebSocketMessage**: Rich message representation with metadata

## Reconnection Strategies

### Exponential Backoff (Default)
- Starts with initial delay and exponentially increases
- Includes randomization to prevent thundering herd
- Configurable maximum delay cap

### Linear Backoff
- Linear increase in delay between attempts
- Predictable reconnection timing
- Good for controlled environments

### Fixed Delay
- Constant delay between reconnection attempts
- Simple and predictable
- Suitable for stable networks

### No Reconnection
- Disables automatic reconnection
- Useful for testing or manual control

## Message Types

- **Text**: Plain text messages
- **Binary**: Binary data (bytes)
- **JSON**: Structured JSON data
- **Ping/Pong**: Heartbeat control messages

## Error Handling

The package provides comprehensive error handling:

- Connection failures with automatic retry
- Message sending failures with queuing
- Network timeouts with configurable limits
- Graceful degradation when features are disabled

## Performance Considerations

- Efficient message queuing with O(log n) priority operations
- Batch message processing for optimal throughput
- Minimal memory overhead for connection management
- Optimized reconnection timing algorithms
- Lazy initialization of resources
- Platform-specific optimizations for native and web

## Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/flutter_websocket_plus_test.dart
```

## Requirements

- Dart SDK: >=3.8.0 <4.0.0
- Flutter: >=3.0.0

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions, please:

1. Check the [documentation](https://github.com/Dhia-Bechattaoui/flutter_websocket_plus#readme)
2. Search [existing issues](https://github.com/Dhia-Bechattaoui/flutter_websocket_plus/issues)
3. Create a [new issue](https://github.com/Dhia-Bechattaoui/flutter_websocket_plus/issues/new)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.

---

**Made with ❤️ by [Dhia-Bechattaoui](https://github.com/Dhia-Bechattaoui)**
