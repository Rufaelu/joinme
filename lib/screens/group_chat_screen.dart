import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/event_model.dart';

class GroupChatScreen extends StatefulWidget {
  final String? eventId;
  
  const GroupChatScreen({Key? key, this.eventId}) : super(key: key);

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late JoinMeEvent _event;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _event = appState.events.firstWhere((e) => e.id == widget.eventId, orElse: () => appState.events.first);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    context.read<AppState>().sendEventMessage(_event.id, text).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Refresh event details in case they changed
    final appState = context.watch<AppState>();
    final currentEvent = appState.events.firstWhere(
      (e) => e.id == widget.eventId,
      orElse: () => _event,
    );
    final catColor = AppTheme.categoryColors[currentEvent.category]!;

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
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white60,
                  border: Border(bottom: BorderSide(color: catColor.primary.withOpacity(0.3), width: 2)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => appState.navigateTo('messages'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, shape: BoxShape.circle),
                        child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentEvent.title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(
                            children: [
                              Icon(LucideIcons.users, size: 12, color: catColor.primary),
                              const SizedBox(width: 4),
                              Text('${currentEvent.participants} participants', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(LucideIcons.phone, color: catColor.primary),
                        const SizedBox(width: 16),
                        Icon(LucideIcons.video, color: catColor.primary),
                        const SizedBox(width: 16),
                        Icon(LucideIcons.moreVertical, color: isDark ? Colors.white54 : Colors.black54),
                      ],
                    ),
                  ],
                ),
              ),

              // Messages Area
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: appState.streamEventMessages(currentEvent.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Failed to load messages.', style: TextStyle(color: Colors.red[300])));
                    }
                    
                    final messages = snapshot.data ?? [];

                    // Auto scroll to bottom
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                      }
                    });

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.messageCircle, size: 48, color: catColor.primary.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text('No messages yet.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                            Text('Say hello to the group!', style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 12)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final senderId = msg['senderId'] as String?;
                        final isMe = senderId == appState.currentUser?.uid;
                        
                        String timeText = '';
                        if (msg['timestamp'] != null) {
                          final date = (msg['timestamp'] as Timestamp).toDate();
                          timeText = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                        } else {
                          timeText = 'Sending...';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe) ...[
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.black12,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      msg['senderAvatar'] as String? ?? 'US',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                                        child: Text(msg['senderName'] as String? ?? 'User', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 10)),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isMe ? catColor.primary : (isDark ? Colors.white10 : Colors.black12),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        msg['message'] as String? ?? '',
                                        style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black)),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4, right: 4),
                                      child: Text(timeText, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ).animate().fadeIn().moveY(begin: 10, end: 0),
                        );
                      },
                    );
                  },
                ),
              ),

              // Input Area
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white60,
                  border: Border(top: BorderSide(color: catColor.primary.withOpacity(0.3), width: 2)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Icon(LucideIcons.image, color: isDark ? Colors.white54 : Colors.black54),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black12,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: catColor.primary, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().slideX(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
    );
  }
}
