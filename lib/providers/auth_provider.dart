// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});

class User {
  final String name;
  final String email;
  final String password;
  final String location;

  User({
    required this.name,
    required this.email,
    required this.password,
    required this.location,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'location': location,
  };

  static User fromJson(Map<String, dynamic> j) => User(
    name: j['name'],
    email: j['email'],
    password: j['password'],
    location: j['location'],
  );
}

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final data = sp.getString('user');
    if (data != null) {
      final map = jsonDecode(data) as Map<String, dynamic>;
      state = User.fromJson(map);
    }
  }

  /// Simulasi REGISTER — nyimpen data dummy user ke SharedPreferences
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String location,
  }) async {
    final user = User(
      name: name,
      email: email,
      password: password,
      location: location,
    );

    final sp = await SharedPreferences.getInstance();
    await sp.setString('user', jsonEncode(user.toJson()));
    state = user;
  }

  /// Simulasi LOGIN — validasi dari data dummy di SharedPreferences
  Future<void> signIn({required String email, required String password}) async {
    final sp = await SharedPreferences.getInstance();
    final data = sp.getString('user');
    if (data == null) throw Exception('User belum terdaftar');

    final saved = User.fromJson(jsonDecode(data));

    if (saved.email != email || saved.password != password) {
      throw Exception('Email atau password salah');
    }

    state = saved;
  }

  /// LOGOUT — hapus data user dummy
  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('user');
    state = null;
  }
}
