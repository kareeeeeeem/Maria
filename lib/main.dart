import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'package:churchapp/routes.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:churchapp/firebase_options.dart'; 

// =========================================================================
// 🔥 ثوابت ومتغيرات OneSignal
// =========================================================================
const OneSignalAppId ='a3d9efe8-e736-45fc-98fa-2d4a9d4051c5';
final notificationsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);


// =========================================================================
// 🔔 دالة تهيئة OneSignal (تم تحديثها)
// =========================================================================
Future<void> _initializeOneSignal() async {
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

  // 1. تحميل الإشعارات المحفوظة من SharedPreferences (عند بداية التطبيق)
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
  
  // 2. معالج استقبال الإشعار أثناء عمل التطبيق (Foreground) - الجزء المُعدَّل
  OneSignal.Notifications.addForegroundWillDisplayListener((event) async {
    
    final notif = event.notification;
    final newNotif = {
      "title": notif.title ?? "No title",
      "body": notif.body ?? "No message",
      "time": DateTime.now().toIso8601String(),
      "isRead": false, // الإشعار الجديد دائماً غير مقروء
    };

    // 🔥 التعديل: نعتمد مباشرة على القيمة الحالية في الذاكرة (notificationsNotifier.value) 
    // لضمان أننا نستخدم حالة القراءة/الحذف التي تمت للتو في NotificationsPage
    final currentNotifications = notificationsNotifier.value; 
    
    // إضافة الإشعار الجديد إلى بداية القائمة الحالية
    final updatedNotifications = [newNotif, ...currentNotifications];
    
    // تحديث الـ ValueNotifier في الذاكرة (سيحدث الـ UI)
    notificationsNotifier.value = updatedNotifications; 

    // ✅ الآن نقوم بالحفظ باستخدام نسخة prefs حديثة
    final prefs = await SharedPreferences.getInstance(); 
    await prefs.setString('saved_notifications', jsonEncode(updatedNotifications));
    
    // تحديث عداد الإشعارات غير المقروءة
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