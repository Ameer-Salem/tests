import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/theme.dart';
import '../../providers/transfer_provider.dart';
import '../../widgets/empty_state.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    context.read<TransferProvider>().loadTransfers();
  }

  IconData _getFileIcon(String fileType) {
    if (fileType.contains('image')) return LucideIcons.fileImage;
    if (fileType.contains('video')) return LucideIcons.fileVideo;
    if (fileType.contains('zip') || fileType.contains('tar')) return LucideIcons.fileArchive;
    if (fileType.contains('pdf') || fileType.contains('document')) return LucideIcons.fileText;
    return LucideIcons.file;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransferProvider>();
    final transfers = provider.getFilteredTransfers(_filter);

    return Scaffold(
      backgroundColor: AppColors.dark950,
      appBar: AppBar(title: const Text('File Transfers')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            Row(
              children: [
                Expanded(child: _StatCard(icon: LucideIcons.arrowUpRight, label: 'Sent', value: provider.totalSent.toString(), color: AppColors.info)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: LucideIcons.arrowDownLeft, label: 'Received', value: provider.totalReceived.toString(), color: AppColors.success)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: LucideIcons.zap, label: 'Total', value: provider.formattedTotalSize, color: const Color(0xFF8B5CF6))),
              ],
            ),
            const SizedBox(height: 20),

            // Filter
            Row(
              children: ['all', 'sent', 'received'].map((f) {
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

            // Transfer list
            if (provider.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary500)))
            else if (transfers.isEmpty)
              const EmptyState(
                icon: LucideIcons.arrowLeftRight,
                title: 'No transfers yet',
                subtitle: 'File transfers will appear here',
              )
            else
              ...transfers.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.dark900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.dark800),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.dark800, borderRadius: BorderRadius.circular(10)),
                      child: Icon(_getFileIcon(t.fileType), color: AppColors.dark400, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.fileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(t.formattedSize, style: const TextStyle(color: AppColors.dark500, fontSize: 12)),
                              const Text(' • ', style: TextStyle(color: AppColors.dark600)),
                              Text(t.isIncoming ? 'From ${t.peerName}' : 'To ${t.peerName}', style: const TextStyle(color: AppColors.dark500, fontSize: 12)),
                            ],
                          ),
                          if (t.status == 'pending') ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: t.progress / 100, backgroundColor: AppColors.dark800, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary500), minHeight: 4),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          t.status == 'completed' ? LucideIcons.checkCircle2 : t.status == 'pending' ? LucideIcons.clock : LucideIcons.xCircle,
                          size: 16,
                          color: t.status == 'completed' ? AppColors.success : t.status == 'pending' ? AppColors.warning : AppColors.error,
                        ),
                        const SizedBox(height: 4),
                        Text(timeago.format(t.createdAt), style: const TextStyle(color: AppColors.dark500, fontSize: 11)),
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
