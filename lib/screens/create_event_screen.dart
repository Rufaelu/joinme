import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../data/mock_data.dart';

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
  String? _localImagePath;
  bool _isCreating = false;
  
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
                      onTap: () => context.read<AppState>().navigateTo('map'),
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
                                            : 'Select Date',
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
                                Text('Max People', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                GlassContainer(
                                  padding: EdgeInsets.zero,
                                  child: TextField(
                                    controller: _participantsController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(LucideIcons.users, color: Colors.blue[400], size: 20),
                                      hintText: "e.g. 10",
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

                      // Event Image Selection
                      Text('Event Cover Image', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if (picked != null) {
                            setState(() => _localImagePath = picked.path);
                          }
                        },
                        child: GlassContainer(
                          child: Row(
                            children: [
                              Icon(LucideIcons.image, color: Colors.blue[400]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _localImagePath != null
                                      ? 'Selected: ${_localImagePath!.split('/').last}'
                                      : 'Tap to select cover image',
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_localImagePath != null)
                                GestureDetector(
                                  onTap: () => setState(() => _localImagePath = null),
                                  child: Icon(LucideIcons.trash2, color: Colors.red[400]),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      GestureDetector(
                        onTap: (_title.trim().isNotEmpty && !_isCreating) ? () async {
                          setState(() => _isCreating = true);
                          try {
                            final appState = context.read<AppState>();
                            final loc = appState.pickedLocation;
                            
                            final double lat = loc?.lat ?? 9.0300;
                            final double lng = loc?.lng ?? 38.7400;
                            final String locName = loc?.name ?? 'Addis Ababa';

                            await appState.createNewEvent(
                              title: _title.trim(),
                              category: _selectedCategory == 'custom'
                                  ? _customCategoryController.text.trim()
                                  : _selectedCategory,
                              lat: lat,
                              lng: lng,
                              locationName: locName,
                              maxParticipants: int.tryParse(_participantsController.text) ?? 10,
                              duration: _selectedDuration,
                              description: _descriptionController.text.trim().isNotEmpty 
                                  ? _descriptionController.text.trim() 
                                  : null,
                              localImagePath: _localImagePath,
                            );
                            
                            appState.navigateTo('map');
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to create event: $e'), backgroundColor: Colors.red),
                            );
                          } finally {
                            if (mounted) setState(() => _isCreating = false);
                          }
                        } : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: (_title.trim().isNotEmpty && !_isCreating) 
                              ? Colors.blue[500] 
                              : (isDark ? Colors.white10 : Colors.black12),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: (_title.trim().isNotEmpty && !_isCreating) ? [
                              BoxShadow(
                                color: Colors.blue[600]!.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ] : [],
                          ),
                          child: Center(
                            child: _isCreating 
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
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
