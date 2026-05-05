class MessageModel {
  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  bool isRead;
}

class ChatThread {
  ChatThread({
    required this.id,
    required this.title,
    required this.participantIds,
    required this.messages,
    this.unreadCount = 0,
    required this.isGroup,
    this.relatedEventId,
  });

  final String id;
  final String title;
  final List<String> participantIds;
  final List<MessageModel> messages;
  int unreadCount;
  final bool isGroup;
  final String? relatedEventId;
}
