import 'package:flutter/material.dart';
import 'package:joinme/src/Screens/edit_profile_screen.dart';
import 'package:joinme/src/Screens/event_detail_screen.dart';
import 'package:joinme/src/models/event.dart';
import 'package:joinme/src/services/app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, child) {
        final user = appState.currentUser;
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).colorScheme.onBackground,
              automaticallyImplyLeading: false,
              title: Text('Profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                  child: const Text('Edit'),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(radius: 34, backgroundImage: NetworkImage(user.avatarUrl)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(user.bio, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.75))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ProfileStat(label: 'Hosted', value: user.eventsHosted.toString()),
                      _ProfileStat(label: 'Joined', value: user.eventsJoined.toString()),
                      _ProfileStat(label: 'Friends', value: user.friendsCount.toString()),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Text('${user.rating.toStringAsFixed(1)} • ${user.reviewCount} reviews', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TabBar(
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).textTheme.bodyLarge?.color,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: const [
                      Tab(text: 'My Events'),
                      Tab(text: 'Friends'),
                      Tab(text: 'Notifications'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _MyEventsTab(),
                        _FriendsTab(),
                        _NotificationsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7))),
      ],
    );
  }
}

class _MyEventsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final joinedEvents = appState.events.where((event) => event.participantIds.contains(appState.currentUser.id)).toList();
    if (joinedEvents.isEmpty) {
      return const Center(child: Text('No joined events yet. Explore the map to find your next plan.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 16),
      itemCount: joinedEvents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = joinedEvents[index];
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          tileColor: Theme.of(context).colorScheme.surface,
          title: Text(event.title),
          subtitle: Text(event.locationName),
          trailing: Text(event.category.label, style: TextStyle(color: Color(event.category.colorValue), fontWeight: FontWeight.bold)),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))),
        );
      },
    );
  }
}

class _FriendsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final friends = appState.friends;
    return ListView.separated(
      padding: const EdgeInsets.only(top: 16),
      itemCount: friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final friend = friends[index];
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          tileColor: Theme.of(context).colorScheme.surface,
          leading: CircleAvatar(backgroundImage: NetworkImage(friend.avatarUrl)),
          title: Text(friend.name),
          subtitle: Text(friend.bio, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: friend.online ? const Icon(Icons.circle, color: Colors.green, size: 14) : null,
        );
      },
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        _NotificationTile(
          title: 'New friend suggestion',
          subtitle: 'People around you want to connect.',
          icon: Icons.people_outline,
        ),
        _NotificationTile(
          title: 'Event reminder',
          subtitle: 'Sunset Pickup Football starts in 6 hours.',
          icon: Icons.notifications_active_outlined,
        ),
        _NotificationTile(
          title: 'Chat update',
          subtitle: 'You have unread messages in the event group.',
          icon: Icons.chat_bubble_outline,
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      tileColor: Theme.of(context).colorScheme.surface,
      leading: CircleAvatar(backgroundColor: const Color(0xFF60A5FA), child: Icon(icon, color: Colors.white)),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    );
  }
}
