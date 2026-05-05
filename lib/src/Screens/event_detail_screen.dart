import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:joinme/src/Screens/chat_detail_screen.dart';
import 'package:joinme/src/models/event.dart';
import 'package:joinme/src/services/app_state.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final joined = event.participantIds.contains(appState.currentUser.id);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                  const SizedBox(width: 12),
                  Text(event.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 12))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Color(event.category.colorValue).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(event.category.icon, style: const TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.category.label.toUpperCase(), style: TextStyle(color: Color(event.category.colorValue), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${event.participantsCount}/${event.maxParticipants} joined', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(event.description, style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text('${event.dateTime.month}/${event.dateTime.day} • ${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(event.locationName, style: Theme.of(context).textTheme.bodyMedium)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            CircleAvatar(backgroundImage: NetworkImage(appState.currentUser.id == event.hostId ? appState.currentUser.avatarUrl : appState.friends.firstWhere((user) => user.id == event.hostId).avatarUrl), radius: 24),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hosted by', style: Theme.of(context).textTheme.bodySmall),
                                Text(appState.friends.firstWhere((user) => user.id == event.hostId, orElse: () => appState.currentUser).name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
                                const SizedBox(width: 4),
                                Text(event.rating.toStringAsFixed(1), style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 220,
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
                          child: FlutterMap(
                            options: MapOptions(initialCenter: event.location, initialZoom: 14),
                            children: [
                              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.joinme'),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: event.location,
                                    width: 52,
                                    height: 52,
                                    child: const Icon(Icons.location_pin, size: 48, color: Color(0xFFF59E0B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: () {
                            if (joined) {
                              appState.leaveEvent(event.id);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You left the event')));
                            } else if (event.isFull) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event is full')));
                            } else {
                              appState.joinEvent(event.id);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You joined the event')));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: joined ? Colors.grey[700] : const Color(0xFFF59E0B),
                            foregroundColor: joined ? Colors.white : Colors.black,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(joined ? 'Leave event' : event.isFull ? 'Full' : 'Join now'),
                        ),
                        const SizedBox(height: 12),
                        if (joined)
                          OutlinedButton(
                            onPressed: () {
                              final thread = appState.getChatThreadForEvent(event.id) ?? appState.chatThreads.first;
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(thread: thread)));
                            },
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            child: const Text('Open group chat'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
