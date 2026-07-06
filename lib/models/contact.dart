class Contact {
  final String id;
  final String peerId;
  final String? nickname;
  final bool isFavorite;
  final String displayName;
  final String username;
  final String avatarColor;
  final String status;
  final String? statusMessage;
  final String? ipAddress;
  final DateTime? lastSeen;

  Contact({
    required this.id,
    required this.peerId,
    this.nickname,
    required this.isFavorite,
    required this.displayName,
    required this.username,
    required this.avatarColor,
    required this.status,
    this.statusMessage,
    this.ipAddress,
    this.lastSeen,
  });

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'],
      peerId: map['peer_id'],
      nickname: map['nickname'],
      isFavorite: map['is_favorite'] == 1,
      displayName: map['display_name'],
      username: map['username'],
      avatarColor: map['avatar_color'] ?? '#6366f1',
      status: map['status'] ?? 'offline',
      statusMessage: map['status_message'],
      ipAddress: map['ip_address'],
      lastSeen: map['last_seen'] != null ? DateTime.tryParse(map['last_seen']) : null,
    );
  }

  Contact copyWith({bool? isFavorite, String? nickname}) {
    return Contact(
      id: id,
      peerId: peerId,
      nickname: nickname ?? this.nickname,
      isFavorite: isFavorite ?? this.isFavorite,
      displayName: displayName,
      username: username,
      avatarColor: avatarColor,
      status: status,
      statusMessage: statusMessage,
      ipAddress: ipAddress,
      lastSeen: lastSeen,
    );
  }

  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}
