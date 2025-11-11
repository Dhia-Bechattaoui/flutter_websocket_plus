/// A powerful and feature-rich WebSocket package for Flutter with automatic
/// reconnection, message queuing, and cross-platform support.
///
/// This package provides a comprehensive WebSocket solution that works on all
/// 6 platforms (iOS, Android, Web, Windows, macOS, Linux) with features like:
///
/// - Automatic reconnection with configurable strategies
/// - Message queuing with priority support
/// - Heartbeat/ping-pong support for connection health monitoring
/// - Comprehensive statistics and monitoring
/// - Error handling and recovery mechanisms
///
/// Example:
/// ```dart
/// import 'package:flutter_websocket_plus/flutter_websocket_plus.dart';
///
/// final config = WebSocketConfig(
///   url: 'wss://echo.websocket.org',
///   enableReconnection: true,
///   enableMessageQueue: true,
/// );
///
/// final manager = WebSocketManager(config: config);
/// await manager.connect();
/// await manager.sendText('Hello, WebSocket!');
/// ```
library flutter_websocket_plus;

export 'websocket_manager.dart';
export 'websocket_connection.dart';
export 'websocket_message.dart';
export 'websocket_config.dart';
export 'websocket_state.dart';
export 'websocket_exception.dart';
export 'reconnection_strategy.dart';
export 'message_queue.dart';
