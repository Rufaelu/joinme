import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/glass_container.dart';

class RateEventScreen extends StatefulWidget {
  final String? eventId;
  final String? groupId;

  const RateEventScreen({Key? key, this.eventId, this.groupId}) : super(key: key);

  @override
  State<RateEventScreen> createState() => _RateEventScreenState();
}

class _RateEventScreenState extends State<RateEventScreen> {
  JoinMeEvent? _event;
  List<GroupMember> _peers = [];
  String? _error;
  int _eventScore = 0;
  int _hostScore = 0;
  final Map<String, int> _peerScores = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final eventId = widget.eventId;
    if (eventId == null) {
      setState(() => _error = 'Event not found');
      return;
    }
    final appState = context.read<AppState>();
    try {
      final event = await appState.eventService.fetchOne(eventId);
      final groups = await appState.chat.groupsFor(eventId);
      final myId = appState.auth.userId;
      final group = groups.where((g) => g.id == widget.groupId).firstOrNull;
      if (!mounted) return;
      setState(() {
        _event = event;
        // The host is rated separately, so leave them out of the peer list.
        _peers = (group?.members ?? []).where((m) => m.id != myId && m.id != event.host.id).toList();
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load this event');
    }
  }

  bool _isHost(AppState appState) => _event?.host.id == appState.auth.userId;

  Future<void> _submit() async {
    final appState = context.read<AppState>();
    final isHost = _isHost(appState);
    setState(() => _submitting = true);
    try {
      await appState.ratings.submit(
        eventId: _event!.id,
        eventScore: _eventScore,
        hostScore: isHost ? null : _hostScore,
        peerScores: Map.of(_peerScores),
      );
      await appState.loadMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for rating!')));
      appState.navigateTo('profile');
    } catch (e) {
      if (!mounted) return;
      final msg = e is PostgrestException
          ? (e.code == '23505' ? 'You already rated this event' : e.message)
          : 'Could not submit. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();
    final event = _event;
    final isHost = _isHost(appState);
    final ready = event != null && _eventScore > 0 && (isHost || _hostScore > 0) && !_submitting;

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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => appState.navigateTo('event', eventId: widget.eventId),
                      child: GlassContainer(
                        borderRadius: 30,
                        padding: const EdgeInsets.all(12),
                        child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('Rate', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: event == null
                    ? Center(
                        child: _error == null
                            ? const CircularProgressIndicator()
                            : Text(_error!, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        children: [
                          Text(event.title,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('How did it go? Your ratings build everyone\'s reputation.',
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                          const SizedBox(height: 24),
                          _ratingCard(
                            isDark: isDark,
                            title: 'The event',
                            subtitle: event.category.toUpperCase(),
                            leading: Icon(LucideIcons.calendarCheck, color: AppTheme.colorsFor(event.category).primary),
                            value: _eventScore,
                            onChanged: (v) => setState(() => _eventScore = v),
                          ),
                          if (!isHost) ...[
                            const SizedBox(height: 12),
                            _ratingCard(
                              isDark: isDark,
                              title: event.host.name,
                              subtitle: 'Host',
                              leading: _avatar(event.host.avatar),
                              value: _hostScore,
                              onChanged: (v) => setState(() => _hostScore = v),
                            ),
                          ],
                          if (_peers.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text('Your group (optional)',
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ..._peers.map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ratingCard(
                                    isDark: isDark,
                                    title: p.name,
                                    subtitle: 'Group mate',
                                    leading: _avatar(p.initials),
                                    value: _peerScores[p.id] ?? 0,
                                    onChanged: (v) => setState(() => _peerScores[p.id] = v),
                                  ),
                                )),
                          ],
                          const SizedBox(height: 32),
                          GestureDetector(
                            onTap: ready ? _submit : null,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: ready ? Colors.yellow[500] : (isDark ? Colors.white10 : Colors.black12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: _submitting
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                    : Text('Submit Ratings',
                                        style: TextStyle(
                                          color: ready ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        )),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ).animate().fadeIn(),
              ),
            ],
          ),
        ),
      ).animate().slideX(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
    );
  }

  Widget _avatar(String initials) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Colors.yellow[400]!, Colors.blue[600]!]),
      ),
      child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
    );
  }

  Widget _ratingCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required Widget leading,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final filled = i < value;
              return GestureDetector(
                onTap: () => onChanged(i + 1),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.star_rounded,
                    size: 36,
                    color: filled ? Colors.yellow[500] : (isDark ? Colors.white24 : Colors.black26),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
