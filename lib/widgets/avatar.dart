import 'package:flutter/material.dart';
import '../config/theme.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? color;
  final double size;
  final String? status;
  final bool showStatus;

  const UserAvatar({
    super.key,
    required this.name,
    this.color,
    this.size = 40,
    this.status,
    this.showStatus = false,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color get backgroundColor {
    if (color == null) return AppColors.primary500;
    try {
      return Color(int.parse(color!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary500;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'online': return AppColors.online;
      case 'away': return AppColors.away;
      case 'busy': return AppColors.busy;
      default: return AppColors.offline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.35,
              ),
            ),
          ),
        ),
        if (showStatus && status != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.dark900, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class GroupAvatar extends StatelessWidget {
  final double size;

  const GroupAvatar({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary600.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.group, color: AppColors.primary400, size: size * 0.5),
    );
  }
}
