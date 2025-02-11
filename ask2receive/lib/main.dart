import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert'; // ✅ Add this to fix the error
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:timezone/standalone.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

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
    print("✅ initState() called, attempting to schedule notification...");
    scheduleDailyNotification();
  }

  Future<void> requestNotificationPermissions() async {
    if (kIsWeb) {
      print("🛑 Notifications are not supported on web.");
      return;
    }

    var status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.notification.request();
    }

    // Request exact alarm permission ONLY on Android (not web/iOS)
    if (Platform.isAndroid) {
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
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

  Future<void> initializeNotifications() async {
    tzdata.initializeTimeZones();

    String? userTimezone = await getUserTimeZone();
    if (userTimezone != null) {
      tz.setLocalLocation(tz.getLocation(userTimezone));
      print("🌍 Timezone set to: $userTimezone");
    } else {
      tz.setLocalLocation(
          tz.getLocation('America/Chicago')); // Default fallback
      print("⚠️ Using default timezone: America/Chicago");
    }

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
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

  Future<void> scheduleDailyNotification(
      {bool updateUserReminderOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();
    tzdata.initializeTimeZones();

    // 🔍 Get user timezone
    String? userTimezone = await getUserTimeZone();
    if (userTimezone != null) {
      tz.setLocalLocation(tz.getLocation(userTimezone));
      print("🌍 Timezone set to: $userTimezone");
    } else {
      tz.setLocalLocation(
          tz.getLocation('America/Chicago')); // Default fallback
      print("⚠️ Using default timezone: America/Chicago");
    }

    final now = tz.TZDateTime.now(tz.local);

    // 📅 9 AM Daily Affirmation Notification (Only schedule if it's not updateUserReminderOnly)
    if (!updateUserReminderOnly) {
      final tz.TZDateTime dailyAffirmationTime =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        1,
        "Daily Affirmation",
        "Your Daily Affirmation has arrived!",
        dailyAffirmationTime.isBefore(now)
            ? dailyAffirmationTime
                .add(Duration(days: 1)) // Ensure it's in the future
            : dailyAffirmationTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_affirmation_channel',
            'Daily Affirmation',
            channelDescription: 'Sends a daily affirmation at 9 AM',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print("📅 Scheduled Daily Affirmation at: $dailyAffirmationTime");
    }

    // 📅 User-Specified Visualization Reminder
    int savedHour = prefs.getInt('notification_hour') ?? 18; // Default: 6 PM
    int savedMinute = prefs.getInt('notification_minute') ?? 0;

    final tz.TZDateTime visualizationReminderTime = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, savedHour, savedMinute);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      2,
      "Visualization Reminder",
      "Time to visualize your affirmation",
      visualizationReminderTime.isBefore(now)
          ? visualizationReminderTime.add(Duration(days: 1))
          : visualizationReminderTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'visualization_channel',
          'Visualization Reminder',
          channelDescription: 'Reminds you to visualize your affirmation',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    print("📅 Scheduled Visualization Reminder at: $visualizationReminderTime");
  }

  Future<String?> getUserTimeZone() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 🛰️ Check if GPS is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("❌ Location services are disabled.");
      return null;
    }

    // 📍 Check for location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("❌ Location permissions denied.");
        return null;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    double latitude = position.latitude;
    double longitude = position.longitude;
    print("📍 User Location: $latitude, $longitude");

    // 🌍 Fetch timezone from API
    final url = Uri.parse(
        "http://api.timezonedb.com/v2.1/get-time-zone?key=YOUR_API_KEY&format=json&by=position&lat=$latitude&lng=$longitude");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("🕒 Timezone found: ${data['zoneName']}");
        return data['zoneName']; // Example: "America/New_York"
      } else {
        print("❌ Timezone API Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Failed to fetch timezone: $e");
      return null;
    }
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
                        scheduleDailyNotification(
                            updateUserReminderOnly:
                                true); // ✅ Only update user reminder
                      });
                    },
                    scheduleNotificationCallback:
                        scheduleDailyNotification, // ✅ Pass the function
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
