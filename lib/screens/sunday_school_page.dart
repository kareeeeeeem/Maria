// sunday_school_unified_page.dart
// صفحة إدارة طلاب مدارس الأحد مع Firebase وإدارة الصلاحيات لكل كنيسة.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';


// =========================================================
// 1. الثوابت والألوان
// =========================================================
class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E); // أزرق أساسي
  static const Color secondaryGold = Color(0xFFFFC107); // ذهبي ثانوي
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF757575);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFFF0F4F8);
  static const Color errorRed = Color(0xFFD32F2F);
}

// =========================================================
// 2. نماذج البيانات (Models)
// =========================================================

// نموذج صلاحيات المستخدم (ChurchUser)
class ChurchUser {
  final String uid;
  final String fullName;
  final String email;
  final bool isAdmin; // مشرف عام
  final List<String> churchAdminOf; // قائمة بـ IDs الكنائس التي يديرها

  ChurchUser({
    required this.uid,
    this.fullName = 'مستخدم غير معروف',
    this.email = '',
    required this.isAdmin,
    this.churchAdminOf = const [],
  });

  // دالة تحويل من Firestore
  factory ChurchUser.fromMap(Map<String, dynamic> data, String uid) {
    return ChurchUser(
      uid: uid,
      fullName: data['fullName'] ?? 'مستخدم غير معروف',
      email: data['email'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      churchAdminOf: List<String>.from(data['churchAdminOf'] ?? []),
    );
  }

  // التحقق من صلاحية الإدارة لكنيسة معينة
  bool isChurchAdmin(String churchId) {
    // القاعدة 1: المشرف العام (isAdmin) يدير كل شيء، أو القاعدة 2: إذا كان ChurchId في قائمة الإدارة
    return isAdmin || churchAdminOf.contains(churchId);
  }

  // التحقق إذا كان المستخدم يمتلك أي صلاحيات إدارية (عامة أو خاصة بكنيسة)
  bool get isAnyAdmin => isAdmin || churchAdminOf.isNotEmpty;
}

// نموذج بيانات الطالب (Student)
class Student {
  final String id;
  final String name;
  final String parentContact;
  final String classLevel; // مثال: "ابتدائي - أول"
  final String address;

  Student({
    required this.id,
    required this.name,
    required this.parentContact,
    required this.classLevel,
    required this.address,
  });

  // دالة تحويل من Firestore
  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      name: data['name'] ?? 'اسم غير محدد',
      parentContact: data['parentContact'] ?? '',
      classLevel: data['classLevel'] ?? 'غير مصنف',
      address: data['address'] ?? 'غير متوفر',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'parentContact': parentContact,
      'classLevel': classLevel,
      'address': address,
      'registrationDate': FieldValue.serverTimestamp(),
    };
  }
}

// =========================================================
// 3. الكنائس المعرفة
// =========================================================
const Map<String, String> CHURCHES = {
  'virgin_mary': 'مدارس أحد كنيسة العذراء مريم',
  'st_nicholas': 'مدارس أحد القديس نيقلاوس',
};

// =========================================================
// 4. الصفحة الرئيسية (SundaySchoolPage)
// =========================================================

class SundaySchoolPage extends StatefulWidget {
  const SundaySchoolPage({super.key});

  @override
  State<SundaySchoolPage> createState() => _SundaySchoolPageState();
}

class _SundaySchoolPageState extends State<SundaySchoolPage> with TickerProviderStateMixin {
  late FirebaseApp _firebaseApp;
  late FirebaseAuth _auth;
  late FirebaseFirestore _db;
  ChurchUser? _currentUser;
  bool _isLoading = true;
  late TabController _tabController;

  // تعريف المتغيرات العامة التي يوفرها الـ Canvas
  final String _appId = (const String.fromEnvironment('APP_ID')).isNotEmpty ? const String.fromEnvironment('APP_ID') : 'default-app-id';

  @override
  void initState() {
    super.initState();
    // إنشاء مبدئي لوحدة التحكم، سيتم تحديث طولها في build إذا لزم الأمر
    _tabController = TabController(length: CHURCHES.length, vsync: this);
    _initializeFirebase();
  }
  
