import 'package:flutter/foundation.dart';
import '../models/file_transfer.dart';
import '../services/database_service.dart';

class TransferProvider extends ChangeNotifier {
  List<FileTransfer> _transfers = [];
  bool _isLoading = false;
  String? _error;

  List<FileTransfer> get transfers => _transfers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _db = DatabaseService.instance;

  List<FileTransfer> getFilteredTransfers(String filter) {
    switch (filter) {
      case 'sent':
        return _transfers.where((t) => !t.isIncoming).toList();
      case 'received':
        return _transfers.where((t) => t.isIncoming).toList();
      default:
        return _transfers;
    }
  }

  int get totalSent => _transfers.where((t) => !t.isIncoming && t.status == 'completed').length;
  int get totalReceived => _transfers.where((t) => t.isIncoming && t.status == 'completed').length;
  int get totalTransferredBytes =>
      _transfers.where((t) => t.status == 'completed').fold(0, (sum, t) => sum + t.fileSize);

  String get formattedTotalSize {
    final bytes = totalTransferredBytes;
    if (bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> loadTransfers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transfers = await _db.getFileTransfers();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransfer(String peerId, String fileName, int fileSize, 
      String fileType, bool isIncoming, {String? filePath}) async {
    try {
      final transfer = await _db.addFileTransfer(
        peerId, fileName, fileSize, fileType, isIncoming,
        filePath: filePath,
      );
      _transfers = [transfer, ..._transfers];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTransfer(String id, {String? status, int? progress, String? speed}) async {
    _transfers = _transfers.map((t) {
      if (t.id == id) {
        return t.copyWith(status: status, progress: progress, speed: speed);
      }
      return t;
    }).toList();
    notifyListeners();

    try {
      await _db.updateFileTransfer(id, status: status, progress: progress, speed: speed);
    } catch (e) {
      await loadTransfers();
    }
  }

  Future<void> cancelTransfer(String id) async {
    await updateTransfer(id, status: 'cancelled');
  }
}
