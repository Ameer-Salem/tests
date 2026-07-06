import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/theme.dart';
import '../../providers/call_provider.dart';
import '../../widgets/avatar.dart';
import '../../widgets/empty_state.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    context.read<CallProvider>().loadCalls();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CallProvider>();
    final calls = provider.getFilteredCalls(_filter);

    return Scaffold(
      backgroundColor: AppColors.dark950,
      appBar: AppBar(title: const Text('Call History')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            Row(
              children: [
                Expanded(child: _StatCard(icon: LucideIcons.phone, label: 'Total', value: provider.totalCalls.toString(), color: AppColors.info)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: LucideIcons.phoneMissed, label: 'Missed', value: provider.missedCalls.toString(), color: AppColors.error)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: LucideIcons.clock, label: 'Duration', value: provider.formattedTotalDuration, color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 20),

            // Filter
            Row(
              children: ['all', 'incoming', 'outgoing', 'missed'].map((f) {
                final isSelected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(f[0].toUpperCase() + f.substring(1)),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.dark400),
                    backgroundColor: AppColors.dark800,
                    selectedColor: AppColors.primary600,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Call list
            if (provider.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary500)))
            else if (calls.isEmpty)
              const EmptyState(icon: LucideIcons.phone, title: 'No calls yet', subtitle: 'Your call history will appear here')
            else
              ...calls.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dark900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.dark800),
                ),
                child: Row(
                  children: [
                    UserAvatar(name: c.peerName, color: c.peerColor, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.peerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                c.isMissed ? LucideIcons.phoneMissed : c.isIncoming ? LucideIcons.phoneIncoming : LucideIcons.phoneOutgoing,
                                size: 14,
                                color: c.isMissed ? AppColors.error : c.isIncoming ? AppColors.info : AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                c.isMissed ? 'Missed' : c.isIncoming ? 'Incoming' : 'Outgoing',
                                style: TextStyle(color: c.isMissed ? AppColors.error : AppColors.dark400, fontSize: 12),
                              ),
                              if (c.duration > 0) ...[
                                const Text(' • ', style: TextStyle(color: AppColors.dark600)),
                                Text(c.formattedDuration, style: const TextStyle(color: AppColors.dark400, fontSize: 12)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(c.callType == 'video' ? LucideIcons.video : LucideIcons.phone, size: 16, color: AppColors.dark500),
                        const SizedBox(height: 4),
                        Text(timeago.format(c.createdAt), style: const TextStyle(color: AppColors.dark500, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              )),
          ],
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

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.dark900, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.dark800)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.dark400, fontSize: 12)),
        ],
      ),
    );
  }
}
