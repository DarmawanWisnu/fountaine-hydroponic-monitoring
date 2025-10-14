// lib/providers/auth/auth_user.dart
class AuthUser {
  final String uid;
  final String? email;
  final bool emailVerified;

  AuthUser({required this.uid, this.email, this.emailVerified = false});

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'emailVerified': emailVerified,
  };

  factory AuthUser.fromMap(Map<String, dynamic> m) => AuthUser(
    uid: m['uid'] as String,
    email: m['email'] as String?,
    emailVerified: m['emailVerified'] as bool? ?? false,
  );
}
