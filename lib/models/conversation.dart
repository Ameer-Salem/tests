class Conversation {
  final String id;
  final String? name;
  final bool isGroup;
  final String displayName;
  final String? lastMessageContent;
  final DateTime? lastMessageTime;
  final String? peerAvatarColor;
  final String? peerStatus;
  final String? peerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    this.name,
    required this.isGroup,
    required this.displayName,
    this.lastMessageContent,
    this.lastMessageTime,
    this.peerAvatarColor,
    this.peerStatus,
    this.peerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromMap(Map<String, dynamic> map, {
    Map<String, dynamic>? lastMessage,
    Map<String, dynamic>? peer,
  }) {
    return Conversation(
      id: map['id'],
      name: map['name'],
      isGroup: map['is_group'] == 1,
      displayName: peer?['display_name'] ?? map['name'] ?? 'Unknown',
      lastMessageContent: lastMessage?['content'],
      lastMessageTime: lastMessage?['created_at'] != null 
          ? DateTime.tryParse(lastMessage!['created_at']) 
          : null,
      peerAvatarColor: peer?['avatar_color'],
      peerStatus: peer?['status'],
      peerId: peer?['id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
