class FileTransfer {
  final String id;
  final String peerId;
  final String peerName;
  final String peerColor;
  final String fileName;
  final String? filePath;
  final int fileSize;
  final String fileType;
  final bool isIncoming;
  final String status;
  final int progress;
  final String? speed;
  final DateTime createdAt;
  final DateTime? completedAt;

  FileTransfer({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.peerColor,
    required this.fileName,
    this.filePath,
    required this.fileSize,
    required this.fileType,
    required this.isIncoming,
    required this.status,
    required this.progress,
    this.speed,
    required this.createdAt,
    this.completedAt,
  });

  factory FileTransfer.fromMap(Map<String, dynamic> map) {
    return FileTransfer(
      id: map['id'],
      peerId: map['peer_id'],
      peerName: map['peer_name'] ?? 'Unknown',
      peerColor: map['peer_color'] ?? '#6366f1',
      fileName: map['file_name'],
      filePath: map['file_path'],
      fileSize: map['file_size'],
      fileType: map['file_type'],
      isIncoming: map['is_incoming'] == 1,
      status: map['status'] ?? 'pending',
      progress: map['progress'] ?? 0,
      speed: map['speed'],
      createdAt: DateTime.parse(map['created_at']),
      completedAt: map['completed_at'] != null ? DateTime.tryParse(map['completed_at']) : null,
    );
  }

  FileTransfer copyWith({String? status, int? progress, String? speed}) {
    return FileTransfer(
      id: id,
      peerId: peerId,
      peerName: peerName,
      peerColor: peerColor,
      fileName: fileName,
      filePath: filePath,
      fileSize: fileSize,
      fileType: fileType,
      isIncoming: isIncoming,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      createdAt: createdAt,
      completedAt: completedAt,
    );
  }

  String get formattedSize {
    if (fileSize == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = fileSize.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
