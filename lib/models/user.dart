class User {
  final String id;
  final String username;
  final String displayName;
  final String avatarColor;
  final String status;
  final String? statusMessage;

  User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarColor,
    required this.status,
    this.statusMessage,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      displayName: map['display_name'],
      avatarColor: map['avatar_color'] ?? '#6366f1',
      status: map['status'] ?? 'online',
      statusMessage: map['status_message'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'displayName': displayName,
    'avatarColor': avatarColor,
    'status': status,
    'statusMessage': statusMessage ?? '',
  };

  User copyWith({
    String? displayName,
    String? avatarColor,
    String? status,
    String? statusMessage,
  }) {
    return User(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      avatarColor: avatarColor ?? this.avatarColor,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
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
