import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

// --- State ---
class NotificationState extends Equatable {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? errorMessage;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? errorMessage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount, errorMessage];
}

// --- Cubit ---
class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;
  StreamSubscription<List<NotificationModel>>? _subscription;

  NotificationCubit({required NotificationRepository repository})
      : _repository = repository,
        super(const NotificationState());

  // Subscribe to user notifications
  void subscribeToNotifications(String userId) {
    _subscription?.cancel();
    _subscription = _repository.userNotificationsStream(userId).listen(
      (notifications) {
        final unread = notifications.where((n) => !n.isRead).length;
        emit(NotificationState(
          notifications: notifications,
          unreadCount: unread,
        ));
      },
      onError: (e) {
        emit(state.copyWith(errorMessage: e.toString()));
      },
    );
  }

  // Trigger/Send a new notification
  Future<void> triggerNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic> extraData = const {},
  }) async {
    try {
      final notif = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
        extraData: extraData,
      );
      await _repository.sendNotification(notif);
    } catch (e) {
      // Fail silently
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
    } catch (e) {
      // Fail silently
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _repository.markAllAsRead(userId);
    } catch (e) {
      // Fail silently
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
