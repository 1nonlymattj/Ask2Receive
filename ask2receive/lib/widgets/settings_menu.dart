import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SettingsMenu extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final TimeOfDay initialNotificationTime;
  final Function(TimeOfDay) onNotificationTimeChanged;
  final Function(String) onNameChanged;
  final Function(ThemeMode) updateTheme;
  final Function scheduleNotificationCallback;
  final String? userName;

  SettingsMenu({
    required this.initialThemeMode,
    required this.initialNotificationTime,
    required this.onNotificationTimeChanged,
    required this.onNameChanged,
    required this.updateTheme,
    required this.scheduleNotificationCallback,
    this.userName,
  });

  @override
  _SettingsMenuState createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  late ThemeMode selectedThemeMode;
  late TimeOfDay notificationTime;
  String toCamelCase(String name) {
    return name.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedThemeMode = widget.initialThemeMode;
    notificationTime = widget.initialNotificationTime;
    nameController.text = widget.userName ?? "";
  }

  Future<void> saveUserName() async {
    final prefs = await SharedPreferences.getInstance();

    String formattedName =
        toCamelCase(nameController.text); // Convert to Camel Case

    await prefs.setString('user_name', formattedName);
    widget.onNameChanged(formattedName);

    // Update UI with formatted name
    setState(() {
      nameController.text = formattedName;
    });

    // Confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Name saved successfully!")),
    );
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', themeMode.index);
    widget.updateTheme(themeMode);
  }

  void showAffirmationPopup(BuildContext context) {
    TextEditingController affirmationController = TextEditingController();

    // Google Form Response URL (Direct, without CORS Proxy)
    const String googleFormUrl =
        "https://docs.google.com/forms/d/e/1FAIpQLSeBAeHbCCiLHVW99lstQhEY7iriZgugz2fh1b-pcJtyzmwlZQ/formResponse";

    const String fieldEntryId = "entry.1224885230"; // Field entry ID

    // Google Form Option 2
    // "https://docs.google.com/forms/d/e/1FAIpQLSdBAF9M10kjB_TnaKz3FHNpI2ZO926wxtSIqfXPKpOT6SzDpA/formResponse";
    // "entry.1947812320"; // Field entry ID for the affirmation

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Submit Affirmation"),
          content: TextField(
            controller: affirmationController,
            maxLength: 200,
            decoration: InputDecoration(hintText: "Enter your affirmation"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close popup
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (affirmationController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter an affirmation")),
                  );
                  return;
                }

                try {
                  // Format data for submission
                  String formData =
                      "$fieldEntryId=${Uri.encodeQueryComponent(affirmationController.text)}";

                  var response = await http.post(
                    Uri.parse(googleFormUrl),
                    headers: {
                      "Content-Type": "application/x-www-form-urlencoded",
                    },
                    body: formData, // Send user input
                  );

                  // Google Forms does not return a normal response; we assume success.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text("Your affirmation was submitted successfully!"),
                      duration: Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text("Your affirmation was submitted successfully!"),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }

                Navigator.of(context).pop();
              },
              child: Text("Send"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text("Enter Your Name", style: TextStyle(fontSize: 18)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(hintText: "Enter your name"),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: saveUserName,
                  child: Text("Save"),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text("Notification Time", style: TextStyle(fontSize: 18)),
            ElevatedButton(
              onPressed: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: notificationTime,
                );

                if (pickedTime != null) {
                  setState(() {
                    notificationTime = pickedTime;
                  });

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('notification_hour', pickedTime.hour);
                  await prefs.setInt('notification_minute', pickedTime.minute);

                  widget.onNotificationTimeChanged(pickedTime);
                  widget.scheduleNotificationCallback(); // Reschedule new time

                  // Show confirmation message for 3 seconds
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Notification time has been updated!"),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Text("Set Notification Time"),
            ),
            SizedBox(height: 20),
            Text("Theme", style: TextStyle(fontSize: 18)),
            DropdownButton<ThemeMode>(
              value: selectedThemeMode,
              items: [
                DropdownMenuItem(value: ThemeMode.light, child: Text("Light")),
                DropdownMenuItem(value: ThemeMode.dark, child: Text("Dark")),
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text("System")),
              ],
              onChanged: (newThemeMode) async {
                if (newThemeMode != null) {
                  setState(() {
                    selectedThemeMode = newThemeMode;
                  });
                  await saveThemeMode(newThemeMode);
                }
              },
            ),
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 20),
            // Submit Affirmation Button
            Center(
              child: ElevatedButton(
                onPressed: () => showAffirmationPopup(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text("Submit Affirmation"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


  // void showAffirmationPopup(BuildContext context) {
  //   TextEditingController affirmationController = TextEditingController();

  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text("Submit Affirmation"),
  //         content: TextField(
  //           controller: affirmationController,
  //           maxLength: 200,
  //           decoration: InputDecoration(hintText: "Enter your affirmation"),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop(); // Close popup
  //             },
  //             child: Text("Cancel"),
  //           ),
  //           TextButton(
  //             onPressed: () async {
  //               if (affirmationController.text.isEmpty) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(content: Text("Please enter an affirmation")),
  //                 );
  //                 return;
  //               }

  //               String affirmationText =
  //                   Uri.encodeComponent(affirmationController.text);

  //               // Replace with your Google Form URL & Entry ID
  //               final String googleFormUrl =
  //                   "https://docs.google.com/forms/d/e/1FAIpQLSeBAeHbCCiLHVW99lstQhEY7iriZgugz2fh1b-pcJtyzmwlZQ/viewform?usp=pp_url&entry.1224885230=$affirmationText";
  //               // Replace `entry.1234567890` with your Google Form Entry ID

  //               if (await canLaunchUrl(Uri.parse(googleFormUrl))) {
  //                 await launchUrl(Uri.parse(googleFormUrl),
  //                     mode: LaunchMode.externalApplication);
  //               } else {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(
  //                     content: Text("Could not open Google Form."),
  //                     duration: Duration(seconds: 3),
  //                   ),
  //                 );
  //               }

  //               Navigator.of(context).pop();
  //             },
  //             child: Text("Submit"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }