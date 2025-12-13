import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_screen.dart';


class ConfigScreen extends StatefulWidget {
  final bool isUpdating; // Are we updating existing keys?
  const ConfigScreen({super.key, this.isUpdating = false});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _accessCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  final _sessionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _accessCtrl.text = prefs.getString('access_key') ?? '';
      _secretCtrl.text = prefs.getString('secret_key') ?? '';
      _sessionCtrl.text = prefs.getString('session_token') ?? '';
    });
  }

  Future<void> _saveAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_key', _accessCtrl.text.trim());
    await prefs.setString('secret_key', _secretCtrl.text.trim());
    await prefs.setString('session_token', _sessionCtrl.text.trim());

    if (widget.isUpdating) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AWS Configuration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Paste credentials from AWS Academy Lab Details.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _accessCtrl,
              decoration: const InputDecoration(
                labelText: "AWS Access Key",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _secretCtrl,
              decoration: const InputDecoration(
                labelText: "AWS Secret Key",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _sessionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "AWS Session Token",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Save Keys"),
              ),
            ),
            if (widget.isUpdating)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
          ],
        ),
      ),
    );
  }
}
