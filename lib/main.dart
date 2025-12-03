// lib/main.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🆕 إضافة Supabase

import 'package:churchapp/routes.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:churchapp/firebase_options.dart'; 

// =========================================================================
// 🌐 ثوابت Supabase
// =========================================================================
const String SUPABASE_URL ='https://zmvhirhhbavjkdjbyrpl.supabase.co'; 
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptdmhpcmhoYmF2amtkamJ5cnBsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3MjA0NDcsImV4cCI6MjA4MDI5NjQ0N30.axhqAPmfyd-quxOaYemRZIib_Rs95Bf_GZWeMfW5mJQ';
// =========================================================================
// 🔥 ثوابت ومتغيرات OneSignal
// =========================================================================
const OneSignalAppId ='a3d9efe8-e736-45fc-98fa-2d4a9d4051c5';
final notificationsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);


// =========================================================================
// 🔔 دالة تهيئة OneSignal
// =========================================================================
Future<void> _initializeOneSignal() async {
// ... (بقية منطق OneSignal يبقى كما هو)
  if (kIsWeb) {
    print("🔔 OneSignal initialization skipped on Web platform.");
    return;
  }
  
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(OneSignalAppId);
  await OneSignal.Notifications.requestPermission(true);
  OneSignal.User.pushSubscription.optIn();

  final prefs = await SharedPreferences.getInstance(); 
  final String? savedString = prefs.getString('saved_notifications');

  if (savedString != null) {
    try {
      List<dynamic> loadedList = jsonDecode(savedString);
      List<Map<String, dynamic>> finalLoadedList = loadedList.map((notif) {
        if (notif is Map<String, dynamic>) {
          return {
            "title": notif["title"] ?? "No title",
            "body": notif["body"] ?? "No message",
            "time": notif["time"] ?? DateTime.now().toIso8601String(),
            "isRead": (notif.containsKey("isRead") && notif["isRead"] is bool) ? notif["isRead"] : true,
          };
        }
        return null;
      }).where((n) => n != null).cast<Map<String, dynamic>>().toList();
      
      notificationsNotifier.value = finalLoadedList;
      
      await prefs.setInt('unread_count', finalLoadedList.where((n) => n["isRead"] == false).length);
    } catch (e) {
      print("Error loading saved notifications: $e");
    }
  }
  
  OneSignal.Notifications.addForegroundWillDisplayListener((event) async {
    
    final notif = event.notification;
    final newNotif = {
      "title": notif.title ?? "No title",
      "body": notif.body ?? "No message",
      "time": DateTime.now().toIso8601String(),
      "isRead": false,
    };

    final currentNotifications = notificationsNotifier.value; 
    final updatedNotifications = [newNotif, ...currentNotifications];
    notificationsNotifier.value = updatedNotifications; 

    final prefs = await SharedPreferences.getInstance(); 
    await prefs.setString('saved_notifications', jsonEncode(updatedNotifications));
    
    await prefs.setInt('unread_count', updatedNotifications.where((n) => n["isRead"] == false).length);

    event.notification.display();
    print("📩 Notification received and persisted: $newNotif");
  });

  OneSignal.Notifications.addClickListener((event) {
    print("🔔 Notification clicked: ${event.notification.jsonRepresentation()}");
  });

  print("✅✅✅✅✅ OneSignal initialized successfully!");
}

// =========================================================================
// 🏁 الدالة الرئيسية main
// =========================================================================
String initialRoute = '/';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, 
  );
  
  // 🆕 تهيئة Supabase Storage (للتخزين)
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );
  
  await _initializeOneSignal();
  
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? userToken = prefs.getString('user_token');
  
  if (userToken != null && userToken.isNotEmpty) {
    initialRoute = '/HomePage'; 
  } else {
    initialRoute = '/'; 
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق الكنيسة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      routes: routes,
      initialRoute: initialRoute, 
    );
  }
}