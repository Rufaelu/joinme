import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../services/event_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  String _selectedCategory = 'sports';
  int _selectedDuration = 60;
  String _title = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _saving = false;
  bool _uploadingCover = false;
  String? _coverUrl;
  
  final _titleController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _participantsController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'value': 'sports', 'label': 'Sports', 'icon': LucideIcons.dumbbell},
    {'value': 'study', 'label': 'Study', 'icon': LucideIcons.bookOpen},
    {'value': 'chill', 'label': 'Chill', 'icon': LucideIcons.coffee},
    {'value': 'creative', 'label': 'Creative', 'icon': LucideIcons.palette},
    {'value': 'custom', 'label': 'Custom', 'icon': LucideIcons.plus},
  ];

  final List<Map<String, dynamic>> _durations = [
    {'value': 30, 'label': '30m'},
    {'value': 60, 'label': '1h'},
    {'value': 120, 'label': '2h'},
    {'value': 180, 'label': '3h'},
  ];

  @override
  void initState() {
    super.initState();
    // Restore what was typed before leaving to pick a location on the map.
    final saved = context.read<AppState>().createFormCache;
    if (saved != null) {
      _titleController.text = saved['title'] as String;
      _title = _titleController.text;
      _descriptionController.text = saved['description'] as String;
      _participantsController.text = saved['groupSize'] as String;
      _selectedCategory = saved['category'] as String;
      _selectedDuration = saved['duration'] as int;
      _selectedDate = saved['date'] as DateTime?;
      _selectedTime = saved['time'] as TimeOfDay?;
      _coverUrl = saved['cover'] as String?;
    }
    if (_participantsController.text.isEmpty) _participantsController.text = '6';
  }

  void _cacheForm() {
    context.read<AppState>().createFormCache = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'groupSize': _participantsController.text,
      'category': _selectedCategory,
      'duration': _selectedDuration,
      'date': _selectedDate,
      'time': _selectedTime,
      'cover': _coverUrl,
    };
  }

  TimeOfDay get _defaultTime {
    final t = DateTime.now().add(const Duration(minutes: 30));
    final rounded = t.add(Duration(minutes: (5 - t.minute % 5) % 5));
    return TimeOfDay(hour: rounded.hour, minute: rounded.minute);
  }

  DateTime get _startsAt {
    final d = _selectedDate ?? DateTime.now();
    final t = _selectedTime ?? _defaultTime;
    var start = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    // Default time can roll past midnight; keep it in the future.
    if (_selectedDate == null && _selectedTime == null && start.isBefore(DateTime.now())) {
      start = start.add(const Duration(days: 1));
    }
    return start;
  }

  EventDraft _draft(PickedLocation? loc) => EventDraft(
        title: _title,
        category: _selectedCategory == 'custom' ? 'creative' : _selectedCategory,
        description: _descriptionController.text,
        locationName: loc?.name,
        lat: loc?.lat,
        lng: loc?.lng,
        startsAt: _startsAt,
        durationMinutes: _selectedDuration,
        groupSize: int.tryParse(_participantsController.text.trim()) ?? 0,
        imageUrl: _coverUrl,
      );

  Future<void> _pickCover() async {
    final storage = context.read<AppState>().storage;
    final file = await storage.pickPhoto();
    if (file == null || !mounted) return;
    setState(() => _uploadingCover = true);
    try {
      final url = await storage.upload(bucket: 'event-images', kind: 'cover', file: file);
      if (mounted) setState(() => _coverUrl = url);
    } catch (e) {
      debugPrint('Cover upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not upload the image. Try a smaller one.')));
      }
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Future<void> _submit() async {
    final appState = context.read<AppState>();
    final draft = _draft(appState.pickedLocation);
    final error = draft.validate(DateTime.now());
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await appState.createEvent(draft);
      appState.createFormCache = null;
      // Replace the form in back history: back from the new event goes home.
      appState.navigateTo('event', eventId: id, replace: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create event: ${e is PostgrestException ? e.message : e}')),
      );
      setState(() => _saving = false);
    }
  }

  /// Marker value for the "Custom" chip (never a real duration).
  static const _customDuration = -1;

  Future<void> _pickCustomDuration() async {
    var picked = Duration(minutes: _selectedDuration);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: isDark ? AppTheme.darkBg2 : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How long is it?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              SizedBox(
                height: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(brightness: isDark ? Brightness.dark : Brightness.light),
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    minuteInterval: 5,
                    initialTimerDuration: Duration(minutes: (_selectedDuration ~/ 5) * 5),
                    onTimerDurationChanged: (d) => picked = d,
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final minutes = picked.inMinutes;
    if (minutes < minDurationMinutes || minutes > maxDurationMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duration must be between 15 minutes and 24 hours')),
      );
      return;
    }
    setState(() => _selectedDuration = minutes);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customCategoryController.dispose();
    _descriptionController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                      onTap: () {
                        final appState = context.read<AppState>();
                        appState.createFormCache = null;
                        appState.navigateTo('map');
                      },
                      child: GlassContainer(
                        borderRadius: 30,
                        padding: const EdgeInsets.all(12),
                        child: Icon(LucideIcons.x, color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    Text(
                      'Create Event',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.read<AppState>().toggleTheme(),
                      child: GlassContainer(
                        borderRadius: 30,
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          isDark ? LucideIcons.sun : LucideIcons.moon,
                          color: isDark ? AppTheme.primaryLight : AppTheme.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text('Event Title', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GlassContainer(
                        padding: EdgeInsets.zero,
                        child: TextField(
                          controller: _titleController,
                          onChanged: (val) => setState(() => _title = val),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: "What's happening?",
                            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Category
                      Text('Category', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat['value'];
                          final catColors = AppTheme.categoryColors[cat['value']] ?? AppTheme.categoryColors['creative']!;
                          
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = cat['value']),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: (MediaQuery.of(context).size.width - 48 - 16) / 3, // 3 columns
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: isSelected 
                                  ? LinearGradient(colors: [catColors.primary, catColors.secondary])
                                  : null,
                                color: isSelected ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                                border: Border.all(
                                  color: isSelected ? Colors.white.withOpacity(0.4) : (isDark ? Colors.white10 : Colors.black12),
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: catColors.primary.withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ] : [],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    cat['icon'],
                                    color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat['label'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      // Custom Category Input
                      if (_selectedCategory == 'custom') ...[
                        const SizedBox(height: 12),
                        GlassContainer(
                          padding: EdgeInsets.zero,
                          child: TextField(
                            controller: _customCategoryController,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              hintText: "Enter custom category...",
                              hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Description
                      Text('Description', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GlassContainer(
                        padding: EdgeInsets.zero,
                        child: TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: "What are the details?",
                            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Cover image (optional)
                      Text('Cover image (optional)', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _uploadingCover ? null : _pickCover,
                        child: GlassContainer(
                          padding: EdgeInsets.zero,
                          child: SizedBox(
                            height: 140,
                            width: double.infinity,
                            child: _uploadingCover
                                ? const Center(child: CircularProgressIndicator())
                                : _coverUrl != null
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(_coverUrl!, fit: BoxFit.cover),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () => setState(() => _coverUrl = null),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                                child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(LucideIcons.image, color: AppTheme.accentLight, size: 32),
                                          const SizedBox(height: 8),
                                          Text('Tap to add a photo', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                                        ],
                                      ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Date & Participants Row
                      Row(
                        children: [
                          // Date Picker
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate ?? DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setState(() => _selectedDate = picked);
                                    }
                                  },
                                  child: GlassContainer(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.calendar, color: AppTheme.accentLight, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          _selectedDate != null 
                                            ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'
                                            : 'Today',
                                          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text('Start time', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: _selectedTime ?? _defaultTime,
                                    );
                                    if (picked != null) {
                                      setState(() => _selectedTime = picked);
                                    }
                                  },
                                  child: GlassContainer(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.clock, color: AppTheme.accentLight, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          (_selectedTime ?? _defaultTime).format(context),
                                          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Max Participants
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Per group', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                GlassContainer(
                                  padding: EdgeInsets.zero,
                                  child: TextField(
                                    controller: _participantsController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(LucideIcons.users, color: AppTheme.accentLight, size: 20),
                                      hintText: "e.g. 6",
                                      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Location Placeholder
                      Text('Location', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Consumer<AppState>(
                        builder: (context, appState, _) {
                          final loc = appState.pickedLocation;
                          return GestureDetector(
                            onTap: () {
                              _cacheForm();
                              appState.setPickingLocation(true);
                              appState.navigateTo('map');
                            },
                            child: GlassContainer(
                              child: Row(
                                children: [
                                  Icon(LucideIcons.mapPin, color: AppTheme.accentLight),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      loc != null ? loc.name : 'Tap to pick location on map', 
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(LucideIcons.chevronRight, color: isDark ? Colors.white54 : Colors.black54),
                                ],
                              ),
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 24),

                      // Duration
                      Text('Duration', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [..._durations, {'value': _customDuration, 'label': 'Custom'}].map((dur) {
                          final isCustomChip = dur['value'] == _customDuration;
                          final isPreset = _durations.any((d) => d['value'] == _selectedDuration);
                          final isSelected = isCustomChip ? !isPreset : _selectedDuration == dur['value'];
                          final label = isCustomChip && !isPreset ? formatDuration(_selectedDuration) : dur['label'] as String;
                          return Expanded(
                            child: GestureDetector(
                              onTap: isCustomChip
                                  ? _pickCustomDuration
                                  : () => setState(() => _selectedDuration = dur['value'] as int),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: isSelected 
                                    ? LinearGradient(colors: [AppTheme.accentLight, AppTheme.accentDark])
                                    : null,
                                  color: isSelected ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                                  border: Border.all(
                                    color: isSelected ? Colors.white.withOpacity(0.4) : (isDark ? Colors.white10 : Colors.black12),
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: AppTheme.accent.withOpacity(0.5),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ] : [],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      LucideIcons.clock,
                                      color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                                      size: 16,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 48),

                      // Submit Button
                      GestureDetector(
                        onTap: _title.trim().isNotEmpty && !_saving && !_uploadingCover ? _submit : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _title.trim().isNotEmpty 
                              ? AppTheme.accent 
                              : (isDark ? Colors.white10 : Colors.black12),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _title.trim().isNotEmpty ? [
                              BoxShadow(
                                color: AppTheme.accentDark.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ] : [],
                          ),
                          child: Center(
                            child: _saving
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : Text(
                              'Create Event',
                              style: TextStyle(
                                color: _title.trim().isNotEmpty ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
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
}
