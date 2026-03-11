import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import 'email_service.dart';
import 'push_service.dart';

class MessagingService {
  final _db = FirebaseFirestore.instance;

  String _convId(String equipmentId, String renterId, String ownerId) =>
      '${equipmentId}_${renterId}_$ownerId';

  Future<String> getOrCreateConversation({
    required String equipmentId,
    required String equipmentTitle,
    required String renterId,
    required String renterEmail,
    required String ownerId,
    required String ownerEmail,
  }) async {
    final id = _convId(equipmentId, renterId, ownerId);
    final ref = _db.collection('conversations').doc(id);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'equipmentId': equipmentId,
        'equipmentTitle': equipmentTitle,
        'renterId': renterId,
        'renterEmail': renterEmail,
        'ownerId': ownerId,
        'ownerEmail': ownerEmail,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }
    return id;
  }

  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(ChatMessage.fromFirestore).toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderEmail,
    required String text,
    String? recipientEmail,
    String? recipientId,
    String? equipmentTitle,
  }) async {
    final ref = _db.collection('conversations').doc(conversationId);
    await ref.collection('messages').add({
      'senderId': senderId,
      'senderEmail': senderEmail,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await ref.update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    // Send email + push notification to recipient (non-fatal)
    if (recipientEmail != null && recipientEmail.isNotEmpty && recipientEmail != senderEmail) {
      EmailService().newMessage(
        recipientEmail: recipientEmail,
        senderEmail: senderEmail,
        equipmentTitle: equipmentTitle ?? 'your listing',
        messagePreview: text.length > 200 ? '${text.substring(0, 200)}...' : text,
      );
    }
    if (recipientId != null && recipientId.isNotEmpty) {
      PushService.sendToUser(
        userId: recipientId,
        title: 'New Message',
        body: text.length > 100 ? '${text.substring(0, 100)}...' : text,
        data: {'type': 'new_message', 'conversationId': conversationId},
      );
    }
  }

  Stream<List<Conversation>> getConversations(String userId) {
    return _db
        .collection('conversations')
        .where(Filter.or(
          Filter('renterId', isEqualTo: userId),
          Filter('ownerId', isEqualTo: userId),
        ))
        .snapshots()
        .map((s) => s.docs.map(Conversation.fromFirestore).toList());
  }
}
