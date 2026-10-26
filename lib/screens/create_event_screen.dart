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
      );

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
      appState.navigateTo('event', eventId: id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create event: ${e is PostgrestException ? e.message : e}')),
      );
      setState(() => _saving = false);
    }
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
                          color: isDark ? Colors.yellow[400] : Colors.blue[500],
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
                                        Icon(LucideIcons.calendar, color: Colors.blue[400], size: 20),
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
                                        Icon(LucideIcons.clock, color: Colors.blue[400], size: 20),
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
                                      prefixIcon: Icon(LucideIcons.users, color: Colors.blue[400], size: 20),
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
                                  Icon(LucideIcons.mapPin, color: Colors.blue[400]),
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
                        children: _durations.map((dur) {
                          final isSelected = _selectedDuration == dur['value'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedDuration = dur['value']),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: isSelected 
                                    ? LinearGradient(colors: [Colors.blue[400]!, Colors.blue[600]!])
                                    : null,
                                  color: isSelected ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                                  border: Border.all(
                                    color: isSelected ? Colors.white.withOpacity(0.4) : (isDark ? Colors.white10 : Colors.black12),
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: Colors.blue[500]!.withOpacity(0.5),
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
                                      dur['label'],
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
                        onTap: _title.trim().isNotEmpty && !_saving ? _submit : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _title.trim().isNotEmpty 
                              ? Colors.blue[500] 
                              : (isDark ? Colors.white10 : Colors.black12),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _title.trim().isNotEmpty ? [
                              BoxShadow(
                                color: Colors.blue[600]!.withOpacity(0.4),
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
