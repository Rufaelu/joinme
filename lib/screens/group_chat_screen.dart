import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/avatar.dart';
import '../widgets/person_sheet.dart';

class GroupChatScreen extends StatefulWidget {
  final String? eventId;
  final String? groupId;

  const GroupChatScreen({Key? key, this.eventId, this.groupId}) : super(key: key);

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  JoinMeEvent? _event;
  EventGroup? _group;
  Stream<List<ChatMessage>>? _messages;
  int _lastCount = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final groupId = widget.groupId;
    if (groupId != null) {
      _messages = context.read<AppState>().chat.messages(groupId);
    }
    _loadHeader();
  }

  Future<void> _loadHeader() async {
    final eventId = widget.eventId;
    if (eventId == null) return;
    final appState = context.read<AppState>();
    try {
      final event = await appState.eventService.fetchOne(eventId);
      final groups = await appState.chat.groupsFor(eventId);
      if (!mounted) return;
      setState(() {
        _event = event;
        _group = groups.where((g) => g.id == widget.groupId).firstOrNull;
      });
    } catch (e) {
      debugPrint('Chat header load failed: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final groupId = widget.groupId;
    if (text.isEmpty || groupId == null || _sending) return;
    if (text.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message is too long (max 2000 characters)')));
      return;
    }

    setState(() => _sending = true);
    try {
      await context.read<AppState>().chat.send(groupId, text);
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        final msg = e is PostgrestException ? e.message : 'Message not sent. Check your connection.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave group?'),
        content: const Text('You will stop seeing this chat. You can join the event again later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Leave')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final appState = context.read<AppState>();
    try {
      await appState.chat.leaveGroup(widget.groupId!);
      appState.refreshEvents();
      appState.navigateTo('event', eventId: widget.eventId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not leave the group')));
      }
    }
  }

  String _time(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = AppTheme.colorsFor(_event?.category);
    final appState = context.watch<AppState>();
    final myId = appState.me?.id ?? appState.auth.userId;

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
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white60,
                  border: Border(bottom: BorderSide(color: catColor.primary.withOpacity(0.3), width: 2)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.read<AppState>().navigateTo('event', eventId: widget.eventId),
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
                          Text(
                            _event == null ? 'Group chat' : '${_event!.title} · Group ${_group?.number ?? ''}',
                            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Icon(LucideIcons.users, size: 12, color: catColor.primary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _group == null
                                      ? ''
                                      : '${_group!.members.length} members · ${_group!.members.map((m) => m.name.split(' ').first).join(', ')}',
                                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(LucideIcons.moreVertical, color: isDark ? Colors.white54 : Colors.black54),
                      onSelected: (v) {
                        if (v == 'leave') _leaveGroup();
                        if (v == 'event') context.read<AppState>().navigateTo('event', eventId: widget.eventId);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'event', child: Text('Event details')),
                        PopupMenuItem(value: 'leave', child: Text('Leave group')),
                      ],
                    ),
                  ],
                ),
              ),

              // Messages Area
              Expanded(
                child: _messages == null
                    ? const Center(child: Text('Chat not found'))
                    : StreamBuilder<List<ChatMessage>>(
                        stream: _messages,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Could not load messages',
                                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final messages = snapshot.data!;
                          if (messages.length != _lastCount) {
                            _lastCount = messages.length;
                            _scrollToBottom();
                          }
                          if (messages.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'Say hi 👋 Introduce yourself and agree where to meet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 15),
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) => _buildMessage(messages[index], myId, isDark, catColor),
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
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
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
                        child: _sending
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(LucideIcons.send, color: Colors.white, size: 20),
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

  Widget _buildMessage(ChatMessage msg, String? myId, bool isDark, CategoryColors catColor) {
    final isMe = msg.senderId == myId;
    final isHost = msg.senderId == _event?.host.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () => showPersonSheet(context, msg.senderId),
              child: Avatar(name: msg.senderName, url: context.read<AppState>().chat.avatarOf(msg.senderId), size: 32),
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
                    child: Text(isHost ? '${msg.senderName} · Host' : msg.senderName,
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 10)),
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
                    msg.body,
                    style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Text(_time(msg.createdAt), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().moveY(begin: 10, end: 0);
  }
}
