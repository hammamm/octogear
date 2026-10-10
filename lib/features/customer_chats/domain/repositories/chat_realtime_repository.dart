import '../entities/chat_update.dart';

abstract interface class ChatRealtimeRepository {
  Stream<ChatUpdate> get updates;
  Future<void> connect();
  void pause();
  Future<void> dispose();
}
