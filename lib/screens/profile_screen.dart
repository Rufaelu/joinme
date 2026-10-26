import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/rating_service.dart';
import '../widgets/glass_container.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<PastEvent>> _pastEvents;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    appState.loadMe();
    _pastEvents = appState.ratings.myPastEvents();
  }

  String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final me = context.watch<AppState>().me;

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
                      'Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.read<AppState>().navigateTo('profileEdit'),
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
                          gradient: LinearGradient(
                            colors: [Colors.yellow[400]!, Colors.blue[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue[600]!.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            me?.initials ?? '…',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 16),
                      Text(
                        me?.name ?? '',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                      ).animate().fadeIn(delay: 100.ms).moveY(begin: 20, end: 0, duration: 400.ms),
                      if (me?.bio != null && me!.bio!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          me.bio!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(isDark, LucideIcons.star, formatReputation(me?.reputation),
                              me == null || me.ratingCount == 0 ? 'Reputation' : 'Reputation (${me.ratingCount})', Colors.yellow[500]!),
                          _buildStatItem(isDark, LucideIcons.calendarCheck, '${me?.eventsAttended ?? 0}', 'Attended', Colors.blue[400]!),
                          _buildStatItem(isDark, LucideIcons.calendarPlus, '${me?.eventsHosted ?? 0}', 'Hosted', Colors.purple[400]!),
                        ],
                      ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0, duration: 400.ms),
                      const SizedBox(height: 32),

                      // Actions
                      _buildActionRow(
                        isDark: isDark,
                        icon: LucideIcons.users,
                        iconColor: Colors.blue[400]!,
                        title: 'Friends',
                        onTap: () => context.read<AppState>().navigateTo('friends'),
                      ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0, duration: 400.ms),
                      const SizedBox(height: 12),
                      _buildActionRow(
                        isDark: isDark,
                        icon: isDark ? LucideIcons.sun : LucideIcons.moon,
                        iconColor: isDark ? Colors.yellow[400]! : Colors.blue[500]!,
                        title: isDark ? 'Light Mode' : 'Dark Mode',
                        onTap: () => context.read<AppState>().toggleTheme(),
                      ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0, duration: 400.ms),
                      
                      const SizedBox(height: 32),
                      
                      // Past Events
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Past Events',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 16),
                      
                      FutureBuilder<List<PastEvent>>(
                        future: _pastEvents,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return snapshot.hasError
                                ? Text('Could not load past events', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))
                                : const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
                          }
                          final past = snapshot.data!;
                          if (past.isEmpty) {
                            return Text('No past events yet. Join one from the map!',
                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54));
                          }
                          return Column(
                            children: past.map((event) {
                        final catColor = AppTheme.colorsFor(event.category);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
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
                                      Text(_date(event.endedAt), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (!event.rated)
                                  GestureDetector(
                                    onTap: () => context.read<AppState>().navigateTo('rate', eventId: event.eventId, groupId: event.groupId),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.yellow[500], borderRadius: BorderRadius.circular(12)),
                                      child: const Text('Rate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0, duration: 400.ms);
                            }).toList(),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Logout
                      GestureDetector(
                        onTap: () => context.read<AppState>().auth.signOut(),
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
