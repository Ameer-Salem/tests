import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/contact_provider.dart';
import '../../providers/network_provider.dart';
import '../../widgets/avatar.dart';
import '../../widgets/empty_state.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ContactProvider>().loadContacts();
  }

  void _showAddContactSheet() {
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
            const Text('Add Contact', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Select a peer to add to contacts', style: TextStyle(color: AppColors.dark400)),
            const SizedBox(height: 16),
            if (network.peers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No peers discovered on the network', style: TextStyle(color: AppColors.dark500)),
              )
            else
              ...network.peers.map((peer) => ListTile(
                leading: UserAvatar(name: peer.displayName, color: peer.avatarColor, size: 40, status: peer.status, showStatus: true),
                title: Text(peer.displayName, style: const TextStyle(color: Colors.white)),
                subtitle: Text(peer.ipAddress, style: const TextStyle(color: AppColors.dark500, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<ContactProvider>().addContact(peer.id);
                },
              )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContactProvider>();

    return Scaffold(
      backgroundColor: AppColors.dark950,
      appBar: AppBar(title: const Text('Contacts'), actions: [
        IconButton(icon: const Icon(LucideIcons.userPlus), onPressed: _showAddContactSheet),
      ]),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
          : provider.contacts.isEmpty
              ? EmptyState(
                  icon: LucideIcons.users,
                  title: 'No contacts yet',
                  subtitle: 'Add contacts from discovered peers on your network',
                  action: ElevatedButton.icon(
                    onPressed: _showAddContactSheet,
                    icon: const Icon(LucideIcons.userPlus, size: 18),
                    label: const Text('Add Contact'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: provider.loadContacts,
                  color: AppColors.primary500,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.contacts.length,
                    itemBuilder: (context, index) {
                      final contact = provider.contacts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.dark900,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.dark800),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: UserAvatar(name: contact.displayName, color: contact.avatarColor, size: 48, status: contact.status, showStatus: true),
                          title: Row(
                            children: [
                              Text(contact.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              if (contact.isFavorite) ...[
                                const SizedBox(width: 6),
                                const Icon(LucideIcons.star, size: 14, color: Colors.amber),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('@${contact.username}', style: const TextStyle(color: AppColors.dark500, fontSize: 12)),
                              if (contact.ipAddress != null)
                                Text(contact.ipAddress!, style: const TextStyle(color: AppColors.dark600, fontSize: 11)),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(LucideIcons.moreVertical, color: AppColors.dark400, size: 20),
                            color: AppColors.dark800,
                            onSelected: (value) {
                              if (value == 'favorite') provider.toggleFavorite(contact);
                              if (value == 'remove') provider.removeContact(contact);
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'favorite',
                                child: Row(
                                  children: [
                                    Icon(contact.isFavorite ? LucideIcons.starOff : LucideIcons.star, size: 18, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Text(contact.isFavorite ? 'Unfavorite' : 'Favorite'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                                    SizedBox(width: 8),
                                    Text('Remove', style: TextStyle(color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
