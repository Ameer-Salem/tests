import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/database_service.dart';

class ConversationProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  Conversation? _selectedConversation;
  bool _isLoading = false;
  bool _isLoadingMessages = false;

  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  Conversation? get selectedConversation => _selectedConversation;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;

  final _db = DatabaseService.instance;

  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final convMaps = await _db.getConversations();
      final convs = <Conversation>[];

      for (final map in convMaps) {
        final lastMsg = await _db.getLastMessage(map['id']);
        final members = await _db.getConversationMembers(map['id']);
        final peer = members.isNotEmpty ? members.first : null;

        convs.add(Conversation.fromMap(map, lastMessage: lastMsg, peer: peer));
      }

      _conversations = convs;
    } catch (e) {
      print('Error loading conversations: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectConversation(Conversation conversation) async {
    _selectedConversation = conversation;
    _messages = [];
    _isLoadingMessages = true;
    notifyListeners();

    try {
      _messages = await _db.getMessages(conversation.id);
    } catch (e) {
      print('Error loading messages: $e');
    }

    _isLoadingMessages = false;
    notifyListeners();
  }

  void clearSelection() {
    _selectedConversation = null;
    _messages = [];
    notifyListeners();
  }

  Future<void> sendMessage(String content, String senderId, String senderName, String senderColor) async {
    if (_selectedConversation == null) return;

    // Optimistic update
    final optimisticMessage = Message(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      messageType: 'text',
      isEdited: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      senderId: senderId,
      senderName: senderName,
      senderColor: senderColor,
      isOptimistic: true,
    );

    _messages = [..._messages, optimisticMessage];
    notifyListeners();

    try {
      final message = await _db.addMessage(
        _selectedConversation!.id,
        senderId,
        content,
        senderName,
        senderColor,
      );

      _messages = _messages.map((m) {
        if (m.id == optimisticMessage.id) return message;
        return m;
      }).toList();

      // TODO: Send via P2P to peer
      
      await loadConversations();
    } catch (e) {
      _messages = _messages.where((m) => m.id != optimisticMessage.id).toList();
    }

    notifyListeners();
  }

  Future<void> editMessage(String messageId, String newContent) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final oldMessage = _messages[index];
    _messages[index] = oldMessage.copyWith(content: newContent, isEdited: true);
    notifyListeners();

    try {
      await _db.updateMessage(messageId, newContent);
    } catch (e) {
      _messages[index] = oldMessage;
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final oldMessage = _messages[index];
    _messages[index] = oldMessage.copyWith(
      content: 'This message was deleted',
      isDeleted: true,
    );
    notifyListeners();

    try {
      await _db.deleteMessage(messageId);
    } catch (e) {
      _messages[index] = oldMessage;
      notifyListeners();
    }
  }

  Future<String> getOrCreateConversation(String peerId) async {
    var convId = await _db.findConversationWithPeer(peerId);
    if (convId == null) {
      convId = await _db.createConversation(peerId);
      await loadConversations();
    }
    return convId;
  }

  void addIncomingMessage(Message message, String conversationId) {
    if (_selectedConversation?.id == conversationId) {
      _messages = [..._messages, message];
      notifyListeners();
    }
    loadConversations();
  }
}
