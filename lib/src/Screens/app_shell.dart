import 'package:flutter/material.dart';
import 'package:joinme/src/Screens/Map_screen.dart';
import 'package:joinme/src/Screens/events_screen.dart';
import 'package:joinme/src/Screens/messages_screen.dart';
import 'package:joinme/src/Screens/profile_screen.dart';

class AppShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const AppShell({super.key, required this.onToggleTheme, required this.isDark});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    MapScreen(),
    EventsScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex],
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'themeToggleShell',
              onPressed: widget.onToggleTheme,
              backgroundColor: widget.isDark ? const Color(0xFFF59E0B) : const Color(0xFF1E293B),
              foregroundColor: widget.isDark ? const Color(0xFF0F172A) : Colors.white,
              child: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: FloatingActionButton(
          heroTag: 'createEventShell',
          onPressed: () => Navigator.pushNamed(context, '/create'),
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: const Color(0xFF0F172A),
          child: const Icon(Icons.add),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 12,
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavIcon(Icons.map, 0, 'Map'),
              _buildNavIcon(Icons.event, 1, 'Events'),
              const SizedBox(width: 48),
              _buildNavIcon(Icons.chat_bubble, 2, 'Messages'),
              _buildNavIcon(Icons.person, 3, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index, String label) {
    final selected = _selectedIndex == index;
    return IconButton(
      onPressed: () => _onItemTapped(index),
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selected ? const Color(0xFFF59E0B) : Colors.grey[500]),
          Text(label, style: TextStyle(fontSize: 10, color: selected ? const Color(0xFFF59E0B) : Colors.grey[500])),
        ],
      ),
    );
  }
}
