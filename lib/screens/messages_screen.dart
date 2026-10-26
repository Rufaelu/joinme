import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../services/chat_service.dart';
import '../models/models.dart';
import '../models/social.dart';
import '../widgets/avatar.dart';
import '../widgets/glass_container.dart';
import '../theme/app_theme.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _searchQuery = '';
  String _activeTab = 'all';
  List<MyGroup> _groups = [];
  List<DmThread> _threads = [];

  static const _categoryEmojis = {'sports': '⚽', 'study': '📚', 'chill': '☕', 'creative': '🎨'};

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final appState = context.read<AppState>();
    try {
      final groups = await appState.chat.myGroups();
      if (mounted) setState(() => _groups = groups);
    } catch (e) {
      debugPrint('Loading groups failed: $e');
    }
    try {
      final threads = await appState.social.threads();
      if (mounted) setState(() => _threads = threads);
    } catch (e) {
      debugPrint('Loading direct chats failed: $e');
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.isNegative) return '';
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final unreadFrom = <String, int>{};
    for (final n in context.watch<AppState>().notifications) {
      if (!n.read && n.type == 'direct_message' && n.actorId != null) {
        unreadFrom[n.actorId!] = (unreadFrom[n.actorId!] ?? 0) + 1;
      }
    }

    final List<Map<String, dynamic>> chats = [
      ..._groups.map((g) => {
        'id': g.groupId,
        'eventId': g.eventId,
        'type': 'group',
        'name': '${g.eventTitle} · Group ${g.groupNumber}',
        'avatar': _categoryEmojis[g.category] ?? '📍',
        'lastMessage': g.lastMessage ?? (g.endsAt.isBefore(DateTime.now()) ? 'Event ended — rate it!' : 'No messages yet'),
        'timestamp': g.lastAt ?? g.endsAt,
        'unreadCount': 0,
        'category': g.category,
        'participantCount': g.memberCount,
      }),
      ..._threads.map((t) => {
        'id': t.friend.id,
        'type': 'friend',
        'name': t.friend.name,
        'avatar': initialsOf(t.friend.name),
        'avatarUrl': t.friend.avatarUrl,
        'lastMessage': t.lastMessage ?? 'Say hi 👋',
        'timestamp': t.lastAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        'unreadCount': unreadFrom[t.friend.id] ?? 0,
      }),
    ];

    chats.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    final filteredChats = chats.where((chat) {
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
              ? [AppTheme.darkBg, AppTheme.darkBg2] 
              : [AppTheme.lightBg, AppTheme.lightBg2],
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
                        child: Icon(LucideIcons.arrowLeft, color: AppTheme.primaryDark),
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accentLight],
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
                                ? LinearGradient(colors: [AppTheme.primary, AppTheme.accent])
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
                            Icon(LucideIcons.messageCircle, size: 64, color: AppTheme.primaryDark),
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
                                  context.read<AppState>().navigateTo('chat', eventId: chat['eventId'], groupId: chat['id']);
                                } else {
                                  context.read<AppState>().navigateTo('directChat', friendData: {
                                    'id': chat['id'],
                                    'name': chat['name'],
                                    'avatarUrl': chat['avatarUrl'],
                                  });
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
                                                : LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                                            color: chat['type'] == 'group' ? AppTheme.accentLight.withOpacity(0.2) : null,
                                            border: chat['type'] == 'group' ? Border.all(color: AppTheme.accentLight.withOpacity(0.4), width: 2) : null,
                                          ),
                                          child: chat['type'] == 'friend'
                                              ? Avatar(name: chat['name'] as String, url: chat['avatarUrl'] as String?, size: 56)
                                              : Center(
                                            child: Text(
                                              chat['avatar'],
                                              style: TextStyle(
                                                color: chat['type'] == 'group' ? AppTheme.accentLight : Colors.white,
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
                                              color: chat['type'] == 'group' ? AppTheme.accent : AppTheme.primaryDark,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: isDark ? AppTheme.darkBg2 : Colors.white, width: 2),
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
                                                (chat['timestamp'] as DateTime).millisecondsSinceEpoch == 0 ? '' : _formatTime(chat['timestamp'] as DateTime),
                                                style: TextStyle(color: AppTheme.primaryDark, fontSize: 12),
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
                                          gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
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
