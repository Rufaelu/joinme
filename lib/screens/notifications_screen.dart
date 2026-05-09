import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../widgets/glass_container.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> notifications = [
      {
        'id': '1',
        'type': 'request',
        'title': 'New Friend Request',
        'message': 'David Martinez sent you a friend request.',
        'time': '2m ago',
        'read': false,
        'icon': LucideIcons.userPlus,
        'color': Colors.blue[400]!,
      },
      {
        'id': '2',
        'type': 'event_invite',
        'title': 'Event Invitation',
        'message': 'Emma Chen invited you to "Sketch Jam".',
        'time': '1h ago',
        'read': false,
        'icon': LucideIcons.calendarPlus,
        'color': Colors.purple[400]!,
      },
      {
        'id': '3',
        'type': 'event_reminder',
        'title': 'Event Starting Soon',
        'message': '"Study Session - Web Dev" starts in 30 minutes.',
        'time': '30m ago',
        'read': true,
        'icon': LucideIcons.bell,
        'color': Colors.yellow[500]!,
      },
      {
        'id': '4',
        'type': 'system',
        'title': 'Welcome to JoinMe!',
        'message': 'Complete your profile to find more relevant events.',
        'time': '1d ago',
        'read': true,
        'icon': LucideIcons.sparkles,
        'color': Colors.yellow[400]!,
      },
    ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF0d1b1e), const Color(0xFF1a363d)] 
              : [const Color(0xFFf9fafb), const Color(0xFFe5e7eb)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
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
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: GlassContainer(
                        borderRadius: 30,
                        padding: const EdgeInsets.all(12),
                        child: Icon(LucideIcons.checkCheck, color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              // Notifications List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final note = notifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassContainer(
                        backgroundColor: note['read'] 
                            ? (isDark ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.4)) 
                            : (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.8)),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: note['color'].withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(note['icon'], color: note['color']),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note['title'], 
                                          style: TextStyle(
                                            color: isDark ? Colors.white : Colors.black, 
                                            fontWeight: note['read'] ? FontWeight.normal : FontWeight.bold, 
                                            fontSize: 16
                                          )
                                        ),
                                      ),
                                      if (!note['read'])
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    note['message'], 
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.black87, 
                                      fontSize: 14
                                    )
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    note['time'], 
                                    style: TextStyle(
                                      color: isDark ? Colors.white54 : Colors.black54, 
                                      fontSize: 12
                                    )
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (50 * index).ms).moveY(begin: 20, end: 0),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ).animate().slideX(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
    );
  }
}
