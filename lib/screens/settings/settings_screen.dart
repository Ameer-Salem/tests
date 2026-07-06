import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/network_provider.dart';
import '../../widgets/avatar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _statusMessageController;
  late String _avatarColor;
  late String _status;
  bool _isSaving = false;
  bool _saved = false;

  static const avatarColors = ['#6366f1', '#ec4899', '#f59e0b', '#10b981', '#8b5cf6', '#ef4444', '#3b82f6', '#14b8a6', '#f97316', '#06b6d4', '#84cc16', '#e11d48'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _displayNameController = TextEditingController(text: user?.displayName ?? '');
    _statusMessageController = TextEditingController(text: user?.statusMessage ?? '');
    _avatarColor = user?.avatarColor ?? '#6366f1';
    _status = user?.status ?? 'online';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _statusMessageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _isSaving = true; _saved = false; });

    final success = await context.read<AuthProvider>().updateProfile(
      displayName: _displayNameController.text.trim(),
      statusMessage: _statusMessageController.text.trim(),
      avatarColor: _avatarColor,
      status: _status,
    );

    if (success) {
      context.read<NetworkProvider>().updateUserInfo(context.read<AuthProvider>().user!);
    }

    setState(() { _isSaving = false; _saved = success; });
    if (_saved) Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _saved = false); });
  }

  Color _parseColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); } catch (e) { return AppColors.primary500; }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final network = context.watch<NetworkProvider>();

    return Scaffold(
      backgroundColor: AppColors.dark950,
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _Section(
              icon: LucideIcons.user,
              title: 'Profile',
              child: Column(
                children: [
                  Row(
                    children: [
                      UserAvatar(name: _displayNameController.text.isNotEmpty ? _displayNameController.text : user?.displayName ?? '', color: _avatarColor, size: 64, status: _status, showStatus: true),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_displayNameController.text.isNotEmpty ? _displayNameController.text : user?.displayName ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                            Text('@${user?.username ?? ''}', style: const TextStyle(color: AppColors.dark500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(controller: _displayNameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Display Name'), onChanged: (_) => setState(() {})),
                  const SizedBox(height: 12),
                  TextField(controller: _statusMessageController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Status Message', hintText: 'What are you up to?')),
                  const SizedBox(height: 16),
                  const Align(alignment: Alignment.centerLeft, child: Text('Status', style: TextStyle(color: AppColors.dark300, fontWeight: FontWeight.w500))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      {'value': 'online', 'label': 'Online', 'color': AppColors.online},
                      {'value': 'away', 'label': 'Away', 'color': AppColors.away},
                      {'value': 'busy', 'label': 'Busy', 'color': AppColors.busy},
                      {'value': 'offline', 'label': 'Offline', 'color': AppColors.offline},
                    ].map((opt) {
                      final isSelected = _status == opt['value'];
                      return FilterChip(
                        selected: isSelected,
                        avatar: Container(width: 10, height: 10, decoration: BoxDecoration(color: opt['color'] as Color, shape: BoxShape.circle)),
                        label: Text(opt['label'] as String),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.dark400),
                        backgroundColor: AppColors.dark800,
                        selectedColor: AppColors.primary600,
                        onSelected: (_) => setState(() => _status = opt['value'] as String),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Appearance
            _Section(
              icon: LucideIcons.palette,
              title: 'Appearance',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Avatar Color', style: TextStyle(color: AppColors.dark300)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: avatarColors.map((c) {
                      final isSelected = _avatarColor == c;
                      return GestureDetector(
                        onTap: () => setState(() => _avatarColor = c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: _parseColor(c), shape: BoxShape.circle, border: isSelected ? Border.all(color: Colors.white, width: 3) : null),
                          child: isSelected ? const Icon(LucideIcons.check, color: Colors.white, size: 18) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Network
            _Section(
              icon: LucideIcons.wifi,
              title: 'Network',
              child: Column(
                children: [
                  _InfoRow('Status', network.isRunning ? 'Active' : 'Inactive', color: network.isRunning ? AppColors.success : AppColors.error),
                  _InfoRow('Mode', 'Peer-to-Peer'),
                  _InfoRow('Discovered Peers', network.peers.length.toString()),
                  _InfoRow('Security', 'Local Network Only', color: AppColors.info),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : _saved ? const Icon(LucideIcons.check, size: 18) : const Icon(LucideIcons.save, size: 18),
                  label: Text(_saved ? 'Saved!' : 'Save Changes'),
                ),
                if (_saved) const Padding(padding: EdgeInsets.only(left: 12), child: Text('Profile updated!', style: TextStyle(color: AppColors.success, fontSize: 14))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Section({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.dark900, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.dark800)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.dark800))),
            child: Row(children: [
              Icon(icon, color: AppColors.primary400, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.dark500)),
          Text(value, style: TextStyle(color: color ?? AppColors.dark300)),
        ],
      ),
    );
  }
}
