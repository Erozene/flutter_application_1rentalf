import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/messaging_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  final String currentUserId;
  final String currentUserEmail;

  const ConversationsScreen({
    required this.currentUserId,
    required this.currentUserEmail,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final svc = MessagingService();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.bg,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border)),
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: svc.getConversations(currentUserId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.orange, strokeWidth: 2));
          }
          final convs = snap.data ?? [];
          if (convs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 16),
                  Text('No messages yet',
                      style: AppFonts.dmMono(
                          fontSize: 14, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Text('Message an owner from an equipment listing',
                      style: AppFonts.dmMono(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: convs.length,
            separatorBuilder: (_, __) => const AppDivider(),
            itemBuilder: (_, i) {
              final c = convs[i];
              final other = c.otherPersonEmail(currentUserId);
              final otherId = c.otherPersonId(currentUserId);
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppColors.surface),
                  child: Center(
                    child: Text(
                      other.substring(0, 1).toUpperCase(),
                      style: AppFonts.bebasNeue(
                          fontSize: 20, color: AppColors.orange),
                    ),
                  ),
                ),
                title: Text(other,
                    style: AppFonts.dmMono(
                        fontSize: 13, weight: FontWeight.w500)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(c.equipmentTitle,
                        style: AppFonts.dmMono(
                            fontSize: 10,
                            color: AppColors.orange,
                            letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text(
                      c.lastMessage.isEmpty ? 'No messages yet' : c.lastMessage,
                      style: AppFonts.dmMono(
                          fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textMuted, size: 18),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversationId: c.id,
                      currentUserId: currentUserId,
                      currentUserEmail: currentUserEmail,
                      otherPersonEmail: other,
                      otherPersonId: otherId,
                      equipmentTitle: c.equipmentTitle,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
