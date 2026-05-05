import 'package:flutter/material.dart';
import 'package:joinme/src/Screens/chat_detail_screen.dart';
import 'package:joinme/src/services/app_state.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Messages', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Realtime chat for events and friends.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.75))),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: appState.chatThreads.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final thread = appState.chatThreads[index];
                        return ListTile(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(thread: thread))),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          tileColor: Theme.of(context).colorScheme.surface,
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFF3B82F6).withOpacity(0.15),
                            child: Text(thread.isGroup ? 'G' : 'D', style: const TextStyle(color: Color(0xFF3B82F6))),
                          ),
                          title: Text(thread.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          subtitle: Text(thread.messages.last.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: thread.unreadCount > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(14)),
                                  child: Text('${thread.unreadCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                )
                              : null,
                        );
                      },
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
