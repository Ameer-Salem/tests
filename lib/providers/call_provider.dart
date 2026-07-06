import 'package:flutter/foundation.dart';
import '../models/call_log.dart';
import '../services/database_service.dart';

class CallProvider extends ChangeNotifier {
  List<CallLog> _calls = [];
  bool _isLoading = false;
  String? _error;

  List<CallLog> get calls => _calls;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _db = DatabaseService.instance;

  List<CallLog> getFilteredCalls(String filter) {
    switch (filter) {
      case 'incoming':
        return _calls.where((c) => c.isIncoming).toList();
      case 'outgoing':
        return _calls.where((c) => !c.isIncoming).toList();
      case 'missed':
        return _calls.where((c) => c.isMissed).toList();
      default:
        return _calls;
    }
  }

  int get totalCalls => _calls.length;
  int get missedCalls => _calls.where((c) => c.isMissed).length;
  int get totalDurationSeconds => _calls.fold(0, (sum, c) => sum + c.duration);

  String get formattedTotalDuration {
    final total = totalDurationSeconds;
    final mins = total ~/ 60;
    final secs = total % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> loadCalls() async {
    _isLoading = true;
    notifyListeners();

    try {
      _calls = await _db.getCallLogs();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCall(String peerId, String callType, bool isIncoming,
      {int duration = 0, String status = 'missed'}) async {
    try {
      await _db.addCallLog(peerId, callType, isIncoming,
          duration: duration, status: status);
      await loadCalls();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
