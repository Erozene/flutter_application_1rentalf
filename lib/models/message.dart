import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderEmail;
  final String text;
  final DateTime? createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    required this.text,
    this.createdAt,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      senderEmail: d['senderEmail'] ?? '',
      text: d['text'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class Conversation {
  final String id;
  final String equipmentId;
  final String equipmentTitle;
  final String renterId;
  final String renterEmail;
  final String ownerId;
  final String ownerEmail;
  final String lastMessage;
  final DateTime? lastMessageAt;

  Conversation({
    required this.id,
    required this.equipmentId,
    required this.equipmentTitle,
    required this.renterId,
    required this.renterEmail,
    required this.ownerId,
    required this.ownerEmail,
    required this.lastMessage,
    this.lastMessageAt,
  });

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      equipmentId: d['equipmentId'] ?? '',
      equipmentTitle: d['equipmentTitle'] ?? '',
      renterId: d['renterId'] ?? '',
      renterEmail: d['renterEmail'] ?? '',
      ownerId: d['ownerId'] ?? '',
      ownerEmail: d['ownerEmail'] ?? '',
      lastMessage: d['lastMessage'] ?? '',
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }

  String otherPersonEmail(String myUid) =>
      myUid == renterId ? ownerEmail : renterEmail;

  String otherPersonId(String myUid) =>
      myUid == renterId ? ownerId : renterId;
}
