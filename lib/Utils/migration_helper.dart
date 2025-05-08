import 'package:to_do_app/services/DatabaseService.dart';
import 'package:hive_flutter/hive_flutter.dart';


class MigrationHelper {
  static Future<void> migrateFromHiveToSql() async {
    final dbService = DatabaseService();
    final hiveBox = Hive.box('mybox');

    // Check if migration is needed
    final isMigrated = hiveBox.get('is_migrated_to_sql', defaultValue: false);
    if (isMigrated) return;

    // Migrate user data
    final username = hiveBox.get('USERNAME');
    final email = hiveBox.get('USER_EMAIL');
    final passwordHash = hiveBox.get('USER_PASSWORD');
    final profileImage = hiveBox.get('PROFILE_IMAGE');
    final themeMode = hiveBox.get('THEME_MODE', defaultValue: true);

    if (email != null && passwordHash != null) {
      await dbService.createUser({
        'email': email,
        'password_hash': passwordHash,
        'username': username ?? email.split('@').first,
        'profile_image': profileImage,
        'theme_mode': themeMode ? 1 : 0,
      });
    }

    // Migrate tasks
    final todoList = hiveBox.get('TODOLIST');
    if (todoList != null && todoList is List) {
      for (final task in todoList) {
        if (task is List && task.length >= 4) {
          await dbService.createTask({
            'user_id': 1, // Assuming first user
            'title': task[0],
            'is_completed': task[1] ? 1 : 0,
            'category': task.length > 2 ? task[2] : 'Work',
            'priority': task.length > 3 ? task[3] : 'low',
          });
        }
      }
    }

    // Mark as migrated
    await hiveBox.put('is_migrated_to_sql', true);
  }
}