import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  final UserRole role;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.displayName,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, displayName, role];
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthUserChanged extends AuthEvent {
  final UserModel? user;

  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthProfileUpdateRequested extends AuthEvent {
  final UserModel updatedUser;

  const AuthProfileUpdateRequested(this.updatedUser);

  @override
  List<Object?> get props => [updatedUser];
}