  // لضمان التخلص من الـ controller عند إغلاق الـ widget
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  // تهيئة Firebase والتحقق من الصلاحيات
  Future<void> _initializeFirebase() async {
    try {
      // بما أن الـ Canvas يوفر التهيئة، نعتمد على الإعدادات التلقائية
      await Firebase.initializeApp();
      _firebaseApp = Firebase.app();
      _auth = FirebaseAuth.instanceFor(app: _firebaseApp);
      _db = FirebaseFirestore.instanceFor(app: _firebaseApp);
      
      // المصادقة كمجهول كمحاكاة للدخول (لتلبية متطلبات Canvas)
      await _auth.signInAnonymously();
      
      // الاستماع لحالة المصادقة وجلب بيانات المستخدم
      _auth.authStateChanges().listen((user) {
        if (user != null) {
          _loadUserData(user.uid);
        } else {
          setState(() {
            _currentUser = null;
            _isLoading = false;
          });
        }
      });
      
    } catch (e) {
      print('Firebase initialization or sign-in error: $e');
      setState(() => _isLoading = false);
    }
  }

  // جلب بيانات المستخدم لتحديد الصلاحيات
  void _loadUserData(String uid) {
    // المسار المفترض لبيانات الصلاحيات
    final userProfileRef = _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('data');

    userProfileRef.get().then((doc) {
      if (doc.exists && doc.data() != null) {
        // تم تحميل بيانات المشرف (العام أو الخاص بالكنيسة)
        setState(() {
          _currentUser = ChurchUser.fromMap(doc.data()!, uid);
        });
        print('User Data Loaded: isAdmin=${_currentUser!.isAdmin}, managed churches: ${_currentUser!.churchAdminOf}');
      } else {
        // التعديل: إذا لم يتم العثور على بيانات في Firestore، يعتبر المستخدم عادياً (بدون صلاحيات إدارية) لتطبيق Rule 3.
        setState(() {
          _currentUser = ChurchUser(
            uid: uid,
            isAdmin: false, // مستخدم عادي
            fullName: 'مستخدم عادي (لا صلاحيات)',
            churchAdminOf: [], 
          );
        });
        print('User data not found in Firestore. Defaulting to Regular User (No Admin Rights).');
      }
      setState(() => _isLoading = false);
    }).catchError((e) {
      print('Error loading user data: $e');
      // في حال حدوث خطأ، استمر كمستخدم عادي بدون صلاحيات (الأكثر أماناً)
        setState(() {
           _currentUser = ChurchUser(
            uid: uid,
            isAdmin: false, 
            fullName: 'خطأ في التحميل - مستخدم عادي',
            churchAdminOf: [], 
          );
          _isLoading = false;
        });
    });
  }

  // =========================================================
  // بناء عناصر الواجهة الرسومية
  // =========================================================

