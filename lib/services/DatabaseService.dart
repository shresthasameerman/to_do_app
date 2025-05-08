import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static FlutterLocalNotificationsPlugin? _notifications;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  FlutterLocalNotificationsPlugin get notifications {
    _notifications ??= FlutterLocalNotificationsPlugin();
    return _notifications!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'taskora.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_key = ON');

    // Users Table
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      username TEXT, 
      profile_image TEXT,
      theme_mode INTEGER DEFAULT 1, --1 FOR DARK, 0 FOR LIGHT
      last_login TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )    
    ''');

    await db.execute('''
     CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        priority TEXT NOT NULL, -- 'low', 'medium', 'high'
        is_completed INTEGER DEFAULT 0, -- 0 for false, 1 for true
        due_date TEXT,
        reminder_time TEXT, -- ISO8601 string for notification scheduling
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    // Notes table
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT,
        images TEXT, -- JSON array of image paths
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    // Study sessions table
    await db.execute('''
      CREATE TABLE study_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        session_type TEXT NOT NULL, -- 'focus', 'short_break', 'long_break'
        duration INTEGER NOT NULL, -- in seconds
        completed_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    // Notifications table
    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        payload TEXT, -- Additional data
        scheduled_time TEXT NOT NULL, -- ISO8601 string
        is_delivered INTEGER DEFAULT 0, -- 0 for pending, 1 for delivered
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    // Create indexes
    await db.execute('CREATE INDEX idx_tasks_user ON tasks(user_id)');
    await db.execute('CREATE INDEX idx_notes_user ON notes(user_id)');
    await db.execute('CREATE INDEX idx_notifications_user ON notifications(user_id)');
    await db.execute('CREATE INDEX idx_notifications_time ON notifications(scheduled_time)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN theme_mode INTEGER DEFAULT 1');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          payload TEXT,
          scheduled_time TEXT NOT NULL,
          is_delivered INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_notifications_user ON notifications(user_id)');
      await db.execute('CREATE INDEX idx_notifications_time ON notifications(scheduled_time)');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<int> createUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUser(int userId, Map<String, dynamic> updates) async {
    final db = await database;
    return await db.update(
      'users',
      updates,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Task Operations
  Future<int> createTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('tasks', task);
  }

  Future<List<Map<String, dynamic>>> getTasks(int userId, {bool? completed}) async {
    final db = await database;
    String where = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (completed != null) {
      where += ' AND is_completed = ?';
      whereArgs.add(completed ? 1 : 0);
    }

    return await db.query(
      'tasks',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'priority DESC, created_at DESC',
    );
  }

  Future<int> updateTask(int taskId, Map<String, dynamic> updates) async {
    final db = await database;
    updates['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'tasks',
      updates,
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<int> deleteTask(int taskId) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // Notification Operations
  Future<int> scheduleNotification(Map<String, dynamic> notification) async {
    final db = await database;
    return await db.insert('notifications', notification);
  }

  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.query(
      'notifications',
      where: 'scheduled_time <= ? AND is_delivered = 0',
      whereArgs: [now],
    );
  }

  Future<int> markNotificationDelivered(int notificationId) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'is_delivered': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  // Study Session Operations
  Future<int> recordStudySession(Map<String, dynamic> session) async {
    final db = await database;
    return await db.insert('study_sessions', session);
  }

  Future<List<Map<String, dynamic>>> getStudySessions(int userId, {int? limit}) async {
    final db = await database;
    return await db.query(
      'study_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'completed_at DESC',
      limit: limit,
    );
  }

  // Initialize notifications
  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
  }

  // Show notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'taskora_channel',
      'Taskora Notifications',
      channelDescription: 'Notifications for Taskora app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await notifications.show(
      0, // Notification ID
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Check and deliver pending notifications
  Future<void> checkPendingNotifications() async {
    final pending = await getPendingNotifications();
    for (final notification in pending) {
      await showNotification(
        title: notification['title'] as String,
        body: notification['body'] as String,
        payload: notification['payload'] as String?,
      );
      await markNotificationDelivered(notification['id'] as int);
    }
  }
}