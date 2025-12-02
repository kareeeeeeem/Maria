import 'dart:convert';
import 'package:churchapp/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. استيراد Firestore
import 'package:firebase_core/firebase_core.dart'; // 2. استيراد Firebase Core

// ملاحظة: notificationsNotifier تم استيراده من main.dart

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({super.key});

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  String? _oneSignalApiKey; // ⚠️ سيتم تخزين المفتاح هنا بعد جلبه
  bool _isLoadingKey = true;
  bool _isSending = false;

  // معرف التطبيق العام (لا يتغير، يبقى ثابتاً)
  final String oneSignalAppId = 'a3d9efe8-e736-45fc-98fa-2d4a9d4051c5';

  @override
  void initState() {
    super.initState();
    _fetchApiKey();
  }

  // 3. دالة جلب المفتاح من Firestore
  Future<void> _fetchApiKey() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('app_config') // اسم المجموعة
          .doc('onesignal_api_keys'); // اسم المستند

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        setState(() {
          _oneSignalApiKey = data['restApiKey'] as String?;
          _isLoadingKey = false;
        });
        print("✅ OneSignal API Key loaded from Firestore successfully.");
      } else {
        setState(() {
          _oneSignalApiKey = null;
          _isLoadingKey = false;
        });
        print("❌ Firestore document 'onesignal_api_keys' not found or is empty.");
      }
    } catch (e) {
      print("❌ Error fetching API key from Firestore: $e");
      setState(() {
        _oneSignalApiKey = null;
        _isLoadingKey = false;
      });
      // عرض خطأ للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text('❌ Failed to load API Key. Check internet/Firestore setup.'),
        ),
      );
    }
  }

  // 4. تعديل دالة الإرسال لاستخدام المفتاح المخزن
  Future<void> sendNotification() async {
    if (_oneSignalApiKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API Key is missing. Please set it up in Firestore.')),
      );
      return;
    }

    final String title = _titleController.text.trim();
    final String message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      print("⚠️ Title or Message is empty");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final url = Uri.parse('https://onesignal.com/api/v1/notifications');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_oneSignalApiKey', // 5. استخدام المفتاح المخزن
        },
        body: jsonEncode({
          "app_id": oneSignalAppId,
          "included_segments": ["All"],
          "headings": {"en": title},
          "contents": {"en": message},
          "android_large_icon": "launcher_icon",
        }),
      );

      print("📤 Sending notification...");
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final newNotif = {
          "title": title,
          "body": message,
          "time": DateTime.now().toIso8601String(),
          "isRead": false,
        };

        // تحديث القائمة والحفظ في SharedPreferences
        final updatedList = [newNotif, ...notificationsNotifier.value];
        notificationsNotifier.value = updatedList;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_notifications', jsonEncode(updatedList));

        int unreadCount = updatedList.where((n) => n['isRead'] == false).length;
        await prefs.setInt('unread_count', unreadCount);

        // عرض SnackBar للنجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1F1F39),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Text(
              '✅ Successful',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            action: SnackBarAction(
              label: 'Close',
              textColor: const Color(0xFF00C4CC),
              onPressed: () {},
            ),
          ),
        );

        _titleController.clear();
        _messageController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('❌ Failed: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الإرسال: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 6. التحقق من حالة التحميل والمفتاح
    final bool isReady = !_isLoadingKey && _oneSignalApiKey != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text("Send Notification", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Send Push Notification to All Users",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _titleController,
              enabled: isReady,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Title",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              enabled: isReady,
              style: const TextStyle(color: Colors.white),
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Message",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              // 7. زر الإرسال معطل حتى يتم تحميل المفتاح
              onPressed: (isReady && !_isSending) ? sendNotification : null,
              child: _isLoadingKey
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isReady ? "SEND" : "API Key Missing!", 
                      style: const TextStyle(fontSize: 18, color: Colors.white)
                    ),
            ),
          ],
        ),
      ),
    );
  }
}