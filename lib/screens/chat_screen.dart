// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/messaging_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String currentUserId;
  final String currentUserEmail;
  final String otherPersonEmail;
  final String otherPersonId;
  final String equipmentTitle;

  const ChatScreen({
    required this.conversationId,
    required this.currentUserId,
    required this.currentUserEmail,
    required this.otherPersonEmail,
    required this.otherPersonId,
    required this.equipmentTitle,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _svc = MessagingService();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await _svc.sendMessage(
      conversationId: widget.conversationId,
      senderId: widget.currentUserId,
      senderEmail: widget.currentUserEmail,
      text: text,
      recipientEmail: widget.otherPersonEmail,
      recipientId: widget.otherPersonId,
      equipmentTitle: widget.equipmentTitle,
    );
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherPersonEmail,
                style: AppFonts.dmMono(fontSize: 13)),
            Text(widget.equipmentTitle,
                style: AppFonts.dmMono(
                    fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _svc.getMessages(widget.conversationId),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.orange, strokeWidth: 2));
                }
                final msgs = snap.data!;
                if (msgs.isEmpty) {
                  return Center(
                    child: Text('No messages yet.\nSay hello!',
                        textAlign: TextAlign.center,
                        style: AppFonts.dmMono(
                            fontSize: 13, color: AppColors.textMuted)),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _MessageBubble(
                    message: msgs[i],
                    isMe: msgs[i].senderId == widget.currentUserId,
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: AppFonts.dmMono(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: AppFonts.dmMono(
                          fontSize: 13, color: AppColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: AppColors.orange, size: 20),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppColors.orange : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.text,
                style: AppFonts.dmMono(
                    fontSize: 13,
                    color: isMe ? Colors.white : AppColors.text,
                    height: 1.5)),
            const SizedBox(height: 4),
            Text(
              message.createdAt != null
                  ? '${message.createdAt!.hour.toString().padLeft(2, '0')}:${message.createdAt!.minute.toString().padLeft(2, '0')}'
                  : '',
              style: AppFonts.dmMono(
                  fontSize: 9,
                  color: isMe
                      ? Colors.white.withOpacity(0.6)
                      : AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
