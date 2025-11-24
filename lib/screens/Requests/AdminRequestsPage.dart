// lib/screens/admin_requests_page.dart

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// تأكد من استيراد AppColors وكلاس VisitationRequest

class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E); 
  static const Color secondaryGold = Color(0xFFFFF8E1); 
  static const Color backgroundColor = Color(0xFFF5F5F5); 
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color statusPending = Colors.orange;
  static const Color statusContacted = Colors.lightBlue;
  static const Color statusVisited = Colors.green;
    static const Color accentGold = Color(0xFFE6C47A); // ذهبي مطفأ / عتيق

}

class AdminRequestsPage extends StatelessWidget {
    static const String routeName = "/AdminRequestsPage"; 

  const AdminRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('طلبات الافتقاد',        style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold)),       

        backgroundColor: AppColors.primaryBlue,
                         centerTitle: true,
                         


      ),
      // 1. الاستماع للبيانات مباشرة من Firestore
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('visitation_requests')
            .orderBy('timestamp', descending: true) // عرض الأحدث أولاً
            .snapshots(),
        
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد طلبات افتقاد حالياً.'));
          }

          // 2. بناء قائمة الطلبات
          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final requestDoc = requests[index];
              final data = requestDoc.data() as Map<String, dynamic>;
              
              // 3. عرض تفاصيل الطلب
              return RequestCard(
                data: data,
                docId: requestDoc.id,
              );
            },
          );
        },
      ),
    );
  }
}

// ------------------------------------------
// مكون البطاقة (Card)
// ------------------------------------------

class RequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  
  const RequestCard({required this.data, required this.docId, super.key});

  // دالة لتحديث الحالة في Firestore
  void _updateStatus(String newStatus) {
    FirebaseFirestore.instance
        .collection('visitation_requests')
        .doc(docId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الاسم ورقم الهاتف
            Text(
              '${data['name']} | ${data['phone']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 5),

            // العنوان والملاحظة
            Text('العنوان: ${data['address']}'),
            Text('الملاحظة: ${data['note']}'),
            
            const Divider(),

            // 4. ميزة تحديث الحالة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الحالة الحالية: ${data['status']}',
                  style: TextStyle(
                    color: _getStatusColor(data['status']),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // قائمة منسدلة لتغيير الحالة
                DropdownButton<String>(
                  value: data['status'], // القيمة الحالية
                  items: const ['في انتظار', 'تم التواصل', 'تمت الزيارة']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      _updateStatus(newStatus);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'في انتظار':
        return Colors.orange;
      case 'تم التواصل':
        return Colors.lightBlue;
      case 'تمت الزيارة':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}