  // بناء بطاقة التسجيل (إضافة طالب)
  Widget _buildRegistrationCard(BuildContext context, String churchId) {
    return _SectionCard(
      title: '📝 إضافة طالب جديد',
      icon: Icons.app_registration,
      color: AppColors.primaryBlue,
      children: [
        const Text(
          'يمكنك تسجيل طفل جديد في مدارس الأحد للكنيسة الحالية.',
          textAlign: TextAlign.right,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 15),
        ElevatedButton.icon(
          onPressed: () => _showAddStudentDialog(context, churchId),
          icon: const Icon(Icons.person_add, color: AppColors.cardColor),
          label: const Text('اضافة طالب جديد', style: TextStyle(color: AppColors.cardColor, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 5,
          ),
        ),
      ],
    );
  }

  
  // شاشة منبثقة لإضافة/تعديل طالب
  void _showAddStudentDialog(BuildContext context, String churchId, {Student? studentToEdit}) {
    final isEditMode = studentToEdit != null;
    final nameController = TextEditingController(text: isEditMode ? studentToEdit.name : '');
    final contactController = TextEditingController(text: isEditMode ? studentToEdit.parentContact : '');
    final addressController = TextEditingController(text: isEditMode ? studentToEdit.address : '');
    String? selectedClassLevel = isEditMode ? studentToEdit.classLevel : null;
    
    final List<String> classLevels = ['ابتدائي - أول', 'ابتدائي - ثاني', 'إعدادي - أول', 'ثانوي - أول']; 

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(isEditMode ? 'تعديل بيانات الطالب' : 'تسجيل طالب جديد', textAlign: TextAlign.right),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الطالب بالكامل', alignLabelWithHint: true)),
                    TextField(controller: contactController, decoration: const InputDecoration(labelText: 'تواصل ولي الأمر', alignLabelWithHint: true, hintText: '01xxxxxxxxxx', prefixIcon: Icon(Icons.phone))),
                    TextField(controller: addressController, decoration: const InputDecoration(labelText: 'العنوان', alignLabelWithHint: true, prefixIcon: Icon(Icons.location_on))),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'المستوى الدراسي',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                      value: selectedClassLevel,
                      hint: const Text('اختر المرحلة/الصف'),
                      items: classLevels.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedClassLevel = newValue;
                        });
                      },
                    ),
                  ],
                ),
              );
            }
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && selectedClassLevel != null) {
                  final newStudentData = Student(
                    id: isEditMode ? studentToEdit.id : '',
                    name: nameController.text,
                    parentContact: contactController.text,
                    classLevel: selectedClassLevel!,
                    address: addressController.text,
                  );

                  if (isEditMode) {
                    _updateStudentInFirebase(churchId, newStudentData);
                  } else {
                    _addStudentToFirebase(churchId, newStudentData);
                  }

                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرجاء إدخال اسم الطالب واختيار المستوى.')),
                  );
                }
              },
              child: Text(isEditMode ? 'تعديل' : 'تسجيل'),
            ),
          ],
        );
      },
    );
  }

  // دالة إضافة طالب إلى Firebase
  Future<void> _addStudentToFirebase(String churchId, Student student) async {
    try {
      final docRef = _db
          .collection('artifacts')
          .doc(_appId)
          .collection('public')
          .doc('data')
          .collection('churches')
          .doc(churchId)
          .collection('students');

      await docRef.add(student.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تسجيل الطالب ${student.name} بنجاح!')),
      );
    } catch (e) {
      print('Firebase error adding student: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في التسجيل: $e')),
      );
    }
  }

  // دالة لتحديث بيانات طالب في Firebase
  Future<void> _updateStudentInFirebase(String churchId, Student student) async {
    try {
      final docRef = _db
          .collection('artifacts')
          .doc(_appId)
          .collection('public')
          .doc('data')
          .collection('churches')
          .doc(churchId)
          .collection('students')
          .doc(student.id);

      // نستخدم updateDoc بدلاً من setDoc لضمان عدم حذف الحقول الأخرى غير المذكورة
      await docRef.update(student.toMap()); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث بيانات الطالب ${student.name} بنجاح!')),
      );
    } catch (e) {
      print('Firebase error updating student: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في التحديث: $e')),
      );
    }
  }

  // بناء صفحة العرض والإدارة لكل كنيسة
  Widget _buildChurchView(String churchId) {
    // التحقق من صلاحية المشرف (القاعدة 1 والمشرف الخاص بالكنيسة القاعدة 2)
    final bool canAdminister = _currentUser?.isChurchAdmin(churchId) ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1. العنوان الرئيسي للكنيسة
          _buildHeader(CHURCHES[churchId]!, churchId),
          const SizedBox(height: 20),

          // 2. المحتوى بناءً على الصلاحية (مرئي للمشرف العام والمشرف الخاص بالكنيسة فقط)
          if (canAdminister) ...[
            // لوحة الإدارة (للمشرفين فقط: عرض/فلترة/حذف)
            _ManagementDashboard(db: _db, churchId: churchId, appId: _appId, showEditDialog: (s) => _showAddStudentDialog(context, churchId, studentToEdit: s)),
            const SizedBox(height: 20),
            // بطاقة تسجيل طالب جديد (إضافة طالب)
            _buildRegistrationCard(context, churchId),
            const SizedBox(height: 20),
          ] else ...[
             // للمستخدم العادي (أو المشرف الذي ليس مسؤولاً عن هذه الكنيسة) - القاعدة 2/3
             const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'غير مصرح لك بالوصول إلى بيانات إدارة الطلاب لهذه الكنيسة. هذه الصلاحيات مخصصة للمديرين فقط.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: AppColors.textSecondary, height: 1.5),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // عناصر البناء المشتركة
  // =========================================================

  Widget _buildHeader(String title, String churchId) {
    // التعديل: عرض حالة الصلاحيات الحالية في العنوان
    String authStatus = _isLoading
        ? 'جاري التحميل...'
        : _currentUser?.isChurchAdmin(churchId) == true
            ? 'مشرف مفوض'
            : (_currentUser?.isAnyAdmin == true ? 'مشرف على كنائس أخرى' : 'مستخدم عادي');

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school, size: 40, color: AppColors.primaryBlue),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                const SizedBox(height: 5),
                Text('هذه صفحة إدارة الطلاب الخاصة بكنيسة $churchId.', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                // عرض حالة الصلاحية
                Text('حالة صلاحيتي: $authStatus', style: TextStyle(fontSize: 14, color: _currentUser?.isChurchAdmin(churchId) == true ? Colors.green.shade700 : AppColors.errorRed, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }
    
    // القاعدة 3: التحقق من صلاحيات المستخدم العامة. إذا لم يكن مشرفاً عاماً ولا مشرفاً على أي كنيسة، اعرض صفحة حظر.
    final isAnyAdmin = _currentUser?.isAnyAdmin ?? false;
    if (!isAnyAdmin) {
        return const Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'غير مصرح لك بالوصول. هذه الصفحة مخصصة لمديري مدارس الأحد فقط وتتطلب صلاحيات إدارية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.errorRed),
                ),
              ),
            ),
        );
    }
    
    // قائمة الكنائس المرئية:
    // القاعدة 1: المشرف العام يرى الكل.
    // القاعدة 2: المشرف الخاص يرى كنائسه فقط.
    final visibleChurchIds = CHURCHES.keys.where((churchId) {
        return _currentUser!.isAdmin || _currentUser!.churchAdminOf.contains(churchId);
    }).toList();
    
    final visibleChurches = Map.fromEntries(CHURCHES.entries.where((entry) => visibleChurchIds.contains(entry.key)));

    // يجب أن يكون هناك كنيسة واحدة على الأقل مرئية (لأننا تجاوزنا اختبار isAnyAdmin)
    if (visibleChurches.isEmpty) {
      // حالة نظرية، لكن نضيفها للأمان.
      return const Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'لم يتم تعيينك كمدير لأي كنيسة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.errorRed),
                ),
              ),
            ),
        );
    }
    
    // إعادة إنشاء TabController بناءً على الكنائس المرئية
    if (_tabController.length != visibleChurches.length) {
      _tabController.dispose();
      _tabController = TabController(length: visibleChurches.length, vsync: this);
    }
    
    // إنشاء قائمة التبويبات (Tabs)
    final tabs = visibleChurches.entries.map((entry) {
      return Tab(text: entry.value);
    }).toList();

    // إنشاء قائمة صفحات التبويبات (Tab Views)
    final tabViews = visibleChurches.keys.map((churchId) {
      return _buildChurchView(churchId);
    }).toList();


    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('📚 لوحة إدارة طلاب مدارس الأحد', style: TextStyle(color: AppColors.secondaryGold)),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.secondaryGold,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.secondaryGold,
          // عكس القائمة للعرض من اليمين لليسار بناءً على الثقافة العربية
          tabs: tabs.reversed.toList(), 
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // عكس القائمة للعرض من اليمين لليسار
        children: tabViews.reversed.toList(), 
      ),
    );
  }
}

