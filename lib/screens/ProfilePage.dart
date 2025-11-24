// يجب التأكد من وجود هذه المكتبات في مشروع Flutter/Firebase
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =========================================================
// I. نموذج البيانات والثوابت (مُعاد تعريفها للتكامل)
// =========================================================

// تعريف AppColors لضمان التكامل مع التصميم
class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E); 
  static const Color secondaryGold = Color(0xFFFFF8E1); 
  static const Color backgroundColor = Color(0xFFF5F5F5); 
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color accentColor = Color(0xFFEBC76D);
}

// نموذج بيانات لتمثيل حقول المستخدم في Firestore
class PersonData {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String neighborhood;
  final String city;
  final String birthDate;
  final bool isAdmin;
  final bool isDataComplete;

  PersonData({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.neighborhood,
    required this.city,
    required this.birthDate,
    required this.isAdmin,
    required this.isDataComplete,
  });

  // دالة تحويل من Firestore Map
  factory PersonData.fromFirestore(Map<String, dynamic> data, User user) {
    return PersonData(
      // استخدام الاسم والبريد من Firebase Auth كقيمة افتراضية إذا لم يتم إدخالها في Firestore
      fullName: data['fullName'] ?? user.displayName ?? 'عضو جديد',
      email: data['email'] ?? user.email ?? 'غير معروف',
      
      // الحقول المدخلة من شاشة إدخال البيانات
      phoneNumber: data['phoneNumber'] ?? 'لم يتم الإدخال',
      neighborhood: data['neighborhood'] ?? 'لم يتم الإدخال',
      city: data['city'] ?? 'لم يتم الإدخال',
      birthDate: data['birthDate'] ?? 'لم يتم الإدخال',
      
      // حالات منطقية
      isAdmin: data['isAdmin'] ?? false,
      isDataComplete: data['isDataComplete'] ?? false,
    );
  }

  // دالة لتوفير بيانات افتراضية في حالة عدم وجود وثيقة في Firestore
  static PersonData defaultData(User user) {
    return PersonData(
      fullName: user.displayName ?? 'عضو جديد',
      email: user.email ?? 'غير معروف',
      phoneNumber: 'لم تُستكمل بعد',
      neighborhood: 'لم تُستكمل بعد',
      city: 'لم تُستكمل بعد',
      birthDate: 'لم تُستكمل بعد',
      isAdmin: false,
      isDataComplete: false,
    );
  }
}

