// repositories/auth_repository.dart
import 'package:to_do_app/services/DatabaseService.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<int> registerUser({
    required String email,
    required String password,
    String? username,
  }) async {
    // Hash password
    final passwordHash = _hashPassword(password);

    final user = {
      'email': email,
      'password_hash': passwordHash,
      'username': username ?? email.split('@').first,
    };

    return await _dbService.createUser(user);
  }

  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    final passwordHash = _hashPassword(password);
    final user = await _dbService.getUserByEmail(email);

    if (user != null && user['password_hash'] == passwordHash) {
      // Update last login time
      await _dbService.updateUser(user['id'], {
        'last_login': DateTime.now().toIso8601String(),
      });
      return user;
    }

    return null;
  }

  Future<bool> updateUserProfile({
    required int userId,
    String? username,
    String? profileImagePath,
    bool? darkMode,
  }) async {
    final updates = <String, dynamic>{};

    if (username != null) updates['username'] = username;
    if (profileImagePath != null) updates['profile_image'] = profileImagePath;
    if (darkMode != null) updates['theme_mode'] = darkMode ? 1 : 0;

    if (updates.isEmpty) return false;

    final rowsAffected = await _dbService.updateUser(userId, updates);
    return rowsAffected > 0;
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}