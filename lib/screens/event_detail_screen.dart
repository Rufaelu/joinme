import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../providers/app_state.dart';
import '../models/event_model.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/glass_container.dart';

class EventDetailScreen extends StatelessWidget {
  final String? eventId;
  
  const EventDetailScreen({Key? key, this.eventId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final appState = context.watch<AppState>();
    final events = appState.events;
    // Find event or use default
    final JoinMeEvent event = events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => events.isNotEmpty ? events[0] : mockEvents[0],
    );
    
    final currentUser = appState.currentUser;
    final userInitials = currentUser != null && currentUser.fullName.isNotEmpty
        ? currentUser.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'US';
    
    final isOrganizer = event.organizerId == currentUser?.uid;
    final isParticipant = event.participantAvatars.contains(userInitials) || isOrganizer;

    final catColors = AppTheme.categoryColors[event.category]!;
    final timeProgress = ((event.duration - event.timeRemaining) / event.duration);

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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [catColors.primary, catColors.secondary]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: catColors.primary.withOpacity(0.5),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Text(
                        event.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.read<AppState>().toggleTheme(),
                      child: GlassContainer(
                        borderRadius: 30,
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          isDark ? LucideIcons.sun : LucideIcons.moon,
                          color: isDark ? Colors.yellow[400] : Colors.blue[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ).animate().fadeIn().moveY(begin: 20, end: 0, duration: 400.ms),
                      
                      if (event.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          event.description!,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ).animate().fadeIn(delay: 100.ms).moveY(begin: 20, end: 0, duration: 400.ms),
                      ],
                      
                      const SizedBox(height: 24),

                      // Info Cards
                      Column(
                        children: [
                          // Location
                          _buildInfoCard(
                            isDark: isDark,
                            icon: LucideIcons.mapPin,
                            iconColor: Colors.blue[400]!,
                            title: 'Location',
                            value: event.location.name,
                            subtitle: '0.5 km away',
                          ),
                          const SizedBox(height: 12),
                          // Time Remaining
                          GlassContainer(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: 0, end: timeProgress),
                                        duration: const Duration(milliseconds: 1000),
                                        builder: (context, value, _) {
                                          return CircularProgressIndicator(
                                            value: value,
                                            strokeWidth: 4,
                                            backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[400]!),
                                          );
                                        },
                                      ),
                                      Icon(LucideIcons.clock, color: Colors.yellow[400], size: 20),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Starting in', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                                      Text('${event.timeRemaining} minutes', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Duration
                          _buildInfoCard(
                            isDark: isDark,
                            icon: LucideIcons.clock,
                            iconColor: Colors.blue[400]!,
                            title: 'Duration',
                            value: '${event.duration} minutes',
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0, duration: 400.ms),

                      const SizedBox(height: 32),

                      // Host Section
                      Text(
                        'Host',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 12),
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: event.host.reliability / 100),
                                    duration: const Duration(milliseconds: 1500),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, _) {
                                      return CircularProgressIndicator(
                                        value: value,
                                        strokeWidth: 4,
                                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          event.host.reliability >= 85 ? Colors.blue[400]! : Colors.yellow[500]!
                                        ),
                                      );
                                    },
                                  ),
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Colors.yellow[400]!, Colors.blue[600]!],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        event.host.avatar,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.host.name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text('${event.host.reliability}% reliability', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0, duration: 400.ms),

                      const SizedBox(height: 32),

                      // Participants
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Participants',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          Text(
                            '${event.participants}/${event.maxParticipants}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 12),
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...event.participantAvatars.asMap().entries.map((e) {
                              return Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Colors.yellow[400]!, Colors.blue[600]!],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    e.value,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ).animate().scale(delay: (500 + e.key * 50).ms, duration: 300.ms);
                            }),
                            ...List.generate(event.maxParticipants - event.participants, (index) {
                              return Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? Colors.white24 : Colors.black26,
                                    width: 2,
                                    style: BorderStyle.solid, // Custom paint needed for dashed, skipping for simplicity
                                  ),
                                ),
                                child: Icon(LucideIcons.users, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                              );
                            })
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0, duration: 400.ms),

                      const SizedBox(height: 48),

                      // Join / Leave / Open Chat button
                      Column(
                        children: [
                          if (isParticipant) ...[
                            // Open Chat Button
                            GestureDetector(
                              onTap: () => appState.navigateTo('chat', eventId: event.id),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.yellow[500],
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.yellow[600]!.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(LucideIcons.messageSquare, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Open Group Chat',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isOrganizer) ...[
                              const SizedBox(height: 12),
                              // Leave Event Button
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    await appState.leaveEvent(event.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('You left the event.'), backgroundColor: Colors.orange),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to leave event: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.black12,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.userMinus, color: Colors.red[400], size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Leave Event',
                                        style: TextStyle(
                                          color: Colors.red[400],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ] else ...[
                            // Join Button
                            GestureDetector(
                              onTap: () async {
                                try {
                                  await appState.joinEvent(event.id);
                                  appState.navigateTo('chat', eventId: event.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Successfully joined event!'), backgroundColor: Colors.green),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to join event: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.yellow[500],
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.yellow[600]!.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(LucideIcons.userPlus, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Join Event',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0, duration: 400.ms),
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

  Widget _buildInfoCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue[500]!.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
