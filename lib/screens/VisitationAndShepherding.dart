// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:churchapp/aus/signup/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' show DateFormat;

// استيراد النموذج والألوان من ملف الإدخال
// =========================================================================
// 1. Visitation Log Model
// =========================================================================

class VisitationLog {
  final String visitorName;
  final DateTime visitDate;
  final String notes;

  VisitationLog({
    required this.visitorName,
    required this.visitDate,
    required this.notes,
  });

  factory VisitationLog.fromFirestore(Map<String, dynamic> data) {
    return VisitationLog(
      visitorName: data['visitorName'] ?? 'غير معروف',
      visitDate: (data['visitDate'] as Timestamp).toDate(),
      notes: data['notes'] ?? 'لا توجد ملاحظات',
    );
  }
}

// =========================================================================
// 2. Visitation Screen
// =========================================================================

class VisitationScreen extends StatefulWidget {
  static const String routeName = '/visitation';
  const VisitationScreen({super.key});

  @override
  _VisitationScreenState createState() => _VisitationScreenState();
}

class _VisitationScreenState extends State<VisitationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  // دالة تصنيف الأشخاص حسب الحي/المنطقة
  Map<String, List<QueryDocumentSnapshot>> _groupPeopleByNeighborhood(
      List<QueryDocumentSnapshot> people) {
    final Map<String, List<QueryDocumentSnapshot>> groupedData = {};

    for (var doc in people) {
      final neighborhood = doc['neighborhood'] as String? ?? 'عنوان غير محدد';
      if (!groupedData.containsKey(neighborhood)) {
        groupedData[neighborhood] = [];
      }
      groupedData[neighborhood]!.add(doc);
    }

    // فرز الأحياء أبجدياً
    final sortedKeys = groupedData.keys.toList()..sort();
    return Map.fromEntries(sortedKeys.map((key) => MapEntry(key, groupedData[key]!)));
  }
  
  // دالة الفلترة الإضافية
  List<QueryDocumentSnapshot> _filterPeople(List<QueryDocumentSnapshot> people) {
    List<QueryDocumentSnapshot> filteredList = people;
    
    // 1. فلترة حسب البحث
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((doc) {
        final name = (doc['fullName'] as String? ?? '').toLowerCase();
        final address = (doc['streetAddress'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || address.contains(query);
      }).toList();
    }
    
    // 2. فلترة حسب تاريخ آخر افتقاد
    if (_selectedFilter == 'needs_visit') {
      final now = DateTime.now();
      filteredList = filteredList.where((doc) {
        final lastVisited = (doc['lastVisited'] as Timestamp?)?.toDate();
        // يعتبر محتاج لزيارة إذا لم يتم افتقاده أبداً أو مر أكثر من 3 أشهر
        if (lastVisited == null) return true;
        return now.difference(lastVisited).inDays > 90;
      }).toList();
    }
    
    return filteredList;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Color(0xFF4E342E),
      appBar: AppBar(
        title:  const Text(' بيانات الشعب ', style: TextStyle(color: AppColors.accentColor)),
      backgroundColor:Color(0xFF4E342E),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.accentColor),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // شريط البحث والفلترة
          _buildSearchAndFilterBar(),
          
          // StreamBuilder للاستماع لتحديثات قاعدة البيانات في الوقت الحقيقي
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').where('isDataComplete', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accentColor));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ في جلب البيانات: ${snapshot.error}', style: const TextStyle(color: AppColors.redColor)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('لا يوجد شعب مكتمل البيانات بعد.',
                          style: TextStyle(color: AppColors.whiteColor)));
                }

                // 1. تطبيق الفلترة (البحث وآخر زيارة)
                final filteredPeople = _filterPeople(snapshot.data!.docs);
                
                if (filteredPeople.isEmpty) {
                   return const Center(
                      child: Text('لا توجد نتائج مطابقة لمرشحات البحث.',
                          style: TextStyle(color: AppColors.accentColor)));
                }

                // 2. تجميع حسب الحي
                final groupedPeople = _groupPeopleByNeighborhood(filteredPeople);

                // 3. عرض القائمة المصنفة
                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: groupedPeople.keys.length,
                  itemBuilder: (context, index) {
                    final neighborhood = groupedPeople.keys.elementAt(index);
                    final peopleInNeighborhood = groupedPeople[neighborhood]!;

                    return Card(
                      color: Color(0xFF4E342E).withOpacity(0.9),
                      elevation: 5,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(color: AppColors.accentColor, width: 1),
                      ),
                      child: ExpansionTile(
                        collapsedIconColor: AppColors.accentColor,
                        iconColor: AppColors.accentColor,
                        title: Text(
                          '$neighborhood (${peopleInNeighborhood.length} فرد)',
                          style: const TextStyle(
                              color: AppColors.whiteColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        children: peopleInNeighborhood.map((doc) {
                          return _buildPersonTile(context, doc);
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // شريط البحث والفلترة
  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'البحث بالاسم أو العنوان...',
              hintStyle: TextStyle(color: AppColors.whiteColor.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: AppColors.accentColor),
              filled: true,
              fillColor:      Color(0xFF4E342E)
.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: AppColors.accentColor, width: 1.5),
              ),
            ),
            style: const TextStyle(color: AppColors.whiteColor),
          ),
          const SizedBox(height: 30),
          DropdownButtonFormField<String>(
            value: _selectedFilter,
            dropdownColor:      Color(0xFF4E342E)
,
            decoration: InputDecoration(
              labelText: 'مرشح الافتقاد',
              labelStyle: const TextStyle(color: AppColors.accentColor),
              filled: true,
              fillColor:      Color(0xFF4E342E).withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('عرض الكل', style: TextStyle(color: AppColors.whiteColor))),
              DropdownMenuItem(value: 'needs_visit', child: Text('لم يُفتقد منذ 3 أشهر+', style: TextStyle(color: AppColors.redColor, fontWeight: FontWeight.bold))),
            ],
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
              });
            },
            style: const TextStyle(color: AppColors.whiteColor),
          ),
        ],
      ),
    );
  }
  
  // Widget لعرض بيانات كل شخص
  Widget _buildPersonTile(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String name = data['fullName'] ?? 'اسم مجهول';
    final String address = data['streetAddress'] ?? 'عنوان غير متوفر';
    final String phone = data['phoneNumber'] ?? 'لا يوجد هاتف';
    final Timestamp? lastVisitedStamp = data['lastVisited'] as Timestamp?;
    
    String lastVisitedText;
    Color lastVisitedColor;

    if (lastVisitedStamp == null) {
      lastVisitedText = 'لم يتم الافتقاد مطلقاً';
      lastVisitedColor = AppColors.redColor;
    } else {
      final lastVisitedDate = lastVisitedStamp.toDate();
      lastVisitedText = DateFormat('yyyy/MM/dd').format(lastVisitedDate);
      
      // حساب الفترة منذ آخر افتقاد
      final diffDays = DateTime.now().difference(lastVisitedDate).inDays;
      if (diffDays > 90) {
        lastVisitedColor = AppColors.redColor; // أكثر من 3 أشهر
      } else if (diffDays > 30) {
        lastVisitedColor = AppColors.accentColor; // أكثر من شهر
      } else {
        lastVisitedColor = AppColors.whiteColor; // أقل من شهر
      }
    }
    
    // عرض قائمة الخيارات (افتقاد، خريطة، تفاصيل)
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: AppColors.accentColor,
        child: Text(name[0], style: const TextStyle(color:      Color(0xFF4E342E)
)),
      ),
      title: Text(
        name,
        style: const TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(address, style: TextStyle(color: AppColors.whiteColor.withOpacity(0.8))),
          Text('آخر افتقاد: $lastVisitedText', style: TextStyle(color: lastVisitedColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppColors.accentColor),
        onSelected: (value) {
          if (value == 'log_visit') {
            _showLogVisitDialog(context, doc.id, name);
          } else if (value == 'view_details') {
            _showPersonDetailsDialog(context, doc.id, data);
          } else if (value == 'navigate') {
            _openNavigation(data['latitude'], data['longitude']);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'log_visit',
            child: Text('تسجيل افتقاد جديد', style: TextStyle(color:      Color(0xFF4E342E)
)),
          ),
          const PopupMenuItem<String>(
            value: 'view_details',
            child: Text('عرض التفاصيل والسجلات', style: TextStyle(color:      Color(0xFF4E342E)
)),
          ),
          const PopupMenuItem<String>(
            value: 'navigate',
            child: Text('التوجيه عبر الخرائط', style: TextStyle(color:      Color(0xFF4E342E)
)),
          ),
        ],
      ),
      onTap: () => _showPersonDetailsDialog(context, doc.id, data),
    );
  }

  // دالة لفتح تطبيق الخرائط (يفترض أنك تستخدم url_launcher)
  void _openNavigation(double? lat, double? lng) {
    if (lat != null && lng != null) {
      // ⚠️ يجب استخدام مكتبة url_launcher
      // final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
      // if (await canLaunch(url)) { await launch(url); } else { /* ... error ... */ }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم فتح التوجيه إلى الموقع في تطبيق الخرائط (يتطلب url_launcher).', textDirection: TextDirection.rtl)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا تتوفر إحداثيات GPS لهذا الشخص.', textDirection: TextDirection.rtl)),
      );
    }
  }


  // =========================================================================
  // 3. Modals and Dialogs (سجلات الافتقاد)
  // =========================================================================

  // فتح صفحة عرض التفاصيل والسجل
  Future<void> _showPersonDetailsDialog(
      BuildContext context, String userId, Map<String, dynamic> personData) async {
    final logsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('visitation_log')
        .orderBy('visitDate', descending: true)
        .get();

    final logs = logsSnapshot.docs.map((doc) => VisitationLog.fromFirestore(doc.data())).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
        backgroundColor:Color(0xFF4E342E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.accentColor)),
          title: Text(
            'تفاصيل وسجلات: ${personData['fullName']}',
            style: const TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildDetailRow('الهاتف', personData['phoneNumber']),
                _buildDetailRow('البريد', personData['email']),
                _buildDetailRow('العنوان', '${personData['streetAddress']}, ${personData['neighborhood']}, ${personData['city']}'),
                _buildDetailRow('تاريخ الميلاد', personData['birthDate']),
                const Divider(color: AppColors.accentColor, height: 20),
                const Text(
                  'سجل الافتقاد:',
                  style: TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                if (logs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('لا توجد سجلات افتقاد بعد.', style: TextStyle(color: AppColors.redColor), textAlign: TextAlign.right),
                  ),
                ...logs.map((log) => ListTile(
                      title: Text(log.notes, style: const TextStyle(color: AppColors.whiteColor, fontSize: 14)),
                      subtitle: Text(
                        'بواسطة ${log.visitorName} في ${DateFormat('yyyy/MM/dd').format(log.visitDate)}',
                        style: TextStyle(color: AppColors.accentColor.withOpacity(0.8), fontSize: 12),
                      ),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق', style: TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Widget لعرض تفاصيل الشخص في الـ Dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.whiteColor, fontSize: 14),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }


  // فتح صفحة تسجيل افتقاد
  Future<void> _showLogVisitDialog(BuildContext context, String userId, String name) async {
    final notesController = TextEditingController();
    final visitorName = FirebaseAuth.instance.currentUser?.displayName ?? 'خادم مجهول';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
        backgroundColor:Color(0xFF4E342E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.accentColor)),
          title: Text(
            'تسجيل افتقاد لـ $name',
            style: const TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
          content: TextField(
            controller: notesController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.whiteColor),
            decoration: InputDecoration(
              hintText: 'أضف ملاحظات عن الزيارة (مثل: احتياجات الصلاة، الحالة)',
              hintStyle: TextStyle(color: AppColors.whiteColor.withOpacity(0.5)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accentColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accentColor, width: 2)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء', style: TextStyle(color: AppColors.redColor)),
            ),
            TextButton(
              onPressed: () {
                _saveVisitationLog(userId, notesController.text.trim(), visitorName);
                Navigator.of(context).pop();
              },
              child: const Text('حفظ السجل', style: TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // دالة حفظ السجل في Firestore
  Future<void> _saveVisitationLog(String userId, String notes, String visitorName) async {
    if (notes.isEmpty) return;

    try {
      // 1. إضافة سجل جديد في مجموعة فرعية (sub-collection)
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('visitation_log')
          .add({
        'visitorName': visitorName,
        'visitDate': FieldValue.serverTimestamp(),
        'notes': notes,
      });

      // 2. تحديث حقل 'lastVisited' في المستند الرئيسي (للتصنيف والفرز السريع)
      await _firestore.collection('users').doc(userId).update({
        'lastVisited': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الافتقاد بنجاح.', textDirection: TextDirection.rtl)),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حفظ السجل: $e', textDirection: TextDirection.rtl)),
      );
    }
  }
}