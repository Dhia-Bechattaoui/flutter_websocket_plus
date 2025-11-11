import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

/// Platform-specific WebSocket connection helper for native platforms (iOS, Android, Windows, macOS, Linux)
class PlatformWebSocketHelper {
  static WebSocketChannel connect(
    Uri uri, {
    List<String>? protocols,
    Map<String, String>? headers,
  }) {
    return IOWebSocketChannel.connect(
      uri,
      protocols: protocols,
      headers: headers,
    );
  }
}
