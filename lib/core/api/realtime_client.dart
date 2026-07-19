import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';

/// Real-time na koneksyon sa Laravel Reverb (Pusher protocol) para sa
/// Live Battle Mode — instant leaderboard updates nang walang polling.
///
/// IMPORTANT: Dapat naka-run ang Reverb server sa backend:
///   php artisan reverb:start --host=0.0.0.0
class RoomRealtime {
  // Dapat tugma sa REVERB_APP_KEY sa .env ng eduquiz-backend
  static const String _appKey = 'axplt4ivmfahjfhhid9g';
  static const int _port = 8080;

  final String code;
  final void Function(Map<String, dynamic> data) onLeaderboardUpdated;
  final void Function(bool connected)? onConnectionChanged;

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool _connected = false;

  RoomRealtime({
    required this.code,
    required this.onLeaderboardUpdated,
    this.onConnectionChanged,
  });

  bool get isConnected => _connected;

  void connect() {
    if (_disposed) return;
    // Parehong host ng REST API ang gamitin, iba lang ang port
    final host = Uri.parse(ApiClient.baseUrl).host;
    final url =
        'ws://$host:$_port/app/$_appKey?protocol=7&client=flutter&version=1.0';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final message = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = message['event'] as String?;

      switch (event) {
        case 'pusher:connection_established':
          _setConnected(true);
          _send({
            'event': 'pusher:subscribe',
            'data': {'auth': '', 'channel': 'room.$code'},
          });
        case 'pusher:ping':
          _send({'event': 'pusher:pong', 'data': {}});
        case 'leaderboard.updated':
          // Ang `data` ay JSON string mula sa Pusher protocol
          final data = message['data'];
          final decoded = data is String ? jsonDecode(data) : data;
          onLeaderboardUpdated(Map<String, dynamic>.from(decoded as Map));
      }
    } catch (_) {
      // Huwag patayin ang connection dahil sa isang malformed message
    }
  }

  void _send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    onConnectionChanged?.call(value);
  }

  void _scheduleReconnect() {
    _setConnected(false);
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), connect);
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
