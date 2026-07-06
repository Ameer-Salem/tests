class Message {
  final String id;
  final String content;
  final String messageType;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;
  final String senderId;
  final String senderName;
  final String senderColor;
  final bool isOptimistic;

  Message({
    required this.id,
    required this.content,
    required this.messageType,
    required this.isEdited,
    required this.isDeleted,
    required this.createdAt,
    required this.senderId,
    required this.senderName,
    required this.senderColor,
    this.isOptimistic = false,
  });

  factory Message.fromMap(Map<String, dynamic> map, Map<String, dynamic>? sender) {
    return Message(
      id: map['id'],
      content: map['content'],
      messageType: map['message_type'] ?? 'text',
      isEdited: map['is_edited'] == 1,
      isDeleted: map['is_deleted'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      senderId: map['sender_id'],
      senderName: sender?['display_name'] ?? 'Unknown',
      senderColor: sender?['avatar_color'] ?? '#6366f1',
    );
  }

  Message copyWith({
    String? id,
    String? content,
    bool? isEdited,
    bool? isDeleted,
    bool? isOptimistic,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      messageType: messageType,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      senderId: senderId,
      senderName: senderName,
      senderColor: senderColor,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }

  String get senderInitials {
    final parts = senderName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';
  }
}
