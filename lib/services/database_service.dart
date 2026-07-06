import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/file_transfer.dart';
import '../models/call_log.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  static Database? _database;

  DatabaseService._();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'locallink.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table (local user profile)
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        display_name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        avatar_color TEXT DEFAULT '#6366f1',
        status TEXT DEFAULT 'online',
        status_message TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    // Discovered peers on the network
    await db.execute('''
      CREATE TABLE peers (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        display_name TEXT NOT NULL,
        avatar_color TEXT DEFAULT '#6366f1',
        status TEXT DEFAULT 'offline',
        status_message TEXT DEFAULT '',
        ip_address TEXT NOT NULL,
        port INTEGER NOT NULL,
        last_seen TEXT NOT NULL
      )
    ''');

    // Contacts (saved peers)
    await db.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY,
        peer_id TEXT NOT NULL,
        nickname TEXT,
        is_favorite INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (peer_id) REFERENCES peers(id)
      )
    ''');

    // Conversations
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        name TEXT,
        is_group INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Conversation members
    await db.execute('''
      CREATE TABLE conversation_members (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        peer_id TEXT NOT NULL,
        joined_at TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id),
        FOREIGN KEY (peer_id) REFERENCES peers(id)
      )
    ''');

    // Messages
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        content TEXT NOT NULL,
        message_type TEXT DEFAULT 'text',
        is_edited INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        is_sent INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id)
      )
    ''');

    // File transfers
    await db.execute('''
      CREATE TABLE file_transfers (
        id TEXT PRIMARY KEY,
        peer_id TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT,
        file_size INTEGER NOT NULL,
        file_type TEXT NOT NULL,
        is_incoming INTEGER NOT NULL,
        status TEXT DEFAULT 'pending',
        progress INTEGER DEFAULT 0,
        speed TEXT,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (peer_id) REFERENCES peers(id)
      )
    ''');

    // Call logs
    await db.execute('''
      CREATE TABLE call_logs (
        id TEXT PRIMARY KEY,
        peer_id TEXT NOT NULL,
        call_type TEXT DEFAULT 'audio',
        is_incoming INTEGER NOT NULL,
        duration INTEGER DEFAULT 0,
        status TEXT DEFAULT 'missed',
        created_at TEXT NOT NULL,
        FOREIGN KEY (peer_id) REFERENCES peers(id)
      )
    ''');
  }

  // ============ USER METHODS ============

  Future<User?> getLocalUser() async {
    final db = await database;
    final results = await db.query('users', limit: 1);
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  Future<User> createUser(String username, String displayName, String passwordHash, String avatarColor) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();
    
    await db.insert('users', {
      'id': id,
      'username': username,
      'display_name': displayName,
      'password_hash': passwordHash,
      'avatar_color': avatarColor,
      'status': 'online',
      'status_message': '',
      'created_at': now,
    });

    return User(
      id: id,
      username: username,
      displayName: displayName,
      avatarColor: avatarColor,
      status: 'online',
      statusMessage: '',
    );
  }

  Future<User?> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      {
        'display_name': user.displayName,
        'avatar_color': user.avatarColor,
        'status': user.status,
        'status_message': user.statusMessage,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return user;
  }

  Future<bool> verifyPassword(String username, String passwordHash) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, passwordHash],
    );
    return results.isNotEmpty;
  }

  // ============ PEER METHODS ============

  Future<void> upsertPeer(Map<String, dynamic> peerData) async {
    final db = await database;
    final existing = await db.query('peers', where: 'id = ?', whereArgs: [peerData['id']]);
    
    if (existing.isEmpty) {
      await db.insert('peers', peerData);
    } else {
      await db.update('peers', peerData, where: 'id = ?', whereArgs: [peerData['id']]);
    }
  }

  Future<List<Map<String, dynamic>>> getAllPeers() async {
    final db = await database;
    return await db.query('peers', orderBy: 'last_seen DESC');
  }

  Future<Map<String, dynamic>?> getPeer(String peerId) async {
    final db = await database;
    final results = await db.query('peers', where: 'id = ?', whereArgs: [peerId]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updatePeerStatus(String peerId, String status) async {
    final db = await database;
    await db.update(
      'peers',
      {'status': status, 'last_seen': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [peerId],
    );
  }

  // ============ CONTACT METHODS ============

  Future<List<Contact>> getContacts() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT c.*, p.username, p.display_name, p.avatar_color, p.status, 
             p.status_message, p.ip_address, p.last_seen
      FROM contacts c
      JOIN peers p ON c.peer_id = p.id
      ORDER BY c.is_favorite DESC, p.display_name ASC
    ''');
    return results.map((r) => Contact.fromMap(r)).toList();
  }

  Future<Contact> addContact(String peerId) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();

    await db.insert('contacts', {
      'id': id,
      'peer_id': peerId,
      'is_favorite': 0,
      'created_at': now,
    });

    final results = await db.rawQuery('''
      SELECT c.*, p.username, p.display_name, p.avatar_color, p.status, 
             p.status_message, p.ip_address, p.last_seen
      FROM contacts c
      JOIN peers p ON c.peer_id = p.id
      WHERE c.id = ?
    ''', [id]);

    return Contact.fromMap(results.first);
  }

  Future<void> updateContact(String id, {bool? isFavorite, String? nickname}) async {
    final db = await database;
    final updates = <String, dynamic>{};
    if (isFavorite != null) updates['is_favorite'] = isFavorite ? 1 : 0;
    if (nickname != null) updates['nickname'] = nickname;
    
    await db.update('contacts', updates, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteContact(String id) async {
    final db = await database;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  // ============ CONVERSATION METHODS ============

  Future<List<Map<String, dynamic>>> getConversations() async {
    final db = await database;
    return await db.query('conversations', orderBy: 'updated_at DESC');
  }

  Future<String> createConversation(String peerId, {String? name, bool isGroup = false}) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();

    await db.insert('conversations', {
      'id': id,
      'name': name,
      'is_group': isGroup ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    });

    // Add the peer as a member
    await db.insert('conversation_members', {
      'id': '${id}_$peerId',
      'conversation_id': id,
      'peer_id': peerId,
      'joined_at': now,
    });

    return id;
  }

  Future<String?> findConversationWithPeer(String peerId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT c.id FROM conversations c
      JOIN conversation_members cm ON c.id = cm.conversation_id
      WHERE cm.peer_id = ? AND c.is_group = 0
      LIMIT 1
    ''', [peerId]);
    return results.isNotEmpty ? results.first['id'] as String : null;
  }

  Future<List<Map<String, dynamic>>> getConversationMembers(String conversationId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.* FROM conversation_members cm
      JOIN peers p ON cm.peer_id = p.id
      WHERE cm.conversation_id = ?
    ''', [conversationId]);
  }

  // ============ MESSAGE METHODS ============

  Future<List<Message>> getMessages(String conversationId) async {
    final db = await database;
    final results = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );
    
    // Get sender info for each message
    final messages = <Message>[];
    for (final r in results) {
      final senderId = r['sender_id'] as String;
      Map<String, dynamic>? sender;
      
      // Check if sender is local user
      final localUser = await getLocalUser();
      if (localUser != null && localUser.id == senderId) {
        sender = {
          'display_name': localUser.displayName,
          'avatar_color': localUser.avatarColor,
        };
      } else {
        sender = await getPeer(senderId);
      }
      
      messages.add(Message.fromMap(r, sender));
    }
    
    return messages;
  }

  Future<Message> addMessage(String conversationId, String senderId, String content, 
      String senderName, String senderColor, {String messageType = 'text'}) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();

    await db.insert('messages', {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'is_edited': 0,
      'is_deleted': 0,
      'is_sent': 1,
      'created_at': now,
    });

    // Update conversation timestamp
    await db.update(
      'conversations',
      {'updated_at': now},
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    return Message(
      id: id,
      content: content,
      messageType: messageType,
      isEdited: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      senderId: senderId,
      senderName: senderName,
      senderColor: senderColor,
    );
  }

  Future<void> updateMessage(String id, String content) async {
    final db = await database;
    await db.update(
      'messages',
      {'content': content, 'is_edited': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.update(
      'messages',
      {'content': 'This message was deleted', 'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getLastMessage(String conversationId) async {
    final db = await database;
    final results = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // ============ FILE TRANSFER METHODS ============

  Future<List<FileTransfer>> getFileTransfers() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT ft.*, p.display_name as peer_name, p.avatar_color as peer_color
      FROM file_transfers ft
      JOIN peers p ON ft.peer_id = p.id
      ORDER BY ft.created_at DESC
    ''');
    return results.map((r) => FileTransfer.fromMap(r)).toList();
  }

  Future<FileTransfer> addFileTransfer(String peerId, String fileName, int fileSize, 
      String fileType, bool isIncoming, {String? filePath}) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();

    await db.insert('file_transfers', {
      'id': id,
      'peer_id': peerId,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'file_type': fileType,
      'is_incoming': isIncoming ? 1 : 0,
      'status': 'pending',
      'progress': 0,
      'created_at': now,
    });

    final peer = await getPeer(peerId);
    return FileTransfer(
      id: id,
      peerId: peerId,
      peerName: peer?['display_name'] ?? 'Unknown',
      peerColor: peer?['avatar_color'] ?? '#6366f1',
      fileName: fileName,
      filePath: filePath,
      fileSize: fileSize,
      fileType: fileType,
      isIncoming: isIncoming,
      status: 'pending',
      progress: 0,
      createdAt: DateTime.now(),
    );
  }

  Future<void> updateFileTransfer(String id, {String? status, int? progress, String? speed}) async {
    final db = await database;
    final updates = <String, dynamic>{};
    if (status != null) updates['status'] = status;
    if (progress != null) updates['progress'] = progress;
    if (speed != null) updates['speed'] = speed;
    if (status == 'completed') updates['completed_at'] = DateTime.now().toIso8601String();
    
    await db.update('file_transfers', updates, where: 'id = ?', whereArgs: [id]);
  }

  // ============ CALL LOG METHODS ============

  Future<List<CallLog>> getCallLogs() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT cl.*, p.display_name as peer_name, p.avatar_color as peer_color
      FROM call_logs cl
      JOIN peers p ON cl.peer_id = p.id
      ORDER BY cl.created_at DESC
    ''');
    return results.map((r) => CallLog.fromMap(r)).toList();
  }

  Future<void> addCallLog(String peerId, String callType, bool isIncoming, 
      {int duration = 0, String status = 'missed'}) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();

    await db.insert('call_logs', {
      'id': id,
      'peer_id': peerId,
      'call_type': callType,
      'is_incoming': isIncoming ? 1 : 0,
      'duration': duration,
      'status': status,
      'created_at': now,
    });
  }
}
