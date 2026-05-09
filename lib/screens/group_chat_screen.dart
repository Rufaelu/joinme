import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/glass_container.dart';

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

  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'senderName': 'Marcus',
      'senderAvatar': '🏃',
      'message': 'Hey everyone! Excited for this!',
      'timestamp': '10:23 AM',
      'isCurrentUser': false,
    },
    {
      'id': '2',
      'senderName': 'Sarah',
      'senderAvatar': '⚡',
      'message': 'Me too! Should we bring anything?',
      'timestamp': '10:25 AM',
      'isCurrentUser': false,
    },
    {
      'id': '3',
      'senderName': 'You',
      'senderAvatar': '😊',
      'message': 'Just yourselves and good vibes!',
      'timestamp': '10:27 AM',
      'isCurrentUser': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _event = mockEvents.firstWhere((e) => e.id == widget.eventId, orElse: () => mockEvents[0]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({
        'id': DateTime.now().toString(),
        'senderName': 'You',
        'senderAvatar': '😊',
        'message': _messageController.text,
        'timestamp': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'isCurrentUser': true,
      });
      _messageController.clear();
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = AppTheme.categoryColors[_event.category]!;

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
                      onTap: () => context.read<AppState>().navigateTo('messages'),
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
                          Text(_event.title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(
                            children: [
                              Icon(LucideIcons.users, size: 12, color: catColor.primary),
                              const SizedBox(width: 4),
                              Text('${_event.participants} participants', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
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
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg['isCurrentUser'] as bool;
                    
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
                              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, shape: BoxShape.circle),
                              child: Center(child: Text(msg['senderAvatar'], style: const TextStyle(fontSize: 16))),
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
                                    child: Text(msg['senderName'], style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 10)),
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
                                    msg['message'],
                                    style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, right: 4),
                                  child: Text(msg['timestamp'], style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn().moveY(begin: 10, end: 0),
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
