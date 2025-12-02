// بردو هنا لازم يدخل الاسم رباعي // ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

// =========================================================================
// 1. Data Model (نموذج البيانات الأساسي)
// =========================================================================

class PersonData {
  String fullName;
  String email;
  String phoneNumber;
  String streetAddress; // اسم الشارع
  String neighborhood; // الحي/المنطقة (أساس التصنيف)
  String city;
  String birthDate;
  double? latitude; // خط العرض
  double? longitude; // خط الطول
  bool isDataComplete;
  DateTime? lastVisited;

  PersonData({
    required this.fullName,
    required this.email,
    this.phoneNumber = '',
    this.streetAddress = '',
    this.neighborhood = '',
    this.city = '',
    this.birthDate = '',
    this.latitude,
    this.longitude,
    this.isDataComplete = false,
    this.lastVisited,
  });

  // تابع للتحويل إلى Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'streetAddress': streetAddress,
      'neighborhood': neighborhood,
      'city': city,
      'birthDate': birthDate,
      'latitude': latitude,
      'longitude': longitude,
      'isDataComplete': isDataComplete,
      'lastVisited': lastVisited,
      'updatedAt': FieldValue.serverTimestamp(),
      'isAdmin': false, // يتم تعيينه عند التسجيل
    };
  }
}

// =========================================================================
// 2. Constants and Styling (كما في الكود الأصلي)
// =========================================================================

class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color primaryDark = Color(0xFF0F1B3A);
  static const Color accentColor = Color(0xFFEBC76D);
  static const List<Color> accentGradient = [Color(0xFFEBC76D), Color(0xFFB39744)];
  static const Color redColor = Color(0xFFEA4E79);
}

// =========================================================================
// 3. Member Data Entry Screen
// =========================================================================

class MemberDataEntryScreen extends StatefulWidget {
  static const String routeName = '/member_data_entry';
  const MemberDataEntryScreen({super.key});

  @override
  State<MemberDataEntryScreen> createState() => _MemberDataEntryScreenState();
}

