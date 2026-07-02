import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.yellow[500]),
        ),
      );
    }

    final avatarInitials = user.fullName.isNotEmpty
        ? user.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'US';

    // Calculate real stats
    final hostedCount = appState.events.where((e) => e.organizerId == user.uid).length;
    final joinedCount = appState.events.where((e) => e.participantAvatars.contains(avatarInitials) && e.organizerId != user.uid).length;
    final totalAttended = hostedCount + joinedCount;

    // Filter events user is involved in
    final userEvents = appState.events.where((e) => e.organizerId == user.uid || e.participantAvatars.contains(avatarInitials)).toList();

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
                      onTap: () => appState.navigateTo('map'),
                      child: GlassContainer(
                        borderRadius: 30,
                        padding: const EdgeInsets.all(12),
                        child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => appState.navigateTo('profileEdit'),
                      child: GlassContainer(
                        borderRadius: 30,
                        padding: const EdgeInsets.all(12),
                        child: Icon(LucideIcons.edit2, color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    children: [
                      // Avatar & Name
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: user.photoUrl == null
                              ? LinearGradient(
                                  colors: [Colors.yellow[400]!, Colors.blue[600]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue[600]!.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: user.photoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: CachedNetworkImage(
                                  imageUrl: user.photoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => Center(
                                    child: Text(
                                      avatarInitials,
                                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  avatarInitials,
                                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                ),
                              ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                      ).animate().fadeIn(delay: 100.ms).moveY(begin: 20, end: 0, duration: 400.ms),
                      const SizedBox(height: 32),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(isDark, LucideIcons.star, '${user.reliability}%', 'Reliability', Colors.yellow[500]!),
                          _buildStatItem(isDark, LucideIcons.calendarCheck, '$totalAttended', 'Attended', Colors.blue[400]!),
                          _buildStatItem(isDark, LucideIcons.calendarPlus, '$hostedCount', 'Hosted', Colors.purple[400]!),
                        ],
                      ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0, duration: 400.ms),
                      const SizedBox(height: 32),

                      // Actions
                      _buildActionRow(
                        isDark: isDark,
                        icon: LucideIcons.users,
                        iconColor: Colors.blue[400]!,
                        title: 'Friends',
                        onTap: () => appState.navigateTo('friends'),
                      ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0, duration: 400.ms),
                      const SizedBox(height: 12),
                      _buildActionRow(
                        isDark: isDark,
                        icon: isDark ? LucideIcons.sun : LucideIcons.moon,
                        iconColor: isDark ? Colors.yellow[400]! : Colors.blue[500]!,
                        title: isDark ? 'Light Mode' : 'Dark Mode',
                        onTap: () => appState.toggleTheme(),
                      ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0, duration: 400.ms),
                      
                      const SizedBox(height: 32),
                      
                      // Active Events Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Your Events',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 16),
                      
                      if (userEvents.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Text(
                            'No active events yet.',
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                          ),
                        ).animate().fadeIn(delay: 600.ms)
                      else
                        ...userEvents.map((event) {
                          final catColor = AppTheme.categoryColors[event.category]!;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GestureDetector(
                              onTap: () => appState.navigateTo('event', eventId: event.id),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: catColor.primary.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(LucideIcons.calendar, color: catColor.primary),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(event.title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text(event.location.name, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0, duration: 400.ms);
                        }).toList(),
                      
                      const SizedBox(height: 32),
                      
                      // Logout
                      GestureDetector(
                        onTap: () async {
                          try {
                            await appState.logOut();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to log out: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        child: Text(
                          'Log Out',
                          style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ).animate().fadeIn(delay: 800.ms),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().slideX(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildStatItem(bool isDark, IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
      ],
    );
  }

  Widget _buildActionRow({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Icon(LucideIcons.chevronRight, color: isDark ? Colors.white54 : Colors.black54),
          ],
        ),
      ),
    );
  }
}