// =========================================================
// 5. مكون لوحة الإدارة (Management Dashboard) للمشرفين
// =========================================================

class _ManagementDashboard extends StatelessWidget {
  final FirebaseFirestore db;
  final String churchId;
  final String appId; 
  final Function(Student) showEditDialog; // لتمرير دالة التعديل

  
  // لتعريف مستويات الدراسة التي يمكن للمشرف فلترة الطلاب بها
  final List<String> _classLevels = ['ابتدائي - أول', 'ابتدائي - ثاني', 'إعدادي - أول', 'ثانوي - أول', 'جميع المستويات'];

    _ManagementDashboard({required this.db, required this.churchId, required this.appId, required this.showEditDialog});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '🛡️ إدارة وعرض بيانات الطلاب',
      icon: Icons.admin_panel_settings,
      color: AppColors.errorRed, // لون مختلف لجذب انتباه المشرف
      children: [
        const Text(
          'يمكنك هنا عرض وإدارة بيانات طلاب مدارس الأحد الخاصة بكنيستك (عرض، تعديل، حذف، فلترة).',
          textAlign: TextAlign.right,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 15),
        // زر عرض بيانات الطلاب (يفتح شاشة جديدة)
        ElevatedButton.icon(
          onPressed: () {
            // يتم توجيه المشرف لصفحة إدارة بيانات الطلاب
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => _StudentDataPage(
                db: db, 
                churchId: churchId, 
                classLevels: _classLevels, 
                appId: appId, 
                showEditDialog: showEditDialog, // تمرير دالة التعديل
              ),
            ));
          },
          icon: const Icon(Icons.list_alt, color: AppColors.cardColor),
          label: const Text('عرض وتعديل بيانات الطلاب', style: TextStyle(color: AppColors.cardColor, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorRed,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 5,
          ),
        ),
      ],
    );
  }
}

// =========================================================
// 6. صفحة عرض بيانات الطلاب (Student Data Page)
// =========================================================

class _StudentDataPage extends StatefulWidget {
  final FirebaseFirestore db;
  final String churchId;
  final List<String> classLevels;
  final String appId;
  final Function(Student) showEditDialog; // دالة للتعديل

