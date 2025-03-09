import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? name;
  final DateTime? lastLogin;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.lastLogin,
  });

  @override
  List<Object?> get props => [id, email, name, lastLogin];

  User copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}