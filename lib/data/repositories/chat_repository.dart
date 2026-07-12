import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room_model.dart';
import '../models/chat_message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _chatRooms => _firestore.collection('chat_rooms');

  // Stream of chat rooms for a student (applicant)
  Stream<List<ChatRoomModel>> studentChatRoomsStream(String studentId) {
    return _chatRooms
        .where('applicantId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ChatRoomModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return list;
    });
  }

  // Stream of chat rooms for a startup
  Stream<List<ChatRoomModel>> startupChatRoomsStream(String startupId) {
    return _chatRooms
        .where('startupId', isEqualTo: startupId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ChatRoomModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return list;
    });
  }

  // Get or create a chat room
  Future<ChatRoomModel> getOrCreateChatRoom(ChatRoomModel chatRoom) async {
    final docRef = _chatRooms.doc(chatRoom.id);
    final doc = await docRef.get();
    if (doc.exists) {
      return ChatRoomModel.fromFirestore(doc);
    } else {
      await docRef.set(chatRoom.toFirestore());
      return chatRoom;
    }
  }

  // Stream of messages for a chat room
  Stream<List<ChatMessageModel>> chatMessagesStream(String roomId) {
    return _chatRooms
        .doc(roomId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ChatMessageModel.fromFirestore(doc)).toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp)); // oldest message first in detail view
      return list;
    });
  }

  // Send a message
  Future<void> sendMessage(String roomId, ChatMessageModel message, ChatRoomModel chatRoom) async {
    final batch = _firestore.batch();
    
    // Add message
    final msgRef = _chatRooms.doc(roomId).collection('messages').doc();
    batch.set(msgRef, message.toFirestore());

    // Update last message in chat room
    final roomRef = _chatRooms.doc(roomId);
    
    // Increment unread count for recipient
    final recipientId = (message.senderId == chatRoom.applicantId) 
        ? chatRoom.startupId 
        : chatRoom.applicantId;

    final updatedUnreadCounts = Map<String, int>.from(chatRoom.unreadCounts);
    updatedUnreadCounts[recipientId] = (updatedUnreadCounts[recipientId] ?? 0) + 1;

    batch.update(roomRef, {
      'lastMessage': message.content,
      'lastMessageSenderId': message.senderId,
      'lastMessageTime': Timestamp.fromDate(message.timestamp),
      'unreadCounts': updatedUnreadCounts,
    });

    await batch.commit();
  }

  // Mark all messages as read for a user in a room
  Future<void> markAsRead(String roomId, String userId) async {
    final roomRef = _chatRooms.doc(roomId);
    final doc = await roomRef.get();
    if (!doc.exists) return;

    final chatRoom = ChatRoomModel.fromFirestore(doc);
    final updatedUnreadCounts = Map<String, int>.from(chatRoom.unreadCounts);
    updatedUnreadCounts[userId] = 0;

    await roomRef.update({
      'unreadCounts': updatedUnreadCounts,
    });
  }
}
