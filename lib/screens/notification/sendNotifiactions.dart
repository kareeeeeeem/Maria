import 'dart:convert';
import 'package:churchapp/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// ⚠️ يجب استيراد الـ ValueNotifier المشترك من ملفه الأصلي
// يجب التأكد من صحة هذا المسار لملف شاشة الإشعارات


class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({super.key});

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  // TODO: Replace with your OneSignal keys
  final String oneSignalAppId = 'a3d9efe8-e736-45fc-98fa-2d4a9d4051c5';
  final String oneSignalApiKey = 'os_v2_app_upm672hhgzc7zgh2fvfj2qcryw5vnlckiksuwov3vicmrhfcuatv2mubwcfypopiy5skw2n5rli3tfwxibdtlcsnv2qmo6kvcc6zdxa';



// AdminNotificationPage.dart (التعديلات في دالة sendNotification)
// AdminNotificationPage.dart (التعديل النهائي في دالة sendNotification)

Future<void> sendNotification() async {
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
                'Authorization': 'Basic $oneSignalApiKey',
            },
            body: jsonEncode({
                "app_id": oneSignalAppId,
                "included_segments": ["All"],
                "headings": {"en": title},
                "contents": {"en": message},
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
                "isRead": false, // تأكيد أن الإشعار الجديد غير مقروء
            };
            
            // 1. إنشاء القائمة المحدثة (إضافة الجديد على رأس القديم الذي يحمل isRead)
            final updatedList = [
                newNotif,
                ...notificationsNotifier.value,
            ];
            
            // 2. تحديث الـ ValueNotifier 
            notificationsNotifier.value = updatedList;
            
            // 3. حفظ التحديث في SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('saved_notifications', jsonEncode(updatedList));
            
            // 4. تحديث عدد الإشعارات غير المقروءة (العد الدقيق)
            int unreadCount = updatedList.where((n) => n['isRead'] == false).length;
            await prefs.setInt('unread_count', unreadCount);

            // 🔥 عرض SnackBar الجديد بتنسيقات أفضل 🔥
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
            // SnackBar للأخطاء
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
            SnackBar(content: Text('خطأ: $e')),
        );
    } finally {
        setState(() => _isSending = false);
    }
}



  @override
  Widget build(BuildContext context) {
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
              onPressed: _isSending ? null : sendNotification,
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SEND", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
