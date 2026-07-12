import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userProfileSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthState.unknown()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthProfileUpdateRequested>(_onProfileUpdateRequested);
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    // Listen to Firebase Auth state changes
    _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) async {
        if (user != null) {
          // Fetch user profile from Firestore
          try {
            final userProfile = await _authRepository.getCurrentUserProfile();
            add(AuthUserChanged(userProfile));
          } catch (_) {
            add(const AuthUserChanged(null));
          }
        } else {
          add(const AuthUserChanged(null));
        }
      },
    );
  }

  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user != null) {
      // Subscribe to real-time user profile updates
      _userProfileSubscription?.cancel();

      emit(AuthState.authenticated(event.user!));

      // Set up real-time listener after emitting authenticated state
      await emit.forEach<UserModel?>(
        _authRepository.userProfileStream(event.user!.uid),
        onData: (userProfile) {
          if (userProfile != null) {
            return AuthState.authenticated(userProfile);
          }
          return AuthState.unauthenticated();
        },
        onError: (_, __) => state,
      );
    } else {
      emit(AuthState.unauthenticated());
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());
    try {
      final user = await _authRepository.signUpWithEmail(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
        role: event.role,
      );
      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());
    try {
      final user = await _authRepository.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    emit(AuthState.unauthenticated());
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(state.copyWith(
        successMessage: 'Password reset email sent. Check your inbox.',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final updatedUser = await _authRepository.updateUserProfile(event.updatedUser);
      emit(AuthState.authenticated(updatedUser));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _userProfileSubscription?.cancel();
    return super.close();
  }
}
