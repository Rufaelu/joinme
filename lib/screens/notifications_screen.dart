import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../models/social.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/bottom_nav.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  static const _icons = {
    'friend_request': LucideIcons.userPlus,
    'friend_accepted': LucideIcons.userCheck,
    'event_joined': LucideIcons.users,
    'direct_message': LucideIcons.messageCircle,
  };

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  Future<void> _open(BuildContext context, AppNotification n) async {
    final appState = context.read<AppState>();
    final screen = notificationScreen(n.type);
    switch (screen) {
      case 'friends':
        appState.friendsTab = 'requests';
        appState.navigateTo('friends');
      case 'event':
        if (n.eventId != null) appState.navigateTo('event', eventId: n.eventId);
      case 'directChat':
        if (n.actorId == null) return;
        try {
          final p = await appState.social.person(n.actorId!);
          appState.navigateTo('directChat', friendData: {'id': p.id, 'name': p.name, 'avatarUrl': p.avatarUrl});
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open this chat')));
          }
        }
    }
  }

  Future<void> _clearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('Clear all notifications?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<AppState>().social.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();
    final notifications = appState.notifications;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark ? [AppTheme.darkBg, AppTheme.darkBg2] : [AppTheme.lightBg, AppTheme.lightBg2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.read<AppState>().navigateTo('map'),
                      child: GlassContainer(
                        borderRadius: 30,
                        padding: const EdgeInsets.all(12),
                        child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    Text('Notifications',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: appState.unreadCount == 0 ? null : () => appState.social.markAllRead(),
                          child: GlassContainer(
                            borderRadius: 30,
                            padding: const EdgeInsets.all(12),
                            child: Icon(LucideIcons.checkCheck,
                                color: appState.unreadCount == 0 ? (isDark ? Colors.white24 : Colors.black26) : AppTheme.primaryLight),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: notifications.isEmpty ? null : () => _clearAll(context),
                          child: GlassContainer(
                            borderRadius: 30,
                            padding: const EdgeInsets.all(12),
                            child: Icon(LucideIcons.trash2,
                                color: notifications.isEmpty ? (isDark ? Colors.white24 : Colors.black26) : (isDark ? Colors.white : Colors.black)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.bellOff, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 16),
                            Text("You're all caught up",
                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, i) {
                          final n = notifications[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                if (!n.read) appState.social.markAllRead();
                                _open(context, n);
                              },
                              child: GlassContainer(
                                padding: const EdgeInsets.all(16),
                                borderColor: n.read ? null : AppTheme.primary.withOpacity(0.5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: (n.read ? Colors.grey : AppTheme.primary).withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(_icons[n.type] ?? LucideIcons.bell,
                                          color: n.read ? (isDark ? Colors.white54 : Colors.black54) : AppTheme.primaryLight, size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n.body,
                                            style: TextStyle(
                                              color: isDark ? Colors.white : Colors.black,
                                              fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(_ago(n.createdAt),
                                              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    if (!n.read)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 6, left: 8),
                                        decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: (40 * i).ms).moveX(begin: -16, end: 0);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }
}
