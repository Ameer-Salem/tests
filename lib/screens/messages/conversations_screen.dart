import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/network_provider.dart';
import '../../widgets/avatar.dart';
import '../../widgets/empty_state.dart';
import '../../models/message.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _messageController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    context.read<ConversationProvider>().loadConversations();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showNewChatSheet() {
    final network = context.read<NetworkProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.dark900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Conversation', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Select a peer to start chatting', style: TextStyle(color: AppColors.dark400)),
            const SizedBox(height: 16),
            if (network.peers.isEmpty)
              const Text('No peers discovered. Make sure other devices are running LocalLink.', style: TextStyle(color: AppColors.dark500))
            else
              ...network.peers.map((peer) => ListTile(
                leading: UserAvatar(name: peer.displayName, color: peer.avatarColor, size: 40, status: peer.status, showStatus: true),
                title: Text(peer.displayName, style: const TextStyle(color: Colors.white)),
                subtitle: Text(peer.ipAddress, style: const TextStyle(color: AppColors.dark500, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final convProvider = context.read<ConversationProvider>();
                  await convProvider.getOrCreateConversation(peer.id);
                },
              )),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    context.read<ConversationProvider>().sendMessage(content, user.id, user.displayName, user.avatarColor);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversationProvider>();
    final user = context.watch<AuthProvider>().user;
    final selectedConv = provider.selectedConversation;

    final isWide = MediaQuery.of(context).size.width > 800;

    // Mobile: show either list or chat
    if (!isWide && selectedConv != null) {
      return _buildChatView(provider, user);
    }

    return Scaffold(
      backgroundColor: AppColors.dark950,
      appBar: AppBar(title: const Text('Messages'), actions: [
        IconButton(icon: const Icon(LucideIcons.plus), onPressed: _showNewChatSheet),
      ]),
      body: Row(
        children: [
          // Conversation list
          SizedBox(
            width: isWide ? 320 : double.infinity,
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
                : provider.conversations.isEmpty
                    ? EmptyState(
                        icon: LucideIcons.messageSquare,
                        title: 'No conversations',
                        subtitle: 'Start a new conversation with a peer',
                        action: ElevatedButton.icon(
                          onPressed: _showNewChatSheet,
                          icon: const Icon(LucideIcons.plus, size: 18),
                          label: const Text('New Chat'),
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.conversations.length,
                        itemBuilder: (context, index) {
                          final conv = provider.conversations[index];
                          final isSelected = selectedConv?.id == conv.id;
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: AppColors.dark800,
                            leading: UserAvatar(name: conv.displayName, color: conv.peerAvatarColor, size: 44, status: conv.peerStatus, showStatus: true),
                            title: Text(conv.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                            subtitle: conv.lastMessageContent != null
                                ? Text(conv.lastMessageContent!, style: const TextStyle(color: AppColors.dark400, fontSize: 13), overflow: TextOverflow.ellipsis)
                                : null,
                            trailing: conv.lastMessageTime != null
                                ? Text(timeago.format(conv.lastMessageTime!, locale: 'en_short'), style: const TextStyle(color: AppColors.dark500, fontSize: 11))
                                : null,
                            onTap: () => provider.selectConversation(conv),
                          );
                        },
                      ),
          ),

          // Chat area (desktop)
          if (isWide)
            Expanded(
              child: selectedConv != null
                  ? _buildChatView(provider, user)
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.messageSquare, size: 48, color: AppColors.dark600),
                          SizedBox(height: 16),
                          Text('Select a conversation', style: TextStyle(color: AppColors.dark400, fontSize: 16)),
                        ],
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatView(ConversationProvider provider, user) {
    final selectedConv = provider.selectedConversation!;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.dark950,
      appBar: AppBar(
        leading: !isWide ? IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => provider.clearSelection()) : null,
        title: Row(
          children: [
            UserAvatar(name: selectedConv.displayName, color: selectedConv.peerAvatarColor, size: 32, status: selectedConv.peerStatus, showStatus: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selectedConv.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(selectedConv.peerStatus ?? 'offline', style: const TextStyle(color: AppColors.dark400, fontSize: 12, fontWeight: FontWeight.normal)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: provider.isLoadingMessages
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
                : provider.messages.isEmpty
                    ? const Center(child: Text('No messages yet. Say hello!', style: TextStyle(color: AppColors.dark500)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.messages.length,
                        itemBuilder: (context, index) {
                          final msg = provider.messages[index];
                          final isMine = msg.senderId == user?.id;
                          return _MessageBubble(message: msg, isMine: isMine);
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.dark900,
              border: Border(top: BorderSide(color: AppColors.dark800)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: AppColors.dark800,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(color: AppColors.primary600, borderRadius: BorderRadius.circular(24)),
                    child: IconButton(icon: const Icon(LucideIcons.send, size: 20), color: Colors.white, onPressed: _sendMessage),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            UserAvatar(name: message.senderName, color: message.senderColor, size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message.senderName, style: const TextStyle(color: AppColors.dark400, fontSize: 11, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    Text(timeago.format(message.createdAt), style: const TextStyle(color: AppColors.dark600, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.isDeleted ? AppColors.dark800.withOpacity(0.5) : isMine ? AppColors.primary600 : AppColors.dark800,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(color: message.isDeleted ? AppColors.dark500 : Colors.white, fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal),
                  ),
                ),
              ],
            ),
          ),
          if (isMine) ...[
            const SizedBox(width: 8),
            UserAvatar(name: message.senderName, color: message.senderColor, size: 28),
          ],
        ],
      ),
    );
  }
}
