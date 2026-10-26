import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/glass_container.dart';

class EventDetailScreen extends StatefulWidget {
  final String? eventId;

  const EventDetailScreen({Key? key, this.eventId}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  JoinMeEvent? _event;
  List<EventGroup> _groups = [];
  bool _hasRated = false;
  String? _error;
  bool _joining = false;
  double? _distanceKm;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.eventId;
    if (id == null) {
      setState(() => _error = 'Event not found');
      return;
    }
    final appState = context.read<AppState>();
    try {
      final event = await appState.eventService.fetchOne(id);
      final groups = await appState.chat.groupsFor(id);
      final hasRated = await appState.ratings.hasRated(id);
      if (!mounted) return;
      setState(() {
        _event = event;
        _groups = groups;
        _hasRated = hasRated;
        _error = null;
      });
      _loadDistance(event);
    } catch (e) {
      debugPrint('Event load failed: $e');
      if (mounted) setState(() => _error = 'Could not load this event');
    }
  }

  Future<void> _loadDistance(JoinMeEvent event) async {
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos == null || !mounted) return;
      final meters = Geolocator.distanceBetween(pos.latitude, pos.longitude, event.location.lat, event.location.lng);
      setState(() => _distanceKm = meters / 1000);
    } catch (_) {
      // Distance is optional.
    }
  }

  EventGroup? _myGroup(String? myId) {
    if (myId == null) return null;
    for (final g in _groups) {
      if (g.members.any((m) => m.id == myId)) return g;
    }
    return null;
  }

  Future<void> _join() async {
    final appState = context.read<AppState>();
    setState(() => _joining = true);
    try {
      final groupId = await appState.chat.joinEvent(_event!.id);
      appState.refreshEvents();
      appState.navigateTo('chat', eventId: _event!.id, groupId: groupId);
    } catch (e) {
      if (!mounted) return;
      final msg = e is PostgrestException ? e.message : 'Could not join. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _joining = false);
      _load();
    }
  }

  String _timeLabel(JoinMeEvent e) {
    if (e.hasEnded) return 'Ended';
    if (e.hasStarted) return 'Happening now';
    final m = e.timeRemaining;
    if (m < 60) return '$m minutes';
    if (m < 60 * 24) return '${(m / 60).floor()}h ${m % 60}m';
    return '${(m / (60 * 24)).floor()} days';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final event = _event;

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
          child: event == null
              ? _buildLoadingOrError(isDark)
              : _buildContent(context, isDark, event),
        ),
      ).animate().slideX(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildLoadingOrError(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => context.read<AppState>().navigateTo('map'),
              child: GlassContainer(
                borderRadius: 30,
                padding: const EdgeInsets.all(12),
                child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: _error == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, JoinMeEvent event) {
    final appState = context.watch<AppState>();
    final myId = appState.me?.id ?? appState.auth.userId;
    final myGroup = _myGroup(myId);
    final isHost = event.host.id == myId;
    final catColors = AppTheme.colorsFor(event.category);
    final timeProgress = event.hasStarted ? 1.0 : (1 - event.timeRemaining / 120).clamp(0.0, 1.0);

    return Column(
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
          child: RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      _buildInfoCard(
                        isDark: isDark,
                        icon: LucideIcons.mapPin,
                        iconColor: Colors.blue[400]!,
                        title: 'Location',
                        value: event.location.name,
                        subtitle: _distanceKm == null ? null : '${_distanceKm!.toStringAsFixed(1)} km away',
                      ),
                      const SizedBox(height: 12),
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
                                  Text(event.hasStarted ? 'Status' : 'Starting in',
                                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                                  Text(_timeLabel(event), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
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
                                tween: Tween<double>(begin: 0, end: (event.host.reputation ?? 0) / 5),
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) {
                                  return CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 4,
                                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      (event.host.reputation ?? 0) >= 4.25 ? Colors.blue[400]! : Colors.yellow[500]!
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
                              Text(isHost ? '${event.host.name} (you)' : event.host.name,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                              Row(
                                children: [
                                  Icon(LucideIcons.star, size: 14, color: Colors.yellow[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    event.host.reputation == null
                                        ? 'New host'
                                        : '${formatReputation(event.host.reputation)} · ${event.host.ratingCount} ratings',
                                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0, duration: 400.ms),

                  const SizedBox(height: 32),

                  // Groups
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Groups',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      Text(
                        '${event.participants} going · ${event.groupSize} per group',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 12),
                  ..._groups.map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildGroupCard(isDark, event, g, isMine: g.id == myGroup?.id),
                      )),

                  const SizedBox(height: 36),

                  _buildActionButton(event, myGroup, isHost),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(bool isDark, JoinMeEvent event, EventGroup g, {required bool isMine}) {
    final full = g.members.length >= event.groupSize;
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderColor: isMine ? Colors.yellow[500]!.withOpacity(0.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Group ${g.number}',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              if (isMine) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.yellow[500], borderRadius: BorderRadius.circular(10)),
                  child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
              const Spacer(),
              Text(full ? 'Full' : '${g.members.length}/${event.groupSize}',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...g.members.map((m) => Tooltip(
                    message: m.name,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Colors.yellow[400]!, Colors.blue[600]!]),
                      ),
                      child: Center(
                        child: Text(m.initials,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )),
              ...List.generate((event.groupSize - g.members.length).clamp(0, 8), (index) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? Colors.white24 : Colors.black26, width: 2),
                  ),
                  child: Icon(LucideIcons.users, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(JoinMeEvent event, EventGroup? myGroup, bool isHost) {
    final appState = context.read<AppState>();
    String label;
    IconData icon;
    VoidCallback? onTap;

    if (event.hasEnded) {
      if (canRate(endsAt: event.endsAt, now: DateTime.now(), isMember: myGroup != null, alreadyRated: _hasRated)) {
        label = 'Rate Event';
        icon = LucideIcons.star;
        onTap = () => appState.navigateTo('rate', eventId: event.id, groupId: myGroup!.id);
      } else if (myGroup != null) {
        label = 'Thanks for rating!';
        icon = LucideIcons.checkCircle;
      } else {
        label = 'Event ended';
        icon = LucideIcons.clock;
      }
    } else if (myGroup != null) {
      label = 'Open Group Chat';
      icon = LucideIcons.messageCircle;
      onTap = () => appState.navigateTo('chat', eventId: event.id, groupId: myGroup.id);
    } else {
      label = 'Join Event';
      icon = LucideIcons.users;
      onTap = _joining ? null : _join;
    }

    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: enabled ? Colors.yellow[500] : Colors.grey[600],
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.yellow[600]!.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _joining
              ? const [SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))]
              : [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0, duration: 400.ms);
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