// =========================================================
// II. الصفحة الرئيسية (ProfilePage) - الآن StatefulWidget
// =========================================================

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 1. حالة تخزين بيانات المستخدم
  PersonData? _userData;
  // 2. حالة التحميل
  bool _isLoading = true;
  // 3. الاستماع لتيار البيانات
  StreamSubscription? _dataSubscription;
  // 4. مُعرِّف المستخدم الحالي
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _fetchUserData();
    } else {
      // إذا لم يكن هناك مستخدم مسجل الدخول
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  // --------------------------------------------------------
  // دالة جلب بيانات المستخدم من Firestore
  // --------------------------------------------------------
  void _fetchUserData() {
    if (_currentUser == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);

    // الاستماع للتحديثات المباشرة على وثيقة المستخدم
    _dataSubscription = docRef.snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // إذا كانت الوثيقة موجودة، قم بجلب البيانات
        final data = PersonData.fromFirestore(snapshot.data()!, _currentUser!);
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      } else {
        // إذا لم تكن الوثيقة موجودة، استخدم بيانات افتراضية من Auth
        setState(() {
          _userData = PersonData.defaultData(_currentUser!);
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print("Error fetching user data: $error");
      setState(() {
        _isLoading = false;
      });
    });
  }

  // --------------------------------------------------------
  // دالة تسجيل الخروج (Sign Out Implementation)
  // --------------------------------------------------------
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الخروج بنجاح. نلقاك لاحقاً!')),
        );
        // يجب التوجيه إلى شاشة تسجيل الدخول
        // يتم افتراض وجود مسار تسجيل الدخول '/login'
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الخروج: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // إذا لم يكن هناك مستخدم مسجل الدخول
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('الرجاء تسجيل الدخول أولاً', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              _buildActionButton(
                context, 
                label: 'انتقال لتسجيل الدخول', 
                icon: Icons.login, 
                color: AppColors.primaryBlue, 
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false)
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title:  const Text('👤 صفحة المستخدم', style: TextStyle(color: AppColors.secondaryGold)),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
         centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // 1. بيانات المستخدم الأساسية (تعرض الآن البيانات الحقيقية)
                  _buildUserInfoCard(context),
                  const SizedBox(height: 30),

                  // زر الانتقال لإكمال البيانات (إذا كانت غير مكتملة)
                  if (_userData != null && !_userData!.isDataComplete)
                    _buildIncompleteDataWarning(context),
                  const SizedBox(height: 30),
                  
                  // زر تسجيل الخروج
                  // _buildActionButton(
                  //   context,
                  //   label: 'تسجيل الخروج',
                  //   icon: Icons.logout,
                  //   color: AppColors.primaryBlue,
                  //   onPressed: () => _signOut(context),
                  // ),
                ],
              ),
            ),
    );
  }

  // =========================================================
  // III. الويدجت المساعدة (Helper Widgets)
  // =========================================================

  // ويدجت لبطاقة بيانات المستخدم
  Widget _buildUserInfoCard(BuildContext context) {
    // استخدم بيانات المستخدم المُجلبة
    final info = _userData;
    
    // يجب أن يكون info غير فارغ هنا لأننا نتحقق من _isLoading
    if (info == null) {
      return const Center(child: Text("خطأ في جلب البيانات.", style: TextStyle(color: AppColors.textPrimary)));
    }

    return Card(
      elevation: 8, // ظل أوضح
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // حواف أكثر دائرية
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          children: [
            // 🌟 صورة المستخدم أو أيقونة
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.secondaryGold,
              child: Text(
                info.fullName.isNotEmpty ? info.fullName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 40, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            // 🌟 اسم المستخدم
            Text(
              info.fullName,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            
            // 🌟 حالة العضوية (إداري أم لا)
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: info.isAdmin ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                info.isAdmin ? 'مدير نظام 👑' : 'عضو مُسجَّل ✅',
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold, 
                  color: info.isAdmin ? Colors.red.shade900 : Colors.green.shade800
                ),
              ),
            ),
            
            const Divider(height: 30, thickness: 1.5, color: AppColors.primaryBlue),
            
            // تفاصيل البيانات
            _buildDetailRow(Icons.email, 'البريد الإلكتروني:', info.email),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.phone_android, 'رقم الهاتف:', info.phoneNumber),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.cake, 'تاريخ الميلاد:', info.birthDate),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_city, 'المدينة:', info.city),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_on, 'الحي/المنطقة:', info.neighborhood),
          ],
        ),
      ),
    );
  }

  // ويدجت لسطر تفصيلي
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 24),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 16),
          ),
          const Spacer(),
          Expanded(
            child: Text(
              value.isEmpty || value == 'لم يتم الإدخال' ? 'لم يتم الإدخال' : value, // عرض رسالة افتراضية
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت زر الإجراءات
  Widget _buildActionButton(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.secondaryGold),
      label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondaryGold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
    );
  }

  // ويدجت التحذير من البيانات الناقصة
  Widget _buildIncompleteDataWarning(BuildContext context) {
    return Card(
      color: AppColors.accentColor.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: AppColors.accentColor, width: 1.5)
      ),
      // child: ListTile(
      //   leading: const Icon(Icons.warning_amber_rounded, color: AppColors.accentColor, size: 30),
      //   title: const Text(
      //     'البيانات الأساسية غير مكتملة', 
      //     style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)
      //   ),
      //   subtitle: const Text(
      //     'الرجاء إكمال بياناتك لضمان جودة الخدمة والمتابعة.', 
      //     style: TextStyle(color: AppColors.textSecondary)
      //   ),
      //   trailing: ElevatedButton(
      //     onPressed: () {
      //       // التوجيه إلى شاشة إدخال البيانات - يجب أن يكون المسار '/member_data_entry' معرفاً في MaterialApp
      //       Navigator.pushNamed(context, '/member_data_entry'); 
      //     },
      //     style: ElevatedButton.styleFrom(
      //       backgroundColor: AppColors.accentColor,
      //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      //       elevation: 3,
      //       padding: const EdgeInsets.symmetric(horizontal: 10),
      //     ),
      //     child: const Text('إكمال', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
      //   ),
      // ),
    );
  }
}