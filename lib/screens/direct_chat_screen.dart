import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../providers/app_state.dart';
import '../models/social.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';

/// Live one-to-one chat with a friend (AppState.selectedFriend: id, name, avatarUrl).
class DirectChatScreen extends StatefulWidget {
  const DirectChatScreen({Key? key}) : super(key: key);

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _friendId;
  String _friendName = '';
  String? _friendAvatar;
  Stream<List<DirectMessage>>? _messages;
  int _lastCount = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    final friend = appState.selectedFriend;
    _friendId = friend?['id'] as String?;
    _friendName = friend?['name'] as String? ?? 'Friend';
    _friendAvatar = friend?['avatarUrl'] as String?;
    if (_friendId != null) {
      _messages = appState.social.directMessages(_friendId!);
      appState.social.markChatRead(_friendId!).catchError((_) {});
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

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _friendId == null || _sending) return;
    if (text.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message is too long (max 2000 characters)')));
      return;
    }
    setState(() => _sending = true);
    try {
      await context.read<AppState>().social.sendDirect(_friendId!, text);
      if (!mounted) return;
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      final msg = e is PostgrestException && e.code == '42501'
          ? 'You can only message friends'
          : 'Message not sent. Check your connection.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _time(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();
    final myId = appState.auth.userId;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark ? [AppTheme.darkBg, AppTheme.darkBg2] : [AppTheme.lightBg, AppTheme.lightBg2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white60,
                  border: Border(bottom: BorderSide(color: AppTheme.primary.withOpacity(0.3), width: 2)),
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
                    Avatar(name: _friendName, url: _friendAvatar, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _friendName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _messages == null
                    ? const Center(child: Text('Chat not found'))
                    : StreamBuilder<List<DirectMessage>>(
                        stream: _messages,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Could not load messages',
                                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                            );
                          }
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          final messages = snapshot.data!;
                          if (messages.length != _lastCount) {
                            _lastCount = messages.length;
                            _scrollToBottom();
                            if (_friendId != null) appState.social.markChatRead(_friendId!).catchError((_) {});
                          }
                          if (messages.isEmpty) {
                            return Center(
                              child: Text('Say hi to ${_friendName.split(' ').first} 👋',
                                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 15)),
                            );
                          }
                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, i) => _bubble(messages[i], messages[i].senderId == myId, isDark),
                          );
                        },
                      ),
              ),

              // Input
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white60,
                  border: Border(top: BorderSide(color: AppTheme.primary.withOpacity(0.3), width: 2)),
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
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _send,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
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

  Widget _bubble(DirectMessage msg, bool isMe, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primary : (isDark ? Colors.white10 : Colors.black12),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Text(msg.body, style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Text(_time(msg.createdAt), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10)),
          ),
        ],
      ),
    ).animate().fadeIn().moveY(begin: 10, end: 0);
  }
}
