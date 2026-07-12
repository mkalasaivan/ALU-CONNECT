import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  loading,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? successMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.successMessage,
    this.isLoading = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  factory AuthState.unknown() => const AuthState(status: AuthStatus.unknown);

  factory AuthState.authenticated(UserModel user) => AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );

  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.loading() => const AuthState(
        status: AuthStatus.loading,
        isLoading: true,
      );

  factory AuthState.error(String message) => AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );

  factory AuthState.success(String message, UserModel? user) => AuthState(
        status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: user,
        successMessage: message,
      );

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    String? successMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, successMessage, isLoading];
}
