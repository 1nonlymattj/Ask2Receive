import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

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

  // Handle null case and provide a default value (ThemeMode.system)
  return ThemeMode.values[themeIndex ?? 0]; // Default to index 0 if null
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
    requestNotificationPermissions();
    scheduleDailyNotification();
  }

  Future<void> requestNotificationPermissions() async {
    var status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.notification.request();
    }
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
      // Use default values (e.g., 9 and 0) if savedHour or savedMinute is null
      notificationTime = TimeOfDay(
        hour: savedHour ?? 9, // Default to 9 if savedHour is null
        minute: savedMinute ?? 0, // Default to 0 if savedMinute is null
      );
    });

    scheduleDailyNotification();
  }

  Future<void> saveNotificationTime(TimeOfDay newTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_hour', newTime.hour);
    await prefs.setInt('notification_minute', newTime.minute);
  }

  void initializeNotifications() async {
    tz.initializeTimeZones();

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsIOS,
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void selectDailyAffirmation() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastUpdated = prefs.getString('last_affirmation_date');
    final savedAffirmation = prefs.getString('daily_affirmation');

    if (lastUpdated == "${now.year}-${now.month}-${now.day}" &&
        savedAffirmation != null) {
      setState(() {
        dailyAffirmation = savedAffirmation;
      });
    } else {
      final newAffirmation = affirmations[now.day % affirmations.length];
      setState(() {
        dailyAffirmation = newAffirmation;
      });
      await prefs.setString('daily_affirmation', newAffirmation);
      await prefs.setString(
          'last_affirmation_date', "${now.year}-${now.month}-${now.day}");
    }
  }

  void scheduleDailyNotification() async {
    final prefs = await SharedPreferences.getInstance();
    int savedHour = prefs.getInt('notification_hour') ?? 9;
    int savedMinute = prefs.getInt('notification_minute') ?? 0;
    String savedAffirmation =
        prefs.getString('daily_affirmation') ?? "Stay positive!";

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
              .add(Duration(days: 1)) // Move to next day if time has passed
          : notificationDateTime,
      tz.local,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Daily Affirmation',
      savedAffirmation,
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
      matchDateTimeComponents: DateTimeComponents.time,
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
                    "$userName The Universe is ready to Listen!",
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
