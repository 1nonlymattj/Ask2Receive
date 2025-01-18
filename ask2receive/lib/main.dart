import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'affirmations_list.dart';
import 'widgets/settings_menu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeMode savedThemeMode = await loadThemeMode();
  runApp(AffirmationApp(savedThemeMode: savedThemeMode));
}

Future<ThemeMode> loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  int? themeIndex = prefs.getInt('theme_mode');
  if (themeIndex == null) return ThemeMode.system;
  return ThemeMode.values[themeIndex];
}

class AffirmationApp extends StatefulWidget {
  final ThemeMode savedThemeMode;

  AffirmationApp({required this.savedThemeMode});

  @override
  _AffirmationAppState createState() => _AffirmationAppState();
}

class _AffirmationAppState extends State<AffirmationApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.savedThemeMode;
  }

  void updateTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', themeMode.index);
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ask2Receive',
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: AffirmationScreen(updateTheme: updateTheme),
    );
  }
}

class AffirmationScreen extends StatefulWidget {
  final Function(ThemeMode) updateTheme;

  AffirmationScreen({required this.updateTheme});

  @override
  _AffirmationScreenState createState() => _AffirmationScreenState();
}

class _AffirmationScreenState extends State<AffirmationScreen> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String dailyAffirmation = "Loading...";
  TimeOfDay notificationTime = const TimeOfDay(hour: 9, minute: 0);
  String? userName;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    selectDailyAffirmation();
    loadNotificationTime(); // Load saved notification time
    loadUserName(); // Load saved name
    scheduleDailyNotification();
  }

  Future<void> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name');
    });
  }

  Future<void> loadNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    int? savedHour = prefs.getInt('notification_hour');
    int? savedMinute = prefs.getInt('notification_minute');

    setState(() {
      if (savedHour != null && savedMinute != null) {
        notificationTime = TimeOfDay(hour: savedHour, minute: savedMinute);
      } else {
        notificationTime = TimeOfDay(hour: 9, minute: 0); // Default 9 AM
      }
    });

    scheduleDailyNotification();
  }

  Future<void> saveNotificationTime(TimeOfDay newTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_hour', newTime.hour);
    await prefs.setInt('notification_minute', newTime.minute);
  }

  void initializeNotifications() {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void selectDailyAffirmation() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    setState(() {
      dailyAffirmation = affirmations[now.day % affirmations.length];
    });
    flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Daily Affirmation',
      dailyAffirmation,
      tz.TZDateTime.from(nextMidnight, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_affirmation_channel',
          'Daily Affirmations',
          channelDescription: 'Receive a daily affirmation at midnight.',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void scheduleDailyNotification() async {
    final prefs = await SharedPreferences.getInstance();
    int? savedHour = prefs.getInt('notification_hour');
    int? savedMinute = prefs.getInt('notification_minute');

    if (savedHour == null || savedMinute == null) {
      return; // No saved notification time, exit function
    }

    final now = DateTime.now();
    final notificationDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      savedHour,
      savedMinute,
    );

    final scheduledTime = tz.TZDateTime.from(
      notificationDateTime.isBefore(now)
          ? notificationDateTime
              .add(Duration(days: 1)) // Next day if time has passed
          : notificationDateTime,
      tz.local,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Daily Affirmation',
      dailyAffirmation,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Daily Affirmation Reminder',
          channelDescription: 'Reminds you of your daily affirmation.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Ensures it repeats daily
    );
  }

  void showWriteAffirmationPopup() {
    TextEditingController affirmationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Write Your Own Manifestation"),
          content: TextField(
            controller: affirmationController,
            decoration: InputDecoration(
              hintText: "Enter your manifestation",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (affirmationController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Please fill out before submitting."),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text("The Universe has received your manifestation."),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ask2Receive'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsMenu(
                    updateTheme: widget.updateTheme,
                    initialThemeMode: ThemeMode.system,
                    initialNotificationTime: notificationTime,
                    onNotificationTimeChanged: (newTime) {
                      setState(() {
                        notificationTime = newTime;
                        saveNotificationTime(newTime);
                        scheduleDailyNotification();
                      });
                    },
                    userName: userName,
                    onNameChanged: (newName) {
                      setState(() {
                        userName = newName;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/galaxy_background.png'),
            opacity: .5,
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Today's Affirmation",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                dailyAffirmation,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: showWriteAffirmationPopup,
                child: Text("Write Your Own Manifestation"),
              ),
              if (userName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    "Hello, $userName!",
                    style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
