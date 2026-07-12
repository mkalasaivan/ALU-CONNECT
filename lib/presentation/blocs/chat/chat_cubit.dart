import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/chat_room_model.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/repositories/chat_repository.dart';

// --- State ---
enum ChatStatus { initial, loading, loaded, messagesLoaded, error, success }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatRoomModel> chatRooms;
  final List<ChatMessageModel> messages;
  final ChatRoomModel? activeRoom;
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.chatRooms = const [],
    this.messages = const [],
    this.activeRoom,
    this.errorMessage,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatRoomModel>? chatRooms,
    List<ChatMessageModel>? messages,
    ChatRoomModel? activeRoom,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      chatRooms: chatRooms ?? this.chatRooms,
      messages: messages ?? this.messages,
      activeRoom: activeRoom ?? this.activeRoom,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, chatRooms, messages, activeRoom, errorMessage];
}

// --- Cubit ---
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repository;
  StreamSubscription<List<ChatRoomModel>>? _chatRoomsSubscription;
  StreamSubscription<List<ChatMessageModel>>? _messagesSubscription;

  ChatCubit({required ChatRepository repository})
      : _repository = repository,
        super(const ChatState());

  // Subscribe to chat rooms based on role
  void subscribeToChatRooms(String id, bool isStartup) {
    _chatRoomsSubscription?.cancel();
    emit(state.copyWith(status: ChatStatus.loading));

    final stream = isStartup
        ? _repository.startupChatRoomsStream(id)
        : _repository.studentChatRoomsStream(id);

    _chatRoomsSubscription = stream.listen(
      (rooms) {
        emit(state.copyWith(
          status: ChatStatus.loaded,
          chatRooms: rooms,
        ));
      },
      onError: (e) {
        emit(state.copyWith(
          status: ChatStatus.error,
          errorMessage: e.toString(),
        ));
      },
    );
  }

  // Subscribe to messages in a chat room
  void subscribeToMessages(String roomId) {
    _messagesSubscription?.cancel();
    
    _messagesSubscription = _repository.chatMessagesStream(roomId).listen(
      (messages) {
        emit(state.copyWith(
          status: ChatStatus.messagesLoaded,
          messages: messages,
        ));
      },
      onError: (e) {
        emit(state.copyWith(
          status: ChatStatus.error,
          errorMessage: e.toString(),
        ));
      },
    );
  }

  // Set active room
  void setActiveRoom(ChatRoomModel? room) {
    emit(state.copyWith(activeRoom: room));
    if (room != null) {
      subscribeToMessages(room.id);
    } else {
      _messagesSubscription?.cancel();
    }
  }

  // Get or create chat room
  Future<ChatRoomModel?> getOrCreateChatRoom(ChatRoomModel chatRoom) async {
    try {
      final room = await _repository.getOrCreateChatRoom(chatRoom);
      setActiveRoom(room);
      return room;
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
      ));
      return null;
    }
  }

  // Send message
  Future<void> sendMessage(String roomId, String senderId, String senderName, String content, ChatRoomModel chatRoom) async {
    try {
      final message = ChatMessageModel(
        id: '',
        senderId: senderId,
        senderName: senderName,
        content: content,
        timestamp: DateTime.now(),
      );
      await _repository.sendMessage(roomId, message, chatRoom);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  // Mark room as read
  Future<void> markRoomAsRead(String roomId, String userId) async {
    try {
      await _repository.markAsRead(roomId, userId);
    } catch (e) {
      // Fail silently
    }
  }

  @override
  Future<void> close() {
    _chatRoomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}
