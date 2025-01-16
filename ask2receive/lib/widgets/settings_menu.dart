import 'package:flutter/material.dart';

class SettingsMenu extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final TimeOfDay initialNotificationTime;
  final Function(TimeOfDay) onNotificationTimeChanged;
  final Function(String) onNameChanged;
  final Function(ThemeMode) updateTheme;
  final String? userName;

  SettingsMenu({
    required this.initialThemeMode,
    required this.initialNotificationTime,
    required this.onNotificationTimeChanged,
    required this.onNameChanged,
    required this.updateTheme,
    this.userName,
  });

  @override
  _SettingsMenuState createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  late ThemeMode selectedThemeMode;
  late TimeOfDay notificationTime;
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedThemeMode = widget.initialThemeMode;
    notificationTime = widget.initialNotificationTime;
    nameController.text = widget.userName ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text("Enter Your Name", style: TextStyle(fontSize: 18)),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: widget.userName == null ? "Enter your name" : "",
              ),
              onSubmitted: (value) {
                widget.onNameChanged(value);
              },
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
                  widget.onNotificationTimeChanged(pickedTime);
                }
              },
              child: Text("Set Notification Time"),
            ),
            Text("Theme", style: TextStyle(fontSize: 18)),
            DropdownButton<ThemeMode>(
              value: selectedThemeMode,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text("Light"),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text("Dark"),
                ),
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text("System"),
                ),
              ],
              onChanged: (newThemeMode) {
                if (newThemeMode != null) {
                  setState(() {
                    selectedThemeMode = newThemeMode;
                  });
                  widget.updateTheme(newThemeMode);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
