Map<String, dynamic> wireMessage({int id = 2}) => {
  'id': id,
  'sender_kind': 'admin',
  'content': 'Support reply',
  'client_message_id': '12345678-1234-4234-8234-123456789abc',
  'created_at': '2026-10-21T10:00:00Z',
};
Map<String, dynamic> wireConversation() => {
  'id': 1,
  'status': 'open',
  'version': 3,
  'unread_count': 1,
  'user_read_through_id': 0,
  'support_read_through_id': 1,
  'last_message': wireMessage(),
};
