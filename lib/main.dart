// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// import 'auth_screen.dart';
//
// void main(){
//   runApp(EduStreamApp());
// }
//
// class EduStreamApp extends StatelessWidget {
//   const EduStreamApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'EduStream Pro',
//       theme: ThemeData(
//         useMaterial3:  true,
//         scaffoldBackgroundColor: const Color(0xFFF3F4F6), // Soft Grey Background
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF6366F1), // "Indigo" Primary
//           primary: const Color(0xFF6366F1),
//           secondary: const Color(0xFFEC4899), // "Pink" Accent
//           surface: Colors.white,
//         ),
//         textTheme: GoogleFonts.poppinsTextTheme(),
//         inputDecorationTheme: InputDecorationTheme(
//           filled: true,
//           fillColor: Colors.grey[100],
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(15),
//             borderSide: BorderSide.none,
//           ),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             elevation: 0,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//             backgroundColor: const Color(0xFF6366F1),
//             foregroundColor: Colors.white,
//           ),
//         ),
//       ),
//       home: const AuthScreen(),
//     );
//   }
// }
//

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb check
import 'auth_screen.dart';

// --- Background Handler (Android Only) ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Platform Check: Only initialize Firebase if NOT on Web
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      // Register Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      print("✅ Firebase initialized for Mobile.");
    } catch (e) {
      print("❌ Firebase Init Error: $e");
    }
  } else {
    print("ℹ️ Connect via Web: Firebase Notifications disabled for Web.");
  }

  runApp(const EduStreamApp());
}

class EduStreamApp extends StatefulWidget {
  const EduStreamApp({super.key});

  @override
  State<EduStreamApp> createState() => _EduStreamAppState();
}

class _EduStreamAppState extends State<EduStreamApp> {

  @override
  void initState() {
    super.initState();
    // Only run setup if NOT on Web
    if (!kIsWeb) {
      _setupPushNotifications();
    }
  }

  Future<void> _setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;

    // A. Request Permissions (Android 13+)
    NotificationSettings settings = await fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission');

      // B. Subscribe to Topic (Directly supported on Android)
      await fcm.subscribeToTopic('all_students');
      print('✅ Android: Subscribed to all_students topic');
    }

    // C. Foreground Listeners
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('⚡ Foreground Message: ${message.notification?.title}');
      if (message.notification != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${message.notification!.title}: ${message.notification!.body}"),
            backgroundColor: const Color(0xFF6366F1),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduStream Pro',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFFEC4899),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}