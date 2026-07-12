import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/startup_model.dart';
import '../../../data/repositories/startup_repository.dart';

// --- State ---
enum StartupStatus { initial, loading, loaded, error, success }

class StartupState extends Equatable {
  final StartupStatus status;
  final List<StartupModel> startups;
  final StartupModel? currentUserStartup;
  final String? errorMessage;
  final String? successMessage;

  const StartupState({
    this.status = StartupStatus.initial,
    this.startups = const [],
    this.currentUserStartup,
    this.errorMessage,
    this.successMessage,
  });

  bool get hasStartup => currentUserStartup != null;

  StartupState copyWith({
    StartupStatus? status,
    List<StartupModel>? startups,
    StartupModel? currentUserStartup,
    String? errorMessage,
    String? successMessage,
    bool clearStartup = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return StartupState(
      status: status ?? this.status,
      startups: startups ?? this.startups,
      currentUserStartup:
          clearStartup ? null : (currentUserStartup ?? this.currentUserStartup),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, startups, currentUserStartup, errorMessage, successMessage];
}

// --- Cubit ---
class StartupCubit extends Cubit<StartupState> {
  final StartupRepository _repository;
  StreamSubscription<List<StartupModel>>? _startupsSubscription;
  StreamSubscription<StartupModel?>? _userStartupSubscription;

  StartupCubit({required StartupRepository repository})
      : _repository = repository,
        super(const StartupState());

  void subscribeToVerifiedStartups() {
    _startupsSubscription?.cancel();
    emit(state.copyWith(status: StartupStatus.loading));
    _startupsSubscription = _repository.verifiedStartupsStream().listen(
      (startups) {
        emit(state.copyWith(
          status: StartupStatus.loaded,
          startups: startups,
        ));
      },
      onError: (e) {
        emit(state.copyWith(
          status: StartupStatus.error,
          errorMessage: e.toString(),
        ));
      },
    );
  }

  void subscribeToUserStartup(String ownerId) {
    _userStartupSubscription?.cancel();
    _userStartupSubscription =
        _repository.startupByOwnerStream(ownerId).listen(
      (startup) {
        emit(state.copyWith(currentUserStartup: startup));
      },
    );
  }

  Future<void> createStartup(StartupModel startup) async {
    emit(state.copyWith(status: StartupStatus.loading));
    try {
      final created = await _repository.createStartup(startup);
      emit(state.copyWith(
        status: StartupStatus.success,
        currentUserStartup: created,
        successMessage:
            'Startup profile created! It will be reviewed by ALU admin.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: StartupStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> updateStartup(StartupModel startup) async {
    try {
      final updated = await _repository.updateStartup(startup);
      emit(state.copyWith(
        status: StartupStatus.success,
        currentUserStartup: updated,
        successMessage: 'Startup profile updated successfully!',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<List<StartupModel>> searchStartups(String query) async {
    try {
      return await _repository.searchStartups(query);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      return [];
    }
  }

  Future<void> verifyStartup(String startupId, VerificationStatus status, {String? note}) async {
    try {
      await _repository.updateVerificationStatus(startupId, status, note: note);
      emit(state.copyWith(
        successMessage: 'Startup verification updated to ${status.toString().split('.').last}!',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }

  @override
  Future<void> close() {
    _startupsSubscription?.cancel();
    _userStartupSubscription?.cancel();
    return super.close();
  }
}
