import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../providers/app_state.dart';
import '../models/models.dart';
import '../models/social.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import '../services/social_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late String _tab; // friends | requests | find
  List<Person> _connections = [];
  List<Person> _results = [];
  bool _loading = true;
  bool _searching = false;
  String _query = '';
  Timer? _debounce;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _tab = appState.friendsTab;
    appState.friendsTab = 'friends';
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await context.read<AppState>().social.connections();
      if (mounted) setState(() => _connections = list);
    } catch (e) {
      debugPrint('Loading friends failed: $e');
      _show('Could not load friends');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    if (_tab != 'find') return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> _search() async {
    final q = _query.trim();
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final found = await context.read<AppState>().social.searchPeople(q);
      if (mounted && _query.trim() == q) setState(() => _results = found);
    } catch (e) {
      debugPrint('People search failed: $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  /// Runs a friend action for [p], then refreshes lists.
  Future<void> _act(Person p, Future<void> Function() action, String done) async {
    setState(() => _busy.add(p.id));
    try {
      await action();
      _show(done);
      await _load();
      if (_tab == 'find') await _search();
    } catch (e) {
      _show(e is PostgrestException ? e.message : 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy.remove(p.id));
    }
  }

  void _openChat(Person p) {
    context.read<AppState>().navigateTo('directChat', friendData: {'id': p.id, 'name': p.name, 'avatarUrl': p.avatarUrl});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final friends = _connections.where((p) => p.relation == FriendRelation.friends).toList();
    final requests = _connections.where((p) => p.relation != FriendRelation.friends).toList()
      ..sort((a, b) => a.relation == FriendRelation.incoming ? -1 : (b.relation == FriendRelation.incoming ? 1 : 0));
    final incomingCount = requests.where((p) => p.relation == FriendRelation.incoming).length;

    final q = _query.trim().toLowerCase();
    final List<Person> shown = switch (_tab) {
      'requests' => requests,
      'find' => _results,
      _ => q.isEmpty ? friends : friends.where((p) => p.name.toLowerCase().contains(q)).toList(),
    };

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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white60,
                  border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.read<AppState>().navigateTo('profile'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, shape: BoxShape.circle),
                            child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text('Friends',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        ),
                        Icon(LucideIcons.users, color: AppTheme.accentLight),
                        const SizedBox(width: 8),
                        Text('${friends.length}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                              onChanged: _onQueryChanged,
                              onTap: () {
                                if (_tab == 'requests') setState(() => _tab = 'find');
                              },
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                hintText: _tab == 'find' ? 'Search people by name...' : 'Search friends...',
                                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (_searching) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _tabButton('Friends', 'friends', isDark),
                        const SizedBox(width: 8),
                        _tabButton('Requests', 'requests', isDark, badge: incomingCount),
                        const SizedBox(width: 8),
                        _tabButton('Find people', 'find', isDark),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: shown.isEmpty
                            ? ListView(children: [const SizedBox(height: 120), _empty(isDark)])
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: shown.length,
                                itemBuilder: (context, i) =>
                                    _personCard(shown[i], isDark).animate().fadeIn(delay: (40 * i).ms).moveY(begin: 16, end: 0),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ).animate().slideX(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
    );
  }

  Widget _empty(bool isDark) {
    final text = switch (_tab) {
      'requests' => 'No friend requests',
      'find' => _query.trim().length < 2 ? 'Type a name to find people' : 'Nobody found with that name',
      _ => _query.isNotEmpty ? 'No friends match' : 'No friends yet.\nMeet people at events, or use Find people.',
    };
    return Column(
      children: [
        Icon(LucideIcons.users, size: 64, color: isDark ? Colors.white24 : Colors.black26),
        const SizedBox(height: 16),
        Text(text, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
      ],
    );
  }

  Widget _tabButton(String label, String value, bool isDark, {int badge = 0}) {
    final selected = _tab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _tab = value);
          if (value == 'find') _search();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? Colors.transparent : (isDark ? Colors.white10 : Colors.black12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : (isDark ? Colors.white : Colors.black),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(10)),
                  child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _personCard(Person p, bool isDark) {
    final busy = _busy.contains(p.id);
    final social = context.read<AppState>().social;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          children: [
            Avatar(name: p.name, url: p.avatarUrl, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: AppTheme.primaryLight),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          p.reputation == null ? 'New' : '${formatReputation(p.reputation)} · ${p.ratingCount} ratings',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (busy)
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            else
              ..._actions(p, isDark, social),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(Person p, bool isDark, SocialService social) {
    switch (p.relation) {
      case FriendRelation.friends:
        return [
          _iconButton(LucideIcons.messageCircle, AppTheme.primary, () => _openChat(p)),
          const SizedBox(width: 8),
          _iconButton(LucideIcons.userMinus, isDark ? Colors.white24 : Colors.black26, () async {
            final ok = await _confirm('Remove ${p.name} from your friends?');
            if (ok) _act(p, () => social.removeFriend(p.id), 'Removed ${p.name}');
          }),
        ];
      case FriendRelation.incoming:
        return [
          _iconButton(LucideIcons.check, AppTheme.primary,
              () => _act(p, () => social.respond(p.id, accept: true), 'You and ${p.name} are now friends')),
          const SizedBox(width: 8),
          _iconButton(LucideIcons.x, isDark ? Colors.white24 : Colors.black26,
              () => _act(p, () => social.respond(p.id, accept: false), 'Request declined')),
        ];
      case FriendRelation.outgoing:
        return [
          _pill('Cancel', isDark, () => _act(p, () => social.removeFriend(p.id), 'Request cancelled')),
        ];
      case FriendRelation.none:
        return [
          _iconButton(LucideIcons.userPlus, AppTheme.accent, () => _act(p, () => social.addFriend(p.id), 'Friend request sent')),
        ];
    }
  }

  Future<bool> _confirm(String text) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    return ok == true;
  }

  Widget _iconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _pill(String label, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black12,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('Requested · $label',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
