import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:joinme/src/models/event.dart';
import 'package:joinme/src/services/app_state.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  EventCategory? _category = EventCategory.social;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _maxParticipants = 6;
  LatLng? _pickedLocation;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _selectedTime);
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) {
    setState(() => _pickedLocation = point);
  }

  void _saveEvent() {
    if (_formKey.currentState?.validate() != true || _pickedLocation == null || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete the event details and location')));
      return;
    }

    final event = EventModel(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category!,
      dateTime: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      location: _pickedLocation!,
      locationName: 'Selected location',
      hostId: appState.currentUser.id,
      maxParticipants: _maxParticipants,
      participantIds: [appState.currentUser.id],
      rating: 4.9,
      duration: '2h',
    );
    appState.createEvent(event);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event created successfully')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      validator: (value) => value?.trim().isEmpty == true ? 'Title required' : null,
                      decoration: const InputDecoration(labelText: 'Event title'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      validator: (value) => value?.trim().isEmpty == true ? 'Description required' : null,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: EventCategory.values.map((category) {
                        final selected = _category == category;
                        return ChoiceChip(
                          label: Text(category.label),
                          selected: selected,
                          selectedColor: Color(category.colorValue).withOpacity(0.18),
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          labelStyle: TextStyle(color: selected ? Color(category.colorValue) : Theme.of(context).textTheme.bodyLarge?.color),
                          onSelected: (_) => setState(() => _category = category),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickDate,
                            child: Text('${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickTime,
                            child: Text(_selectedTime.format(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Pick location', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 240,
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        clipBehavior: Clip.hardEdge,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(9.03, 38.74),
                            initialZoom: 13,
                            onLongPress: _onMapLongPress,
                          ),
                          children: [
                            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.joinme'),
                            if (_pickedLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _pickedLocation!,
                                    width: 56,
                                    height: 56,
                                    child: const Icon(Icons.location_on, size: 48, color: Color(0xFFF59E0B)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_pickedLocation == null ? 'Long press map to choose the meetup spot' : 'Location selected: ${_pickedLocation!.latitude.toStringAsFixed(4)}, ${_pickedLocation!.longitude.toStringAsFixed(4)}'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Capacity'),
                        const Spacer(),
                        Text('$_maxParticipants'),
                      ],
                    ),
                    Slider(
                      value: _maxParticipants.toDouble(),
                      min: 2,
                      max: 20,
                      divisions: 18,
                      label: '$_maxParticipants',
                      onChanged: (value) => setState(() => _maxParticipants = value.round()),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveEvent,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Create event'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
