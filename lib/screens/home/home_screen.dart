import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/network_provider.dart';
import '../../widgets/avatar.dart';
import '../dashboard/dashboard_screen.dart';
import '../messages/conversations_screen.dart';
import '../contacts/contacts_screen.dart';
import '../transfers/transfers_screen.dart';
import '../calls/calls_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(icon: LucideIcons.layoutDashboard, label: 'Dashboard'),
    _NavItem(icon: LucideIcons.messageSquare, label: 'Messages'),
    _NavItem(icon: LucideIcons.users, label: 'Contacts'),
    _NavItem(icon: LucideIcons.arrowLeftRight, label: 'Transfers'),
    _NavItem(icon: LucideIcons.phone, label: 'Calls'),
    _NavItem(icon: LucideIcons.settings, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _startNetworking();
  }

  void _startNetworking() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      context.read<NetworkProvider>().start(user);
    }
  }

  Widget _buildScreen() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(onNavigate: (i) => setState(() => _currentIndex = i));
      case 1:
        return const ConversationsScreen();
      case 2:
        return const ContactsScreen();
      case 3:
        return const TransfersScreen();
      case 4:
        return const CallsScreen();
      case 5:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isWide = MediaQuery.of(context).size.width > 800;

    if (!isWide) {
      // Mobile layout
      return Scaffold(
        body: _buildScreen(),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.dark900,
            border: Border(top: BorderSide(color: AppColors.dark800)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final isSelected = _currentIndex == index;
                  return InkWell(
                    onTap: () => setState(() => _currentIndex = index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary600.withOpacity(0.15) : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        size: 24,
                        color: isSelected ? AppColors.primary400 : AppColors.dark500,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      );
    }

    // Desktop layout
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: AppColors.dark900,
              border: Border(right: BorderSide(color: AppColors.dark800)),
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.dark800)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary600,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.wifi, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'LocalLink',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Nav items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: List.generate(_navItems.length, (index) {
                      final item = _navItems[index];
                      final isSelected = _currentIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            item.icon,
                            size: 20,
                            color: isSelected ? AppColors.primary400 : AppColors.dark400,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary400 : AppColors.dark400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          tileColor: isSelected ? AppColors.primary600.withOpacity(0.15) : null,
                          onTap: () => setState(() => _currentIndex = index),
                        ),
                      );
                    }),
                  ),
                ),

                // User
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.dark800)),
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                        name: user?.displayName ?? '',
                        color: user?.avatarColor,
                        size: 36,
                        status: user?.status,
                        showStatus: true,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '@${user?.username ?? ''}',
                              style: const TextStyle(color: AppColors.dark500, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.logOut, size: 16),
                        color: AppColors.dark500,
                        onPressed: () => auth.logout(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(child: _buildScreen()),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}
