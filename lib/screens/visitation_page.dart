// lib/screens/visitation_page.dart (الكود المصحح والنهائي)

import 'package:flutter/material.dart';

// =========================================================
// I. كلاس نموذج البيانات (Models) والثوابت (Constants)
// =========================================================

// 1. نموذج طلب الافتقاد
class VisitationRequest {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String note;
  String status; // 'في انتظار', 'تم التواصل', 'تمت الزيارة'

  VisitationRequest({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.note,
    this.status = 'في انتظار',
  });
}

// 2. نموذج الخادم / المتطوع (تم إضافة const Constructor)
class Servant {
  final String id;
  final String name;
  final String role; 
  final String contact; 

  // ⬅️ التصحيح: إضافة const هنا
  const Servant({
    required this.id,
    required this.name,
    required this.role,
    required this.contact,
  });
}

// 3. الألوان والثوابت
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
}

// =========================================================
// 4. البيانات الوهمية (Dummy Data) - تم تصحيحها لـ const
// =========================================================

// ⬅️ التصحيح: استخدام const هنا وفي إنشاء كل كائن
const List<Servant> _dummyServants = [
  const Servant(id: 's1', name: 'أ. مينا عماد', role: 'مسؤول الافتقاد العام', contact: '012xxxxxxx'),
  const Servant(id: 's2', name: 'م. سارة جرجس', role: 'خادمة منطقة أ', contact: '010xxxxxxx'),
  const Servant(id: 's3', name: 'أ. بيشوي نبيل', role: 'خادم زيارات المرضى', contact: '011xxxxxxx'),
  const Servant(id: 's4', name: 'فريق إعداد المعمدين', role: 'مسؤول لجنة التعليم', contact: '015xxxxxxx'),
];

// =========================================================
// II. الصفحة الرئيسية (VisitationPage)
// =========================================================

class VisitationPage extends StatelessWidget {
  const VisitationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title:const Center (child:  Text('🤝 الافتقاد والخدمة          ', style: TextStyle(color: AppColors.secondaryGold))),
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'طلب افتقاد', icon: Icon(Icons.home_work_rounded)),
              Tab(text: 'فريق الخدمة', icon: Icon(Icons.people_alt_rounded)),
            ],
            labelColor: AppColors.secondaryGold,
            unselectedLabelColor: Colors.white70,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.secondaryGold, width: 3)),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            // 1. نموذج طلب الافتقاد
            _VisitationRequestForm(),
            // 2. قائمة الخدام والمتطوعين
            _ServantsList(servants: _dummyServants),
          ],
        ),
      ),
    );
  }
}


// =========================================================
// III. مكونات الواجهة (UI Components)
// =========================================================

// ---------------------------------------------------------
// 1. نموذج طلب افتقاد (_VisitationRequestForm)
// ---------------------------------------------------------

class _VisitationRequestForm extends StatefulWidget {
  const _VisitationRequestForm();

  @override
  State<_VisitationRequestForm> createState() => __VisitationRequestFormState();
}

class __VisitationRequestFormState extends State<_VisitationRequestForm> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _phone;
  String? _address;
  String? _note;

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // TODO: هنا يتم إرسال البيانات إلى Firestore 
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إرسال طلب الافتقاد بنجاح! سيتم التواصل معكم قريباً.'),
          backgroundColor: AppColors.statusVisited,
          duration: Duration(seconds: 3),
        ),
      );
      _formKey.currentState!.reset();
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
              'املأ النموذج وسيقوم خادم الافتقاد بالتواصل معك.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // حقل الاسم
            _buildTextField(
              label: 'الاسم بالكامل',
              icon: Icons.person_outline,
              onSaved: (value) => _name = value,
            ),
            const SizedBox(height: 15),

            // حقل رقم الموبايل
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

            // حقل العنوان
            _buildTextField(
              label: 'العنوان بالتفصيل (للتيسير على الخادم)',
              icon: Icons.location_on_outlined,
              onSaved: (value) => _address = value,
              maxLines: 2,
            ),
            const SizedBox(height: 15),

            // حقل الملاحظة
            _buildTextField(
              label: 'ملاحظة بسيطة (مثل: زيارة مريض، استفسار روحي..)',
              icon: Icons.notes,
              onSaved: (value) => _note = value,
              maxLines: 3,
            ),
            const SizedBox(height: 30),

            // زر الإرسال
            ElevatedButton.icon(
              onPressed: _submitRequest,
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


// ---------------------------------------------------------
// 2. قائمة الخدام / المتطوعين (_ServantsList)
// ---------------------------------------------------------

class _ServantsList extends StatelessWidget {
  final List<Servant> servants;
  
  const _ServantsList({required this.servants});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12.0),
      children: [
        // أولاً: قائمة الخدام
        const Text(
          '👥 فريق الخدمة والافتقاد',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
          textAlign: TextAlign.right,
        ),
        const Divider(color: AppColors.primaryBlue),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), 
          itemCount: servants.length,
          itemBuilder: (context, index) {
            final servant = servants[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondaryGold,
                  child: Icon(Icons.star, color: AppColors.primaryBlue),
                ),
                title: Text(servant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(servant.role, style: const TextStyle(color: AppColors.textSecondary)),
                trailing: IconButton(
                  icon: const Icon(Icons.call, color: AppColors.statusVisited),
                  onPressed: () {
                    // TODO: تنفيذ دالة الاتصال (مثل launchUrl)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('جاري الاتصال بـ ${servant.contact}')),
                    );
                  },
                ),
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('معلومات الاتصال: ${servant.contact}')),
                   );
                }
              ),
            );
          },
        ),

        const SizedBox(height: 25),
        
        // ثانياً: تقويم الزيارات (كـ ExpansionTile placeholder)
        const Text(
          '📅 تقويم زيارات الخدمة',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
          textAlign: TextAlign.right,
        ),
        const Divider(color: AppColors.primaryBlue),

        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: const ExpansionTile(
            title: Text('اضغط لعرض جدول الاجتماعات/الزيارات القادمة', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            collapsedIconColor: AppColors.primaryBlue,
            iconColor: AppColors.statusVisited,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'التاريخ غير متوفر بعد. هنا سيتم عرض جدول زمني منظم لزيارات فرق الخدمة واجتماعاتهم (مثلاً: اليوم، المهمة، المنطقة).',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}