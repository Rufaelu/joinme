import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentScreen = context.watch<AppState>().currentScreen;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0d1b1e) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: LucideIcons.map,
              label: 'Map',
              isActive: currentScreen == 'map',
              onTap: () => context.read<AppState>().navigateTo('map'),
            ),
            _NavItem(
              icon: LucideIcons.bell,
              label: 'Activity',
              isActive: currentScreen == 'notifications',
              onTap: () => context.read<AppState>().navigateTo('notifications'),
            ),
            
            // Create Event FAB
            GestureDetector(
              onTap: () => context.read<AppState>().navigateTo('create'),
              child: Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.yellowPrimary, AppTheme.yellowSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.yellowSecondary.withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
              ),
            ),
            
            _NavItem(
              icon: LucideIcons.messageCircle,
              label: 'Chats',
              isActive: currentScreen == 'messages',
              onTap: () => context.read<AppState>().navigateTo('messages'),
            ),
            _NavItem(
              icon: LucideIcons.user,
              label: 'Profile',
              isActive: currentScreen == 'profile',
              onTap: () => context.read<AppState>().navigateTo('profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive 
                ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))
                : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isActive 
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white54 : Colors.black54),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive 
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white54 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
