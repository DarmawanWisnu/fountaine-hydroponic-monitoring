// lib/providers/auth/auth_exceptions.dart
class UserNotFoundAuthException implements Exception {
  final String message;
  UserNotFoundAuthException([this.message = 'User not found']);
  @override
  String toString() => message;
}

class WrongPasswordAuthException implements Exception {
  final String message;
  WrongPasswordAuthException([this.message = 'Wrong password']);
  @override
  String toString() => message;
}

class WeakPasswordAuthException implements Exception {
  final String message;
  WeakPasswordAuthException([this.message = 'Weak password']);
  @override
  String toString() => message;
}

class EmailAlreadyInUseAuthException implements Exception {
  final String message;
  EmailAlreadyInUseAuthException([this.message = 'Email already in use']);
  @override
  String toString() => message;
}

class InvalidEmailAuthException implements Exception {
  final String message;
  InvalidEmailAuthException([this.message = 'Invalid email']);
  @override
  String toString() => message;
}

class UserNotLoggedInAuthException implements Exception {
  final String message;
  UserNotLoggedInAuthException([this.message = 'User not logged in']);
  @override
  String toString() => message;
}

class GenericAuthException implements Exception {
  final String message;
  GenericAuthException([this.message = 'Authentication error']);
  @override
  String toString() => message;
}
