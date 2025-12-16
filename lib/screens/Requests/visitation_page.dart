import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ⬅️ ضروري للإرسال إلى Firebase

// =========================================================
// I. الألوان والثوابت
// =========================================================

class AppColors {
  static const Color primaryBlue = Color(0xFF4E342E); // اللون البني الداكن
  static const Color secondaryGold = Color(0xFFFFF8E1); // لون ذهبي فاتح/بيج
  static const Color backgroundColor = Color(0xFFF5F5F5); 
  static const Color cardColor = Colors.white;
  static const Color textSecondary = Color(0xFF757575);
  static const Color statusVisited = Colors.green; // لون رسالة النجاح
  static const Color textPrimary = Color(0xFF212121);
}

// =========================================================
// II. الصفحة الرئيسية (VisitationPage)
// =========================================================

class VisitationPage extends StatelessWidget {
  const VisitationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          '📝 طلب الافتقاد ',
          style: TextStyle(color: AppColors.secondaryGold),
        ),
                 centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: const _VisitationRequestForm(),
    );
  }
}

// =========================================================
// III. مكون النموذج (Form Component)
// =========================================================

class _VisitationRequestForm extends StatefulWidget {
  const _VisitationRequestForm();

  @override
  State<_VisitationRequestForm> createState() => __VisitationRequestFormState();
}

class __VisitationRequestFormState extends State<_VisitationRequestForm> {
  final _formKey = GlobalKey<FormState>();
  
  // المتغيرات لحفظ بيانات النموذج بعد الضغط على save()
  String? _name;
  String? _phone;
  String? _address;
  String? _note;

  // ⬅️ الدالة المسؤولة عن التحقق والإرسال إلى Firestore
  void _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // 1. إنشاء خريطة البيانات
      final Map<String, dynamic> requestData = {
        'name': _name,
        'phone': _phone,
        'address': _address,
        'note': _note,
        'status': 'في انتظار', // الحالة الأولية
        'timestamp': FieldValue.serverTimestamp(), // تاريخ ووقت الإرسال
        'assignedTo': null, // للحاجة في صفحة الأدمن لاحقاً
      };

      try {
        // 2. إرسال البيانات إلى مجموعة 'visitation_requests'
        await FirebaseFirestore.instance
            .collection('visitation_requests')
            .add(requestData);

        // 3. رسالة النجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرسال طلب الافتقاد بنجاح! سيتم التواصل معكم قريباً.'),
            backgroundColor: AppColors.statusVisited,
            duration: Duration(seconds: 3),
          ),
        );
        _formKey.currentState!.reset(); // تفريغ النموذج بعد النجاح
      } catch (e) {
        // 4. رسالة الخطأ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ فشل الإرسال. تحقق من تهيئة Firebase وقواعد الأمان.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'املأ النموذج وسيتم التواصل معك للافتقاد',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            _buildTextField(
              label: 'الاسم بالكامل',
              icon: Icons.person_outline,
              onSaved: (value) => _name = value,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              label: 'رقم الموبايل',
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 9) {
                  return 'من فضلك أدخل رقم موبايل صحيح.';
                }
                return null;
              },
              onSaved: (value) => _phone = value,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              label: 'العنوان بالتفصيل ',
              icon: Icons.location_on_outlined,
              onSaved: (value) => _address = value,
              maxLines: 2,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              label: 'اذا توجد ملاحظة اكتبها ',
              icon: Icons.notes,
              onSaved: (value) => _note = value,
              maxLines: 3,
            ),
            const SizedBox(height: 30),

            // زر الإرسال
            ElevatedButton.icon(
              onPressed: _submitRequest, // ⬅️ ربط الزر بدالة الإرسال
              icon: const Icon(Icons.send_rounded, color: AppColors.secondaryGold),
              label: const Text(
                'إرسال طلب الافتقاد',
                style: TextStyle(fontSize: 18, color: AppColors.secondaryGold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت مساعدة لإنشاء حقول الإدخال
  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
        filled: true,
        fillColor: AppColors.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'هذا الحقل مطلوب.';
        }
        return null;
      },
      onSaved: onSaved,
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }
}