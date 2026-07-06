import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/p2p_service.dart';
import '../models/user.dart';

class NetworkProvider extends ChangeNotifier {
  final P2PService _p2pService;
  
  List<DiscoveredPeer> _peers = [];
  bool _isRunning = false;
  String? _localIp;
  String? _error;
  
  StreamSubscription? _peersSub;
  StreamSubscription? _messagesSub;
  
  List<DiscoveredPeer> get peers => _peers;
  List<DiscoveredPeer> get onlinePeers => _peers.where((p) => p.status == 'online').toList();
  bool get isRunning => _isRunning;
  String? get localIp => _localIp;
  String? get error => _error;
  
  NetworkProvider(this._p2pService);
  
  Future<void> start(User user) async {
    if (_isRunning) return;
    
    try {
      await _p2pService.start(user.toMap());
      
      _peersSub = _p2pService.peersStream.listen((peers) {
        _peers = peers;
        notifyListeners();
      });
      
      _isRunning = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> stop() async {
    await _p2pService.stop();
    _peersSub?.cancel();
    _messagesSub?.cancel();
    _isRunning = false;
    _peers = [];
    notifyListeners();
  }
  
  void updateUserInfo(User user) {
    _p2pService.updateUserInfo(user.toMap());
  }
  
  DiscoveredPeer? getPeer(String peerId) {
    try {
      return _peers.firstWhere((p) => p.id == peerId);
    } catch (e) {
      return null;
    }
  }
  
  Future<bool> sendMessage(String peerId, String conversationId, String content) {
    return _p2pService.sendMessage(peerId, conversationId, content);
  }
  
  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
