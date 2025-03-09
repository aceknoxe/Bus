part of 'auth_bloc.dart';

@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.checkRequested() = AuthCheckRequested;
  const factory AuthEvent.signInRequested(String email, String password) = SignInRequested;
  const factory AuthEvent.signUpRequested(String email, String password, String name) = SignUpRequested;
  const factory AuthEvent.signOutRequested() = SignOutRequested;
}