class _MemberDataEntryScreenState extends State<MemberDataEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  // 🆕 تحكم جديد للاسم الكامل
  final _fullNameController = TextEditingController(); 
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  
  // 1. تعريف مُنسق التاريخ
  final _dateMaskFormatter = MaskTextInputFormatter(
    mask: '##/##/####', // DD/MM/YYYY
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _isLoading = false;
  String? _errorMessage;

  // حالة حفظ الإحداثيات
  double? _tempLat;
  double? _tempLng;
  String _locationStatus = "";

  @override
  void initState() {
    super.initState();
    // جلب البيانات الأولية (الاسم والبريد) من Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // إذا لم يكن هناك مستخدم، عد إلى شاشة التسجيل
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // افتراض وجود شاشة تسجيل /login
        Navigator.of(context).pushReplacementNamed('/login'); 
      });
    } else {
      // 🆕 تهيئة وحدة تحكم الاسم باستخدام اسم العرض الحالي (إذا وُجد)
      _fullNameController.text = user.displayName ?? ''; 
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose(); // 🆕 التخلص من وحدة التحكم
    _phoneController.dispose();
    _streetController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  // =========================================================================
  // 4. دالة منتقي التاريخ (Date Picker)
  // =========================================================================
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), // تاريخ مبدئي معقول (على سبيل المثال سنة 2000)
      firstDate: DateTime(1900),
      lastDate: DateTime.now(), // لا يمكن اختيار تاريخ مستقبلي
      helpText: 'اختر تاريخ الميلاد', // نص إرشادي في الديالوج
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentColor, // لون الرأس (Header)
              onPrimary: Color(0xFF4E342E), // لون النص على الرأس
              onSurface: AppColors.primaryDark, // لون النص في التقويم
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 0, 0, 0), // لون أزرار التأكيد والإلغاء
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // تنسيق التاريخ إلى DD/MM/YYYY
      final formattedDate =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      
      setState(() {
        // تحديث وحدة التحكم والقيمة المنسقة في نفس الوقت
        _birthDateController.text = formattedDate;
      });
      
      // من الضروري تحديث قيمة المُنسق الداخلي أيضاً
      _dateMaskFormatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        TextEditingValue(text: formattedDate),
      );
    }
  }

  // دالة لتحديد الموقع الجغرافي من العنوان المدخل
  Future<void> _geocodeAddress() async {
    final fullAddress =
        '${_streetController.text}, ${_neighborhoodController.text}, ${_cityController.text}';

    setState(() {
      _locationStatus = "جاري البحث عن الموقع...";
      _tempLat = null;
      _tempLng = null;
    });

    try {
      // يجب التأكد من تهيئة مكتبة geocoding
      List<Location> locations = await locationFromAddress(fullAddress);

      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _tempLat = location.latitude;
          _tempLng = location.longitude;
          _locationStatus = "تم التحديد بنجاح: Lat ${_tempLat!.toStringAsFixed(4)}, Lng ${_tempLng!.toStringAsFixed(4)}";
        });
      } else {
        setState(() {
          _locationStatus = "لم يتم العثور على إحداثيات لهذا العنوان.";
        });
      }
    } catch (e) {
      setState(() {
        _locationStatus = "خطأ في تحديد الموقع. الرجاء مراجعة العنوان.";
      });
      print("Geocoding Error: $e");
    }
  }

  // دالة لحفظ البيانات
  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // منطق الإحداثيات الاختياري:
      if (_tempLat == null && 
          _cityController.text.isNotEmpty && 
          _neighborhoodController.text.isNotEmpty && 
          _streetController.text.isNotEmpty) {
          
          await _geocodeAddress(); 
      }
      
      // بناء نموذج البيانات - 🆕 استخدام القيمة المدخلة من حقل الاسم
      final personData = PersonData(
        fullName: _fullNameController.text.trim(), 
        email: user.email!,
        phoneNumber: _phoneController.text.trim(),
        streetAddress: _streetController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        city: _cityController.text.trim(),
        // يتم حفظ التاريخ مع الفواصل التي تم تنسيقها بواسطة المُنَسِّق
        birthDate: _birthDateController.text.trim(),
        latitude: _tempLat, // سيتم حفظ null إذا لم يتم تحديده
        longitude: _tempLng, // سيتم حفظ null إذا لم يتم تحديده
        isDataComplete: true, 
      );

      // 2. حفظ البيانات في Firestore تحت مُعرّف المستخدم
      await _firestore.collection('users').doc(user.uid).set(
            personData.toFirestore(),
            SetOptions(merge: true), 
          );

      // 3. التوجيه إلى الشاشة الرئيسية (Home)
      if (mounted) {
        // افتراض وجود شاشة رئيسية /home
        Navigator.pushReplacementNamed(context, '/home'); 
      }
    } on PlatformException catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تحديد الموقع: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ غير متوقع أثناء الحفظ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 تصميم مبهر: خلفية داكنة مع تباين قوي
    return Scaffold(
      backgroundColor:      const Color(0xFF4E342E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  '⛪',
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                 const SizedBox(height: 30),

                // 🆕 حقل الاسم الكامل
                _buildTextField(
                  controller: _fullNameController,
                  label: 'الاسم الكامل (رباعي)',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الاسم الكامل (رباعي)';
                    }
                    // التحقق من أن الاسم يحتوي على 4 أجزاء على الأقل (3 مسافات)
                    final parts = value.trim().split(RegExp(r'\s+'));
                    if (parts.length < 4) {
                      return 'الرجاء إدخال الاسم رباعيًا ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),


                // 📞 رقم الهاتف
                _buildTextField(
                  controller: _phoneController,
                  label: 'رقم الهاتف (للاتصال او الواتساب)',
                  icon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال رقم الهاتف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 🎂 تاريخ الميلاد - الآن أيقونة فتح الديالوج هي الوحيدة الظاهرة
                _buildDateField(
                  controller: _birthDateController,
                  label: 'تاريخ الميلاد (يوم/شهر/سنة)',
                  inputFormatters: [_dateMaskFormatter],
                  onTap: () => _selectDate(context),
                  validator: (value) =>
                      (value == null || value.isEmpty || value.length < 10) ? 'الرجاء إدخال تاريخ ميلاد كامل (DD/MM/YYYY)' : null,
                ),
                const SizedBox(height: 30),

                const Divider(color: AppColors.accentColor, thickness: 0.5),
                const SizedBox(height: 10),
                const Text(
                  ' العنوان ',
                  style: TextStyle(
                    color: AppColors.accentColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 20),

                // 🏙️ المدينة
                _buildTextField(
                  controller: _cityController,
                  label: 'المدينة/المحافظة',
                  icon: Icons.location_city,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'الرجاء إدخال اسم المدينة' : null,
                ),
                const SizedBox(height: 20),

                // 🏘️ الحي/المنطقة (أساس التصنيف)
                _buildTextField(
                  controller: _neighborhoodController,
                  label: 'اسم الحي أو المنطقة',
                  icon: Icons.location_on_outlined,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'الرجاء إدخال اسم الحي/المنطقة' : null,
                ),
                const SizedBox(height: 20),

                // 🛣️ الشارع/العنوان التفصيلي
                _buildTextField(
                  controller: _streetController,
                  label: 'اسم الشارع ورقم المنزل/الشقة',
                  icon: Icons.house_outlined,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'الرجاء إدخال العنوان التفصيلي' : null,
                ),
                const SizedBox(height: 15),

                // زر تحديد الموقع الجغرافي
                _buildGeoLocationButton(),
                const SizedBox(height: 10),
                Text(
                  _locationStatus,
                  style: TextStyle(
                      color: _tempLat != null ? AppColors.accentColor : AppColors.redColor,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                // Error Message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.redColor, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 10),

                // زر الحفظ والمتابعة (CTA)
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget for GeoLocation Button
  Widget _buildGeoLocationButton() {
    return Container(
      decoration: BoxDecoration(
        color:      const Color(0xFF4E342E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.accentColor, width: 1.5),
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _geocodeAddress,
        icon: const Icon(Icons.maps_home_work_outlined, color: AppColors.accentColor),
       label: const Text(
          // تم التعديل هنا: استخدام سلسلة نصية متعددة الأسطر لكسر السطر
          '''تحديد الموقع الجغرافي للمنزل
(يفضل للتسهيل علي الافتقاد)''',
          style: TextStyle(color: AppColors.accentColor, fontSize: 16),
          textAlign: TextAlign.center, // يفضل وضع توسيط للنص متعدد الأسطر
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 15),
          elevation: 0,
        ),
      ),
    );
  }

  // Widget for Save Button
  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.accentGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentColor.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveUserData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 10,
                width: 10,
                child: CircularProgressIndicator(color: Color(0xFF4E342E), strokeWidth: 2))
            : const Text(
                'حفظ البيانات والمتابعة',
                style: TextStyle(
                  color: Color(0xFF4E342E),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }

  // 🔴 5. دالة بناء حقل إدخال التاريخ المعدلة 
  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required List<TextInputFormatter> inputFormatters,
    required VoidCallback onTap, // الدالة التي سيتم تنفيذها عند النقر على الأيقونة
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: validator,
      readOnly: false, // يمكن التعديل يدوياً أو من خلال الـ Date Picker
      inputFormatters: inputFormatters, 
      style: const TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: IconButton( 
          icon: const Icon(Icons.edit_calendar_outlined, color: AppColors.accentColor),
          onPressed: onTap, // ربط الأيقونة بدالة _selectDate
        ),
        labelStyle: const TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.w400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.accentColor, width: 2),
        ),
        fillColor: const Color(0xFF4E342E).withOpacity(0.8),
        filled: true,
      ),
    );
  }
  
  // دالة بناء حقل الإدخال العام (بدون منتقي تاريخ)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters, 
      style: const TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.accentColor),
        labelStyle: const TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.w400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.accentColor, width: 2),
        ),
        fillColor: const Color(0xFF4E342E).withOpacity(0.8),
        filled: true,
      ),
    );
  }
}