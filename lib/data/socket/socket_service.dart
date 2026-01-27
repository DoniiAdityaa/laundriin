import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../../config/constant.dart';

class SocketService {
  late Socket socket;

  SocketService() {
    socket = io(
      baseSocket,
      OptionBuilder()
          .setTransports(['websocket']) // for Flutter or Dart VM
          .disableAutoConnect() // optional
          .build(),
    );
    socket.onAny((event, data) {
      if (kDebugMode) {
        log('SOCKET: $event');
      }
    });
    socket.onConnect((_) {
      log('SOCKET CONNECT');
    });

    socket.on('disconnect', (_) => log('SOCKET DISCONNECT'));

    socket.on('error', (error) => log('SOCKET ERROR $error'));
  }

  void connect() {
    socket.connect();
  }

  void emitJoinRoom(String chatId) {
    socket.emit('join', chatId);

    if (kDebugMode) {
      print("SOCKET JOIN ROOM CHAT");
      print(chatId);
      log('SOCKET JOIN ROOM CHAT');
    }
  }

  void onChatUpdate({required Function(String? senderId) onUpdate}) {
    socket.on('update message', (data) {
      if (kDebugMode) {
        print("SOCKET MESSAGE");
        print(data);
      }
      onUpdate(data["senderId"]);
    });
  }

  void onSendUpdateMessage({required String roomName, required String senderId}) {
    socket.emit('update message', {
      "roomId": roomName,
      "senderId": senderId,
    });
    if (kDebugMode) {
      print("SEND SOCKET READ");
      print({
        "roomId": roomName,
      });
    }
    socket.connect();
  }

  void disconnect() {
    socket.disconnect();
    socket.dispose();
  }
}
