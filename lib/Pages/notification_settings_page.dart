import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_app/Utils/notification_service.dart';

class HiveKeys {
  static const String notificationsEnabled = "NOTIFICATIONS_ENABLED";
  static const String dailyReminderTime = "DAILY_REMINDER_TIME";
  static const String weeklySummaryDay = "WEEKLY_SUMMARY_DAY";
  static const String weeklySummaryTime = "WEEKLY_SUMMARY_TIME";
  static const String taskCompletionNotifications = "TASK_COMPLETION_NOTIFICATIONS";
  static const String highPriorityReminders = "HIGH_PRIORITY_REMINDERS";
  static const String silentHours = "SILENT_HOURS";
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  _NotificationSettingsPageState createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _myBox = Hive.box('mybox');
  final NotificationService _notificationService = NotificationService();

  bool _notificationsEnabled = true;
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 20, minute: 0);
  int _weeklySummaryDay = 1; // 1 = Monday, 7 = Sunday
  TimeOfDay _weeklySummaryTime = const TimeOfDay(hour: 9, minute: 0);
  bool _taskCompletionNotifications = true;
  bool _highPriorityReminders = true;

  // Store start and end hours as separate variables to handle midnight crossover
  double _silentStartHour = 22; // 10 PM
  double _silentEndHour = 7; // 7 AM
  bool _crossesMidnight = true; // Flag to track if the range crosses midnight

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _notificationsEnabled = _myBox.get(HiveKeys.notificationsEnabled, defaultValue: true);

      final savedDailyReminderTime = _myBox.get(HiveKeys.dailyReminderTime);
      if (savedDailyReminderTime != null) {
        final List<String> timeParts = savedDailyReminderTime.split(':');
        _dailyReminderTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }

      _weeklySummaryDay = _myBox.get(HiveKeys.weeklySummaryDay, defaultValue: 1);

      final savedWeeklySummaryTime = _myBox.get(HiveKeys.weeklySummaryTime);
      if (savedWeeklySummaryTime != null) {
        final List<String> timeParts = savedWeeklySummaryTime.split(':');
        _weeklySummaryTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }

      _taskCompletionNotifications = _myBox.get(HiveKeys.taskCompletionNotifications, defaultValue: true);
      _highPriorityReminders = _myBox.get(HiveKeys.highPriorityReminders, defaultValue: true);

      final savedSilentHours = _myBox.get(HiveKeys.silentHours);
      if (savedSilentHours != null) {
        _silentStartHour = savedSilentHours[0].toDouble();
        _silentEndHour = savedSilentHours[1].toDouble();
        _crossesMidnight = _silentStartHour > _silentEndHour;
      }
    });
  }

  void _saveSettings() {
    _myBox.put(HiveKeys.notificationsEnabled, _notificationsEnabled);
    _myBox.put(
      HiveKeys.dailyReminderTime,
      '${_dailyReminderTime.hour}:${_dailyReminderTime.minute}',
    );
    _myBox.put(HiveKeys.weeklySummaryDay, _weeklySummaryDay);
    _myBox.put(
      HiveKeys.weeklySummaryTime,
      '${_weeklySummaryTime.hour}:${_weeklySummaryTime.minute}',
    );
    _myBox.put(HiveKeys.taskCompletionNotifications, _taskCompletionNotifications);
    _myBox.put(HiveKeys.highPriorityReminders, _highPriorityReminders);
    _myBox.put(HiveKeys.silentHours, [_silentStartHour, _silentEndHour]);

    if (_notificationsEnabled) {
      _scheduleNotifications();
    } else {
      _notificationService.cancelAllNotifications();
    }
  }

  Future<void> _scheduleNotifications() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications updated')),
    );
  }

  Future<void> _changeDailyReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dailyReminderTime,
    );

    if (picked != null && picked != _dailyReminderTime) {
      setState(() {
        _dailyReminderTime = picked;
        _saveSettings();
      });
    }
  }

  Future<void> _changeWeeklySummarySettings() async {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    showDialog(
      context: context,
      builder: (context) {
        int selectedDay = _weeklySummaryDay;

        return AlertDialog(
          title: const Text('Select day for weekly summary'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < days.length; i++)
                      RadioListTile<int>(
                        title: Text(days[i]),
                        value: i + 1,
                        groupValue: selectedDay,
                        onChanged: (value) {
                          setState(() {
                            selectedDay = value!;
                          });
                        },
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _weeklySummaryTime,
                );

                if (picked != null) {
                  setState(() {
                    _weeklySummaryDay = selectedDay;
                    _weeklySummaryTime = picked;
                    _saveSettings();
                  });
                }
              },
              child: const Text('Next'),
            ),
          ],
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${tod.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatHour(double hour) {
    final int hourInt = hour.floor();
    final String period = hourInt >= 12 ? 'PM' : 'AM';
    final int formattedHour = hourInt > 12 ? hourInt - 12 : (hourInt == 0 ? 12 : hourInt);
    return '$formattedHour $period';
  }

  // Normalize the range for RangeSlider to ensure start <= end
  RangeValues _getSliderRange() {
    if (_crossesMidnight) {
      // If the range crosses midnight, split it into two parts for display purposes
      // For the slider, we can show it as a continuous range by adjusting the logic
      return RangeValues(0, 24); // Placeholder for visualization, we'll handle the logic separately
    } else {
      return RangeValues(_silentStartHour, _silentEndHour);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SwitchListTile(
                      title: const Text(
                        'Enable Notifications',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Turn on/off all notifications'),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                          _saveSettings();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Task Reminders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Daily Reminder'),
                        subtitle: Text(
                          'Get reminded of incomplete tasks at ${_formatTimeOfDay(_dailyReminderTime)}',
                        ),
                        trailing: Icon(Icons.access_time, color: _notificationsEnabled ? null : Colors.grey),
                        onTap: _notificationsEnabled ? _changeDailyReminderTime : null,
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Weekly Summary'),
                        subtitle: Text(
                          'Every ${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][_weeklySummaryDay - 1]} at ${_formatTimeOfDay(_weeklySummaryTime)}',
                        ),
                        trailing: Icon(Icons.calendar_today, color: _notificationsEnabled ? null : Colors.grey),
                        onTap: _notificationsEnabled ? _changeWeeklySummarySettings : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Notification Types',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Task Completion Notifications'),
                        subtitle: const Text('Get notified when you complete a task'),
                        value: _taskCompletionNotifications && _notificationsEnabled,
                        onChanged: _notificationsEnabled
                            ? (value) {
                          setState(() {
                            _taskCompletionNotifications = value;
                            _saveSettings();
                          });
                        }
                            : null,
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('High Priority Task Reminders'),
                        subtitle: const Text('Extra reminders for high priority tasks'),
                        value: _highPriorityReminders && _notificationsEnabled,
                        onChanged: _notificationsEnabled
                            ? (value) {
                          setState(() {
                            _highPriorityReminders = value;
                            _saveSettings();
                          });
                        }
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quiet Hours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No notifications during:',
                          style: TextStyle(
                            color: _notificationsEnabled ? null : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatHour(_silentStartHour),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _notificationsEnabled ? null : Colors.grey,
                              ),
                            ),
                            Text(
                              _formatHour(_silentEndHour),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _notificationsEnabled ? null : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: _crossesMidnight
                              ? RangeValues(_silentEndHour, _silentStartHour)
                              : RangeValues(_silentStartHour, _silentEndHour),
                          min: 0,
                          max: 24,
                          divisions: 24,
                          labels: RangeLabels(
                            _formatHour(_silentStartHour),
                            _formatHour(_silentEndHour),
                          ),
                          onChanged: _notificationsEnabled
                              ? (RangeValues values) {
                            setState(() {
                              if (_crossesMidnight) {
                                _silentEndHour = values.start;
                                _silentStartHour = values.end;
                              } else {
                                _silentStartHour = values.start;
                                _silentEndHour = values.end;
                              }
                              _crossesMidnight = _silentStartHour > _silentEndHour;
                              _saveSettings();
                            });
                          }
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Notifications will be silenced during these hours${_crossesMidnight ? " (across midnight)" : ""}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_notificationsEnabled)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _notificationService.cancelAllNotifications();
                      _scheduleNotifications();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All notifications reset')),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset All Notifications'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}