  const _StudentDataPage({required this.db, required this.churchId, required this.classLevels, required this.appId, required this.showEditDialog});

  @override
  State<_StudentDataPage> createState() => _StudentDataPageState();
}

class _StudentDataPageState extends State<_StudentDataPage> {
  String _selectedLevel = 'جميع المستويات';

  // مسار البيانات في Firestore
  CollectionReference get _studentsCollectionRef => widget.db
      .collection('artifacts')
      .doc(widget.appId) 
      .collection('public')
      .doc('data')
      .collection('churches')
      .doc(widget.churchId)
      .collection('students');
  
  // عرض شاشة تفاصيل الطالب
  void _showStudentDetails(Student student) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(student.name, textAlign: TextAlign.right),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end, // محاذاة النص لليمين
            children: [
              Text('المستوى: ${student.classLevel}', textAlign: TextAlign.right),
              Text('تواصل ولي الأمر: ${student.parentContact}', textAlign: TextAlign.right),
              Text('العنوان: ${student.address}', textAlign: TextAlign.right),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.showEditDialog(student); // فتح شاشة التعديل
              },
              child: const Text('تعديل البيانات', style: TextStyle(color: AppColors.primaryBlue)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmDeleteStudent(student); // طلب تأكيد الحذف
              },
              child: const Text('حذف الطالب', style: TextStyle(color: AppColors.errorRed)),
            ),
          ],
        );
      },
    );
  }
  
  // تأكيد الحذف (لأننا لا نستخدم alert())
  void _confirmDeleteStudent(Student student) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تأكيد الحذف', textAlign: TextAlign.right),
          content: Text('هل أنت متأكد من حذف بيانات الطالب "${student.name}"؟', textAlign: TextAlign.right),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteStudent(student.id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
              child: const Text('تأكيد الحذف', style: TextStyle(color: AppColors.cardColor)),
            ),
          ],
        ),
      );
  }
  
  // دالة لحذف الطالب
  Future<void> _deleteStudent(String studentId) async {
    try {
      await _studentsCollectionRef.doc(studentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الطالب بنجاح.')),
      );
    } catch (e) {
      print('Error deleting student: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في الحذف: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // بناء الاستعلام: إذا كان "جميع المستويات"، نجلب كل شيء، وإلا نستخدم الـ where
    Query query = _studentsCollectionRef;
    if (_selectedLevel != 'جميع المستويات') {
      query = query.where('classLevel', isEqualTo: _selectedLevel);
    }
    
    // ملاحظة: لا يوجد orderBy() هنا لتجنب أخطاء الفهرسة (Index Errors)
    
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة طلاب ${CHURCHES[widget.churchId]}', style: const TextStyle(color: AppColors.secondaryGold)),
        backgroundColor: AppColors.primaryBlue,
        actions: [
          // قائمة منسدلة للفلترة حسب المستوى
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButton<String>(
              value: _selectedLevel,
              dropdownColor: AppColors.primaryBlue,
              style: const TextStyle(color: AppColors.secondaryGold, fontWeight: FontWeight.bold),
              icon: const Icon(Icons.filter_list, color: AppColors.secondaryGold),
              underline: const SizedBox(),
              items: widget.classLevels.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, textAlign: TextAlign.right),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLevel = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في جلب البيانات: ${snapshot.error}', textAlign: TextAlign.center));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }
          
          final students = snapshot.data!.docs.map((doc) => Student.fromFirestore(doc)).toList();

          if (students.isEmpty) {
            return Center(
              child: Text(
                _selectedLevel == 'جميع المستويات' 
                    ? 'لا يوجد طلاب مسجلين في هذه الكنيسة حالياً.'
                    : 'لا يوجد طلاب في مستوى "$_selectedLevel".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            );
          }
          
          // فرز البيانات محلياً (بدلاً من استخدام orderBy في الاستعلام لتجنب أخطاء الفهرسة)
          students.sort((a, b) => a.name.compareTo(b.name));

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.child_care, color: Colors.blueGrey),
                  title: Text(student.name, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('المستوى: ${student.classLevel} - تواصل ولي الأمر: ${student.parentContact}', textAlign: TextAlign.right),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
                        onPressed: () => widget.showEditDialog(student),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.errorRed),
                        onPressed: () => _confirmDeleteStudent(student),
                      ),
                    ],
                  ),
                  onTap: () => _showStudentDetails(student),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


// =========================================================
// 7. مُكون البطاقة العامة
// =========================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(width: 10),
                Icon(icon, color: color, size: 28),
              ],
            ),
            const Divider(color: AppColors.secondaryGold, thickness: 1.5, height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}