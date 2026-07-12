import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final String startupId;
  final String startupOwnerId; // New field to directly notify the founder
  final String startupName;
  final String? startupLogoUrl;
  final String applicantId;
  final String applicantName;
  final String? applicantPhotoUrl;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts; // userId -> count

  const ChatRoomModel({
    required this.id,
    required this.startupId,
    required this.startupOwnerId,
    required this.startupName,
    this.startupLogoUrl,
    required this.applicantId,
    required this.applicantName,
    this.applicantPhotoUrl,
    this.lastMessage = '',
    this.lastMessageSenderId = '',
    required this.lastMessageTime,
    this.unreadCounts = const {},
  });

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      id: doc.id,
      startupId: data['startupId'] ?? '',
      startupOwnerId: data['startupOwnerId'] ?? '',
      startupName: data['startupName'] ?? '',
      startupLogoUrl: data['startupLogoUrl'],
      applicantId: data['applicantId'] ?? '',
      applicantName: data['applicantName'] ?? '',
      applicantPhotoUrl: data['applicantPhotoUrl'],
      lastMessage: data['lastMessage'] ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'startupId': startupId,
      'startupOwnerId': startupOwnerId,
      'startupName': startupName,
      'startupLogoUrl': startupLogoUrl,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantPhotoUrl': applicantPhotoUrl,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCounts': unreadCounts,
    };
  }

  ChatRoomModel copyWith({
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCounts,
  }) {
    return ChatRoomModel(
      id: id,
      startupId: startupId,
      startupOwnerId: startupOwnerId,
      startupName: startupName,
      startupLogoUrl: startupLogoUrl,
      applicantId: applicantId,
      applicantName: applicantName,
      applicantPhotoUrl: applicantPhotoUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }
}
