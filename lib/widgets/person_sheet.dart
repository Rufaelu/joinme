import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../providers/app_state.dart';
import '../models/models.dart';
import '../models/social.dart';
import '../theme/app_theme.dart';
import 'avatar.dart';

/// Bottom sheet with someone's photo, reputation and a friend action.
Future<void> showPersonSheet(BuildContext context, String userId) async {
  final appState = context.read<AppState>();
  if (userId == appState.auth.userId) return;
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(value: appState, child: _PersonSheet(userId: userId)),
  );
}

class _PersonSheet extends StatefulWidget {
  final String userId;
  const _PersonSheet({required this.userId});

  @override
  State<_PersonSheet> createState() => _PersonSheetState();
}

class _PersonSheetState extends State<_PersonSheet> {
  Person? _person;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await context.read<AppState>().social.person(widget.userId);
      if (mounted) setState(() => _person = p);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load this profile');
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is PostgrestException ? e.message : 'Something went wrong')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = _person;
    final social = context.read<AppState>().social;

    Widget action;
    if (p == null) {
      action = const SizedBox.shrink();
    } else if (p.isDeleted) {
      action = Text('This person deleted their account',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 15));
    } else {
      final (label, icon, onTap) = switch (p.relation) {
        FriendRelation.none => ('Add friend', LucideIcons.userPlus, () => _run(() async => social.addFriend(p.id))),
        FriendRelation.outgoing => ('Request sent · Cancel', LucideIcons.clock, () => _run(() => social.removeFriend(p.id))),
        FriendRelation.incoming => ('Accept friend request', LucideIcons.userCheck, () => _run(() => social.respond(p.id, accept: true))),
        FriendRelation.friends => ('Message', LucideIcons.messageCircle, () {
            Navigator.pop(context);
            context.read<AppState>().navigateTo('directChat', friendData: {'id': p.id, 'name': p.name, 'avatarUrl': p.avatarUrl});
          }),
      };
      final secondary = p.relation == FriendRelation.outgoing;
      action = GestureDetector(
        onTap: _busy ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: secondary ? (isDark ? Colors.white10 : Colors.black12) : AppTheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _busy
              ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: secondary ? (isDark ? Colors.white70 : Colors.black54) : Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(label,
                        style: TextStyle(
                          color: secondary ? (isDark ? Colors.white70 : Colors.black54) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )),
                  ],
                ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg2 : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: p == null
            ? SizedBox(
                height: 160,
                child: Center(child: _error == null ? const CircularProgressIndicator() : Text(_error!)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Avatar(name: p.name, url: p.avatarUrl, size: 80),
                  const SizedBox(height: 12),
                  Text(p.displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_rounded, size: 18, color: AppTheme.primaryLight),
                      const SizedBox(width: 4),
                      Text(
                        p.reputation == null ? 'New to JoinMe' : '${formatReputation(p.reputation)} · ${p.ratingCount} ratings',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  action,
                ],
              ),
      ),
    );
  }
}
