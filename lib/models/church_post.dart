// lib/models/church_post.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ChurchPost {
  final String id;
  final String title;
  final String body;
  final DateTime date;
  final bool isUrgent; 
  final List<String> mediaUrls; // 🆕 الحقل الجديد لروابط الصور/الفيديوهات

  const ChurchPost({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.isUrgent = false,
    this.mediaUrls = const [],
  });

  // مصنع لإنشاء كائن ChurchPost من DocumentSnapshot
  factory ChurchPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    List<String> urls = [];
    if (data?['mediaUrls'] is List) {
      // 🆕 قراءة حقل mediaUrls وضمان أنه قائمة من الـ Strings
      urls = List<String>.from(data!['mediaUrls']);
    }

    return ChurchPost(
      id: doc.id,
      title: data?['title'] ?? 'عنوان مفقود',
      body: data?['body'] ?? 'محتوى مفقود',
      date: (data?['date'] as Timestamp? ?? Timestamp.now()).toDate(), 
      isUrgent: data?['isUrgent'] ?? false,
      mediaUrls: urls,
    );
  }

  // دالة لتحويل الكائن إلى Map لتخزينه في Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'date': Timestamp.fromDate(date),
      'isUrgent': isUrgent,
      'mediaUrls': mediaUrls, // 🆕 حفظ الروابط
    };
  }
}