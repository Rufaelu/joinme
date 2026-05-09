import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../data/mock_data.dart';
import '../widgets/glass_container.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  String _searchQuery = '';
  String _selectedTab = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pendingCount = mockFriends.where((f) => f.status == 'pending').length;
    final receivedCount = mockFriends.where((f) => f.status == 'received').length;
    final acceptedCount = mockFriends.where((f) => f.status == 'accepted').length;

    final filteredFriends = mockFriends.where((friend) {
      final matchesSearch = friend.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_selectedTab == 'all') return matchesSearch && friend.status == 'accepted';
      return matchesSearch && friend.status == _selectedTab;
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
              GlassContainer(
                borderRadius: 0,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.read<AppState>().navigateTo('profile'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.black12,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Friends',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(LucideIcons.users, color: Colors.blue[400]),
                            const SizedBox(width: 8),
                            Text(
                              '$acceptedCount',
                              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.search, color: isDark ? Colors.white54 : Colors.black54),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                hintText: 'Search friends...',
                                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tabs
                    Row(
                      children: [
                        _buildTabButton('All ($acceptedCount)', 'all', isDark),
                        const SizedBox(width: 8),
                        _buildTabButton('Requests ($receivedCount)', 'received', isDark, notificationCount: receivedCount),
                        const SizedBox(width: 8),
                        _buildTabButton('Sent ($pendingCount)', 'pending', isDark),
                      ],
                    ),
                  ],
                ),
              ),

              // Friends List
              Expanded(
                child: filteredFriends.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.users, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty 
                                ? 'No friends found' 
                                : _selectedTab == 'all' ? 'No friends yet' : _selectedTab == 'received' ? 'No pending requests' : 'No sent requests',
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = filteredFriends[index];
                          return _buildFriendCard(friend, isDark).animate().fadeIn(delay: (50 * index).ms).moveY(begin: 20, end: 0);
                        },
                      ),
              ),
            ],
          ),
        ),
      ).animate().slideX(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildTabButton(String label, String value, bool isDark, {int notificationCount = 0}) {
    final isSelected = _selectedTab == value;
    Color? bgColor;
    if (isSelected) {
      if (value == 'all') bgColor = Colors.blue[500];
      else if (value == 'received') bgColor = Colors.yellow[500];
      else bgColor = Colors.grey[500];
    } else {
      bgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.black12)),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (notificationCount > 0)
                Positioned(
                  top: -10,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$notificationCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCard(Friend friend, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
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
                    tween: Tween<double>(begin: 0, end: friend.reliability / 100),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 3,
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          friend.reliability >= 85 ? Colors.blue[400]! : (friend.reliability >= 70 ? Colors.yellow[500]! : Colors.red[500]!)
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
                      ),
                    ),
                    child: Center(
                      child: Text(
                        friend.avatar,
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
                  Text(friend.name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${friend.reliability}% reliability', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                      if (friend.status == 'accepted') ...[
                        Text(' • ', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                        Text('${friend.mutualEvents} events together', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                      ]
                    ],
                  )
                ],
              ),
            ),
            if (friend.status == 'received')
              Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue[500], shape: BoxShape.circle),
                      child: const Icon(LucideIcons.check, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, shape: BoxShape.circle),
                      child: Icon(LucideIcons.x, color: isDark ? Colors.white54 : Colors.black54, size: 20),
                    ),
                  ),
                ],
              ),
            if (friend.status == 'pending')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('Pending', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            if (friend.status == 'accepted')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[500]!.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[500]!.withOpacity(0.3)),
                ),
                child: Text('Friends', style: TextStyle(color: Colors.blue[400], fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
