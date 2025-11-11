import 'package:web_socket_channel/web_socket_channel.dart';

/// Platform-specific WebSocket connection helper for web platform
/// Note: Web platform doesn't support custom headers in WebSocket constructor
class PlatformWebSocketHelper {
  static WebSocketChannel connect(
    Uri uri, {
    List<String>? protocols,
    Map<String, String>? headers,
  }) {
    // Web platform doesn't support headers in WebSocket constructor
    // Headers would need to be sent as part of the initial handshake or via query params
    if (protocols != null && protocols.isNotEmpty) {
      return WebSocketChannel.connect(uri, protocols: protocols);
    }
    return WebSocketChannel.connect(uri);
  }
}
