import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'database_service.dart';

/// P2P Message Types
class P2PMessageType {
  static const String discovery = 'DISCOVERY';
  static const String announce = 'ANNOUNCE';
  static const String message = 'MESSAGE';
  static const String messageAck = 'MESSAGE_ACK';
  static const String fileRequest = 'FILE_REQUEST';
  static const String fileAccept = 'FILE_ACCEPT';
  static const String fileReject = 'FILE_REJECT';
  static const String fileData = 'FILE_DATA';
  static const String fileComplete = 'FILE_COMPLETE';
  static const String call = 'CALL';
  static const String callAccept = 'CALL_ACCEPT';
  static const String callReject = 'CALL_REJECT';
  static const String callEnd = 'CALL_END';
  static const String statusUpdate = 'STATUS_UPDATE';
  static const String ping = 'PING';
  static const String pong = 'PONG';
}

/// Represents a discovered peer on the network
class DiscoveredPeer {
  final String id;
  final String username;
  final String displayName;
  final String avatarColor;
  final String status;
  final String statusMessage;
  final String ipAddress;
  final int port;
  final DateTime lastSeen;

  DiscoveredPeer({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarColor,
    required this.status,
    required this.statusMessage,
    required this.ipAddress,
    required this.port,
    required this.lastSeen,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'display_name': displayName,
    'avatar_color': avatarColor,
    'status': status,
    'status_message': statusMessage,
    'ip_address': ipAddress,
    'port': port,
    'last_seen': lastSeen.toIso8601String(),
  };

  factory DiscoveredPeer.fromJson(Map<String, dynamic> json, String ip) {
    return DiscoveredPeer(
      id: json['id'],
      username: json['username'],
      displayName: json['displayName'],
      avatarColor: json['avatarColor'] ?? '#6366f1',
      status: json['status'] ?? 'online',
      statusMessage: json['statusMessage'] ?? '',
      ipAddress: ip,
      port: json['port'] ?? 42424,
      lastSeen: DateTime.now(),
    );
  }
}

/// P2P Service for local network communication
class P2PService {
  static const int udpPort = 42420;  // UDP broadcast port for discovery
  static const int tcpPort = 42424;  // TCP port for direct messaging
  
  RawDatagramSocket? _udpSocket;
  ServerSocket? _tcpServer;
  Timer? _discoveryTimer;
  Timer? _announceTimer;
  
  String? _localIp;
  Map<String, dynamic>? _localUserInfo;
  
  final _peersController = StreamController<List<DiscoveredPeer>>.broadcast();
  final _messagesController = StreamController<Map<String, dynamic>>.broadcast();
  final _fileTransferController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<List<DiscoveredPeer>> get peersStream => _peersController.stream;
  Stream<Map<String, dynamic>> get messagesStream => _messagesController.stream;
  Stream<Map<String, dynamic>> get fileTransferStream => _fileTransferController.stream;
  
  final Map<String, DiscoveredPeer> _discoveredPeers = {};
  final Map<String, Socket> _peerConnections = {};
  
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Start the P2P service
  Future<void> start(Map<String, dynamic> userInfo) async {
    if (_isRunning) return;
    
    _localUserInfo = userInfo;
    _localIp = await _getLocalIp();
    
    if (_localIp == null) {
      print('Warning: Could not determine local IP address');
      _localIp = '0.0.0.0';
    }
    
    // Start UDP discovery
    await _startUdpDiscovery();
    
    // Start TCP server for direct connections
    await _startTcpServer();
    
    // Announce presence periodically
    _announceTimer = Timer.periodic(const Duration(seconds: 5), (_) => _announcePresence());
    
    // Clean up stale peers periodically
    _discoveryTimer = Timer.periodic(const Duration(seconds: 10), (_) => _cleanupStalePeers());
    
    _isRunning = true;
    
    // Initial announcement
    _announcePresence();
  }

  /// Stop the P2P service
  Future<void> stop() async {
    _isRunning = false;
    
    _discoveryTimer?.cancel();
    _announceTimer?.cancel();
    
    _udpSocket?.close();
    await _tcpServer?.close();
    
    for (final conn in _peerConnections.values) {
      conn.destroy();
    }
    _peerConnections.clear();
    _discoveredPeers.clear();
  }

  /// Update local user info
  void updateUserInfo(Map<String, dynamic> userInfo) {
    _localUserInfo = userInfo;
    _announcePresence();
  }

