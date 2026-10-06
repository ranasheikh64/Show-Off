import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/constants/api_url.dart';
import '../../../core/storage/hive_service.dart';

class SocketService {
  static IO.Socket? _socket;

  static void initSocket() {
    if (_socket != null && _socket!.connected) return;

    final token = HiveService.getToken();
    if (token == null) return;

    _socket = IO.io(ApiUrl.socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .build());

    _socket?.onConnect((_) {
      print('Socket Connected');
    });

    _socket?.onDisconnect((_) {
      print('Socket Disconnected');
    });

    _socket?.onConnectError((err) {
      print('Socket Connect Error: $err');
    });
  }

  static void joinChat(String chatId) {
    _socket?.emit('join_chat', chatId);
  }

  static void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  static void emitWithAck(String event, dynamic data, Function(dynamic) ack) {
    _socket?.emitWithAck(event, data, ack: ack);
  }

  static void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  static void off(String event) {
    _socket?.off(event);
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
