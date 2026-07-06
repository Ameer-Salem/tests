import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/network_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/contact_provider.dart';
import '../../providers/transfer_provider.dart';
import '../../providers/call_provider.dart';
import '../../widgets/avatar.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    context.read<ConversationProvider>().loadConversations();
    context.read<ContactProvider>().loadContacts();
    context.read<TransferProvider>().loadTransfers();
    context.read<CallProvider>().loadCalls();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final network = context.watch<NetworkProvider>();
    final conversations = context.watch<ConversationProvider>().conversations;
    final contacts = context.watch<ContactProvider>().contacts;
    final transfers = context.watch<TransferProvider>().transfers;
    final calls = context.watch<CallProvider>().calls;

    return Scaffold(
      backgroundColor: AppColors.dark950,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary500,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Welcome, ${user?.displayName.split(' ')[0]}! 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: network.isRunning ? AppColors.success : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      network.isRunning
                          ? '${network.onlinePeers.length} peer${network.onlinePeers.length != 1 ? 's' : ''} online'
                          : 'Network offline',
                      style: const TextStyle(color: AppColors.dark400),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      icon: LucideIcons.messageSquare,
                      label: 'Conversations',
                      value: conversations.length.toString(),
                      color: AppColors.info,
                      onTap: () => widget.onNavigate?.call(1),
                    ),
                    _StatCard(
                      icon: LucideIcons.users,
                      label: 'Contacts',
                      value: contacts.length.toString(),
                      color: AppColors.success,
                      onTap: () => widget.onNavigate?.call(2),
                    ),
                    _StatCard(
                      icon: LucideIcons.arrowLeftRight,
                      label: 'Transfers',
                      value: transfers.length.toString(),
                      color: const Color(0xFF8B5CF6),
                      onTap: () => widget.onNavigate?.call(3),
                    ),
                    _StatCard(
                      icon: LucideIcons.phone,
                      label: 'Calls',
                      value: calls.length.toString(),
                      color: AppColors.warning,
                      onTap: () => widget.onNavigate?.call(4),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Network Status
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.dark900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.dark800),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.wifi, color: AppColors.primary400, size: 20),
                          SizedBox(width: 8),
                          Text('Network Status', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _InfoTile(label: 'Status', value: network.isRunning ? 'Active' : 'Inactive', color: network.isRunning ? AppColors.success : AppColors.error)),
                          Expanded(child: _InfoTile(label: 'Mode', value: 'P2P', color: AppColors.primary400)),
                          Expanded(child: _InfoTile(label: 'Security', value: 'Local Only', color: AppColors.info)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Online Peers
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.dark900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.dark800),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discovered Peers', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          TextButton(
                            onPressed: () => widget.onNavigate?.call(2),
                            child: const Text('View all', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (network.peers.isEmpty)
                        const Text('No peers discovered yet. Make sure other devices are running LocalLink on the same network.',
                          style: TextStyle(color: AppColors.dark500, fontSize: 14),
                        )
                      else
                        ...network.peers.take(5).map((peer) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              UserAvatar(name: peer.displayName, color: peer.avatarColor, size: 36, status: peer.status, showStatus: true),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(peer.displayName, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    Text(peer.ipAddress, style: const TextStyle(color: AppColors.dark500, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dark900,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dark800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              Text(label, style: const TextStyle(color: AppColors.dark400, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.dark500, fontSize: 12)),
      ],
    );
  }
}
