import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/glass_container.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _searchQuery = '';
  String _activeTab = 'all';

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final avatarInitials = user != null && user.fullName.isNotEmpty
        ? user.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'US';

    final userEvents = appState.events.where((e) =>
        e.organizerId == user?.uid || e.participantAvatars.contains(avatarInitials)).toList();

    final List<Map<String, dynamic>> mockChats = [
      ...userEvents.map((e) => {
        'id': e.id,
        'type': 'group',
        'name': e.title,
        'avatar': e.category == 'sports' ? '⚽' : e.category == 'study' ? '📚' : e.category == 'chill' ? '☕' : '🎨',
        'lastMessage': '${e.host.name}: Active conversation',
        'timestamp': e.updatedAt,
        'unreadCount': 0,
        'category': e.category,
        'participantCount': e.participants,
      }),
      {
        'id': 'friend-1',
        'type': 'friend',
        'name': 'Emma Wilson',
        'avatar': 'EW',
        'lastMessage': 'Want to grab coffee later?',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
        'unreadCount': 2
      },
      {
        'id': 'friend-2',
        'type': 'friend',
        'name': 'Jake Martinez',
        'avatar': 'JM',
        'lastMessage': 'Thanks for the study session!',
        'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
        'unreadCount': 0
      },
    ];

    mockChats.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    final filteredChats = mockChats.where((chat) {
      final matchesSearch = (chat['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesTab = _activeTab == 'all' || chat['type'] == _activeTab || (_activeTab == 'groups' && chat['type'] == 'group') || (_activeTab == 'friends' && chat['type'] == 'friend');
      return matchesSearch && matchesTab;
    }).toList();

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
                        child: Icon(LucideIcons.arrowLeft, color: Colors.yellow[600]),
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.yellow[500]!, Colors.blue[400]!],
                      ).createShader(bounds),
                      child: const Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // balance
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(LucideIcons.search, color: isDark ? Colors.white54 : Colors.black54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Search chats...',
                            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: ['all', 'groups', 'friends'].map((tab) {
                      final isSelected = _activeTab == tab;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = tab),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: isSelected 
                                ? LinearGradient(colors: [Colors.yellow[500]!, Colors.blue[500]!])
                                : null,
                            ),
                            child: Center(
                              child: Text(
                                tab[0].toUpperCase() + tab.substring(1),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Chats List
              Expanded(
                child: filteredChats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.messageCircle, size: 64, color: Colors.yellow[600]),
                            const SizedBox(height: 16),
                            Text('No chats', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Join events or add friends to start chatting', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                if (chat['type'] == 'group') {
                                  context.read<AppState>().navigateTo('chat', eventId: chat['id']);
                                } else {
                                  context.read<AppState>().navigateTo('directChat');
                                }
                              },
                              child: GlassContainer(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Stack(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: chat['type'] == 'group' 
                                                ? null 
                                                : LinearGradient(colors: [Colors.yellow[500]!, Colors.blue[500]!]),
                                            color: chat['type'] == 'group' ? Colors.blue[400]!.withOpacity(0.2) : null,
                                            border: chat['type'] == 'group' ? Border.all(color: Colors.blue[400]!.withOpacity(0.4), width: 2) : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              chat['avatar'],
                                              style: TextStyle(
                                                color: chat['type'] == 'group' ? Colors.blue[400] : Colors.white,
                                                fontSize: chat['type'] == 'group' ? 24 : 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: chat['type'] == 'group' ? Colors.blue[500] : Colors.yellow[600],
                                              shape: BoxShape.circle,
                                              border: Border.all(color: isDark ? const Color(0xFF1a363d) : Colors.white, width: 2),
                                            ),
                                            child: Icon(
                                              chat['type'] == 'group' ? LucideIcons.users : LucideIcons.user,
                                              color: Colors.white,
                                              size: 10,
                                            ),
                                          ),
                                        )
                                      ],
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
                                                  chat['name'],
                                                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                _formatTime(chat['timestamp'] as DateTime),
                                                style: TextStyle(color: Colors.yellow[600], fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  chat['lastMessage'],
                                                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (chat['type'] == 'group') ...[
                                                const SizedBox(width: 8),
                                                Icon(LucideIcons.users, size: 12, color: isDark ? Colors.white54 : Colors.black54),
                                                const SizedBox(width: 2),
                                                Text('${chat['participantCount']}', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                                              ]
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (chat['unreadCount'] > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [Colors.yellow[500]!, Colors.blue[500]!]),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text('${chat['unreadCount']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      )
                                    ]
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: (50 * index).ms).moveX(begin: -20, end: 0),
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