  /// Get local IP address without external packages
  Future<String?> _getLocalIp() async {
    try {
      // Get all network interfaces
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          // Skip loopback and IPv6
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            // Prefer addresses that look like local network IPs
            if (addr.address.startsWith('192.168.') ||
                addr.address.startsWith('10.') ||
                addr.address.startsWith('172.')) {
              return addr.address;
            }
          }
        }
      }
      
      // Fallback: return any non-loopback IPv4
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting local IP: $e');
    }
    return null;
  }

  /// Start UDP socket for discovery
  Future<void> _startUdpDiscovery() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort);
      _udpSocket!.broadcastEnabled = true;
      
      _udpSocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket!.receive();
          if (datagram != null) {
            _handleUdpMessage(datagram);
          }
        }
      });
    } catch (e) {
      print('Error starting UDP discovery: $e');
    }
  }

  /// Start TCP server for direct connections
  Future<void> _startTcpServer() async {
    try {
      _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, tcpPort);
      _tcpServer!.listen(_handleTcpConnection);
    } catch (e) {
      print('Error starting TCP server: $e');
    }
  }

  /// Broadcast presence on the network
  void _announcePresence() {
    if (_udpSocket == null || _localUserInfo == null || _localIp == null) return;
    
    final message = {
      'type': P2PMessageType.announce,
      'id': _localUserInfo!['id'],
      'username': _localUserInfo!['username'],
      'displayName': _localUserInfo!['displayName'],
      'avatarColor': _localUserInfo!['avatarColor'],
      'status': _localUserInfo!['status'],
      'statusMessage': _localUserInfo!['statusMessage'],
      'port': tcpPort,
    };
    
    final data = utf8.encode(jsonEncode(message));
    
    // Broadcast to common subnet ranges
    final ipParts = _localIp!.split('.');
    if (ipParts.length == 4) {
      final subnet = '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}';
      
      // Send to broadcast address
      try {
        _udpSocket!.send(data, InternetAddress('$subnet.255'), udpPort);
      } catch (e) {
        // Fallback: send to all IPs in subnet
        for (int i = 1; i < 255; i++) {
          try {
            _udpSocket!.send(data, InternetAddress('$subnet.$i'), udpPort);
          } catch (_) {}
        }
      }
    }
  }

  /// Handle incoming UDP message
  void _handleUdpMessage(Datagram datagram) {
    try {
      final data = utf8.decode(datagram.data);
      final message = jsonDecode(data);
      final senderIp = datagram.address.address;
      
      // Ignore our own messages
      if (senderIp == _localIp) return;
      
      switch (message['type']) {
        case P2PMessageType.announce:
          _handlePeerAnnounce(message, senderIp);
          break;
        case P2PMessageType.discovery:
          // Respond with our info
          _announcePresence();
          break;
      }
    } catch (e) {
      print('Error handling UDP message: $e');
    }
  }

  /// Handle peer announcement
  void _handlePeerAnnounce(Map<String, dynamic> message, String ip) async {
    final peer = DiscoveredPeer.fromJson(message, ip);
    
    // Don't add ourselves
    if (peer.id == _localUserInfo?['id']) return;
    
    _discoveredPeers[peer.id] = peer;
    
    // Save to database
    await DatabaseService.instance.upsertPeer(peer.toMap());
    
    // Notify listeners
    _peersController.add(_discoveredPeers.values.toList());
  }

  /// Handle incoming TCP connection
  void _handleTcpConnection(Socket socket) {
    final peerId = '${socket.remoteAddress.address}:${socket.remotePort}';
    
    socket.listen(
      (data) => _handleTcpData(socket, data),
      onDone: () {
        _peerConnections.remove(peerId);
      },
      onError: (e) {
        print('TCP error: $e');
        _peerConnections.remove(peerId);
      },
    );
  }

  /// Handle incoming TCP data
  void _handleTcpData(Socket socket, Uint8List data) {
    try {
      final message = jsonDecode(utf8.decode(data));
      
      switch (message['type']) {
        case P2PMessageType.message:
          _handleIncomingMessage(message, socket);
          break;
        case P2PMessageType.fileRequest:
          _handleFileRequest(message, socket);
          break;
        case P2PMessageType.fileData:
          _handleFileData(message, socket);
          break;
        case P2PMessageType.ping:
          _sendPong(socket);
          break;
      }
    } catch (e) {
      print('Error handling TCP data: $e');
    }
  }

  /// Handle incoming chat message
  void _handleIncomingMessage(Map<String, dynamic> message, Socket socket) async {
    final senderId = message['senderId'];
    final content = message['content'];
    
    // Get or create conversation
    final db = DatabaseService.instance;
    var convId = await db.findConversationWithPeer(senderId);
    convId ??= await db.createConversation(senderId);
    
    // Get sender info
    final peer = await db.getPeer(senderId);
    
    // Save message
    final msg = await db.addMessage(
      convId,
      senderId,
      content,
      peer?['display_name'] ?? 'Unknown',
      peer?['avatar_color'] ?? '#6366f1',
    );
    
    // Notify listeners
    _messagesController.add({
      'type': 'new_message',
      'conversationId': convId,
      'message': msg,
    });
    
    // Send acknowledgment
    _sendTcpMessage(socket, {
      'type': P2PMessageType.messageAck,
      'messageId': message['messageId'],
    });
  }

  /// Send a message to a peer
  Future<bool> sendMessage(String peerId, String conversationId, String content) async {
    final peer = _discoveredPeers[peerId];
    if (peer == null) return false;
    
    try {
      final socket = await _getOrCreateConnection(peer);
      
      _sendTcpMessage(socket, {
        'type': P2PMessageType.message,
        'messageId': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderId': _localUserInfo!['id'],
        'conversationId': conversationId,
        'content': content,
      });
      
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Get or create TCP connection to peer
  Future<Socket> _getOrCreateConnection(DiscoveredPeer peer) async {
    final key = peer.id;
    
    if (_peerConnections.containsKey(key)) {
      return _peerConnections[key]!;
    }
    
    final socket = await Socket.connect(peer.ipAddress, peer.port);
    _peerConnections[key] = socket;
    
    socket.listen(
      (data) => _handleTcpData(socket, data),
      onDone: () => _peerConnections.remove(key),
      onError: (e) => _peerConnections.remove(key),
    );
    
    return socket;
  }

  /// Send TCP message
  void _sendTcpMessage(Socket socket, Map<String, dynamic> message) {
    socket.write(jsonEncode(message));
  }

  /// Send pong response
  void _sendPong(Socket socket) {
    _sendTcpMessage(socket, {'type': P2PMessageType.pong});
  }

  /// Handle file transfer request
  void _handleFileRequest(Map<String, dynamic> message, Socket socket) {
    _fileTransferController.add({
      'type': 'request',
      'data': message,
      'socket': socket,
    });
  }

  /// Handle file data
  void _handleFileData(Map<String, dynamic> message, Socket socket) {
    _fileTransferController.add({
      'type': 'data',
      'data': message,
    });
  }

  /// Send file to peer
  Future<void> sendFile(String peerId, String filePath, String fileName, int fileSize) async {
    final peer = _discoveredPeers[peerId];
    if (peer == null) return;
    
    try {
      final socket = await _getOrCreateConnection(peer);
      
      // Send file request
      _sendTcpMessage(socket, {
        'type': P2PMessageType.fileRequest,
        'senderId': _localUserInfo!['id'],
        'fileName': fileName,
        'fileSize': fileSize,
      });
      
      // TODO: Implement chunked file transfer
    } catch (e) {
      print('Error sending file: $e');
    }
  }

  /// Clean up stale peers (not seen in 30 seconds)
  void _cleanupStalePeers() {
    final now = DateTime.now();
    final staleIds = <String>[];
    
    for (final entry in _discoveredPeers.entries) {
      if (now.difference(entry.value.lastSeen).inSeconds > 30) {
        staleIds.add(entry.key);
      }
    }
    
    for (final id in staleIds) {
      _discoveredPeers.remove(id);
      DatabaseService.instance.updatePeerStatus(id, 'offline');
    }
    
    if (staleIds.isNotEmpty) {
      _peersController.add(_discoveredPeers.values.toList());
    }
  }

  /// Get current list of discovered peers
  List<DiscoveredPeer> get discoveredPeers => _discoveredPeers.values.toList();

  /// Dispose resources
  void dispose() {
    stop();
    _peersController.close();
    _messagesController.close();
    _fileTransferController.close();
  }
}
