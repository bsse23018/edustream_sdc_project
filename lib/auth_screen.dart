import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'aws_config.dart';
import 'prof_dashboard.dart';
import 'stud_dashboard.dart';
import 'config_screen.dart';

@Preview(name: "AuthScreen Preview", group: 'Screens')
Widget authScreenPreview() => MaterialApp(home: const AuthScreen());

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  String selectedRole = 'student';
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  Future<void> _submit() async {
    setState(() => isLoading = true);
    final Map<String, dynamic> payload = {
      'action': isLogin ? 'login' : 'signup',
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text.trim(),
    };
    if (!isLogin) {
      payload['name'] = _nameCtrl.text.trim();
      payload['role'] = selectedRole;
    }

    try {
      final response = await http.post(
        Uri.parse(API_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (isLogin) {
          if (data['role'] == 'professor') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfDashboard(email: _emailCtrl.text, name: data['name'])));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StudDashboard(email: _emailCtrl.text, name: data['name'])));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Success'), backgroundColor: Colors.green));
          setState(() => isLogin = true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Configuration Gear
          Positioned(
            top: 50, right: 20,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white54),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfigScreen(isUpdating: true))),
            ),
          ),
          // Main Card
          Center(
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("EduStream", style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF6366F1))),
                      const SizedBox(height: 5),
                      Text(isLogin ? "Welcome Back" : "Start Learning", style: TextStyle(color: Colors.grey[500])),
                      const SizedBox(height: 30),
                          
                      // Toggle Switch
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Expanded(child: _toggleButton("Login", isLogin)),
                            Expanded(child: _toggleButton("Register", !isLogin)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                          
                      // Inputs
                      if (!isLogin) ...[
                        TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: "Full Name", prefixIcon: Icon(Icons.person_outline))),
                        const SizedBox(height: 10),
                        DropdownButtonFormField(
                          value: selectedRole,
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined)),
                          items: const [
                            DropdownMenuItem(value: 'student', child: Text("Student")),
                            DropdownMenuItem(value: 'professor', child: Text("Professor")),
                          ],
                          onChanged: (v) => setState(() => selectedRole = v as String),
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextField(controller: _emailCtrl, decoration: const InputDecoration(hintText: "Email", prefixIcon: Icon(Icons.email_outlined))),
                      const SizedBox(height: 10),
                      TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(hintText: "Password", prefixIcon: Icon(Icons.lock_outline))),
                          
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isLogin ? "LOG IN" : "SIGN UP"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String title, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => isLogin = (title == "Login")),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
        ),
        child: Center(
          child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey)),
        ),
      ),
    );
  }
}