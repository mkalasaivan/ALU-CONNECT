import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _notifications => _firestore.collection('notifications');

  // Stream of notifications for a user
  Stream<List<NotificationModel>> userNotificationsStream(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // newest first
      return list;
    });
  }

  // Send/create a notification
  Future<void> sendNotification(NotificationModel notification) async {
    await _notifications.add(notification.toFirestore());
  }

  // Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
        
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
