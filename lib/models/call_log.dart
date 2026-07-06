class CallLog {
  final String id;
  final String peerId;
  final String peerName;
  final String peerColor;
  final String callType;
  final bool isIncoming;
  final int duration;
  final String status;
  final DateTime createdAt;

  CallLog({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.peerColor,
    required this.callType,
    required this.isIncoming,
    required this.duration,
    required this.status,
    required this.createdAt,
  });

  factory CallLog.fromMap(Map<String, dynamic> map) {
    return CallLog(
      id: map['id'],
      peerId: map['peer_id'],
      peerName: map['peer_name'] ?? 'Unknown',
      peerColor: map['peer_color'] ?? '#6366f1',
      callType: map['call_type'] ?? 'audio',
      isIncoming: map['is_incoming'] == 1,
      duration: map['duration'] ?? 0,
      status: map['status'] ?? 'missed',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String get formattedDuration {
    if (duration == 0) return '0:00';
    final mins = duration ~/ 60;
    final secs = duration % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  bool get isMissed => status == 'missed';
}
