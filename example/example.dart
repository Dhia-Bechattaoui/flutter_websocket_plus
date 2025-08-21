import 'package:flutter_websocket_plus/flutter_websocket_plus.dart';

void main() {
  // Example usage of flutter_websocket_plus
  print('flutter_websocket_plus example');

  // Create configuration
  final config = WebSocketConfig(
    url: 'wss://echo.websocket.org',
    enableReconnection: true,
    enableMessageQueue: true,
  );

  // Create manager
  final manager = WebSocketManager(config: config);

  print('WebSocket manager created with config: ${config.url}');
  print('Reconnection enabled: ${config.enableReconnection}');
  print('Message queue enabled: ${config.enableMessageQueue}');
  print('Manager instance: $manager');
}
