// ignore_for_self_referencing_package_names
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:flutter/services.dart';
// 🔥 الإضافات الجديدة للحفظ التلقائي
import 'dart:io'; 
import 'package:path_provider/path_provider.dart';
// ------------------------------------
import 'package:url_launcher/url_launcher.dart'; 
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 


// =========================================================================
// 0. General Variables (WhatsApp Target Number)
// =========================================================================

// 📞 Target number for the responsible employee (Reception)
const String _RECEPTION_WHATSAPP_NUMBER = "966500000000"; // Dummy number, please change

// =========================================================================
// 1. Color Definitions (AppColors)
// =========================================================================

class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617); // Dark Background
  static const Color darkGrayColor = Color(0xFFC0C0C0); // Lighter Gray for text on dark bg
  static const Color primaryColor1 = Color(0xFF92A3FD); // Primary Blue/Lavender
  static const Color accentColor = Color(0xFF00C4CC); // Bright Mint/Tiffany Green
  static const Color cardBackgroundColor = Color(0xFF222222); // Dark background for dialogs & inputs
  static const Color redColor = Color(0xFFEA4E79); // Red for Alerts
  
  static const List<Color> primaryG = [
    Color(0xFF92A3FD), 
    Color(0xFF00C4CC), 
  ];
}

// =========================================================================
// 2. Placeholder Screens (Dashboard & Goal Screen)
// =========================================================================

class DashboardScreen extends StatelessWidget {
  static const String routeName = "/home";
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.blackColor,
        appBar: AppBar(
            backgroundColor: AppColors.blackColor,
            title: const Text("Control Panel", style: TextStyle(color: AppColors.whiteColor))), 
        body: const Center(
            child: Text("Subscription confirmed successfully and proceeding to the next page. (Dashboard)", 
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.whiteColor, fontSize: 18))),
    );
  }
}

class YourGoalScreen extends StatelessWidget {
  static const String routeName = "/YourGoalScreen";
  const YourGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.blackColor,
        appBar: AppBar(
             backgroundColor: AppColors.blackColor,
             title: const Text("Goal Setting", style: TextStyle(color: AppColors.whiteColor))),
        body: const Center(child: Text("Welcome! Your profile is complete.", style: TextStyle(color: AppColors.whiteColor))),
    );
  }
}


// =========================================================================
// 3. RoundTextField (Input Field)
// =========================================================================

class RoundTextField extends StatelessWidget {
  final String hintText;
  final String icon;
  final TextInputType textInputType;
  final TextEditingController? controller;
  final bool isReadOnly;
  final String? Function(String?)? validator;

  const RoundTextField({
    Key? key,
    required this.hintText,
    required this.icon,
    required this.textInputType,
    this.controller,
    this.isReadOnly = false,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor, 
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: textInputType,
        readOnly: isReadOnly,
        validator: validator,
        inputFormatters: textInputType == TextInputType.number ? 
          [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))] : null,
        style: const TextStyle(color: AppColors.whiteColor, fontSize: 14), 
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 0),
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.darkGrayColor, fontSize: 12), 
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Image.network(
              icon.contains('calendar') ? "https://placehold.co/20x20/92A3FD/1D1617?text=C" :
              icon.contains('weight') ? "https://placehold.co/20x20/00C4CC/1D1617?text=W" : 
              "https://placehold.co/20x20/C0C0C0/1D1617?text=I",
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              color: AppColors.primaryColor1, 
              errorBuilder: (context, error, stackTrace) => Icon(
                icon.contains('calendar') ? Icons.calendar_today : 
                icon.contains('weight') ? Icons.scale : Icons.swap_horiz,
                color: AppColors.primaryColor1,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// =========================================================================
// 4. Complete Profile Screen
// =========================================================================

class CompleteProfileScreen extends StatefulWidget {
  static String routeName = "/CompleteProfileScreen";
  const CompleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); 
  final TextEditingController _dobTextController = TextEditingController();
  
  DateTime? _selectedDateOfBirth;
  String? _selectedGender; 
  bool _isLoading = false; 
  bool _termsAgreed = false; 
  
  final List<String> _genders = ["Male", "Female", "Other"]; 

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _dobTextController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  int calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
  
  // BMI calculation function
  String calculateBMI(double weightKg, double heightCm) {
    if (heightCm <= 0) return '0.00';
    final heightM = heightCm / 100.0; 
    final bmi = weightKg / (heightM * heightM);
    return bmi.toStringAsFixed(2);
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: color,
        duration: const Duration(seconds: 5), 
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)), 
      firstDate: DateTime(1900), 
      lastDate: DateTime.now(), 
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentColor,
              onPrimary: AppColors.whiteColor, 
              surface: AppColors.cardBackgroundColor, 
              onSurface: AppColors.whiteColor, 
            ), dialogTheme: const DialogThemeData(backgroundColor: AppColors.cardBackgroundColor),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobTextController.text = DateFormat('yyyy-MM-dd').format(picked); 
      });
    }
  }

  // =========================================================================
  // 💾 Function to save member data in Firestore
  // =========================================================================
  Future<bool> _saveUserProfile(String name, int age, String gender, double height, double weight, String bmi) async {
    try {
        final docData = {
          'name': name,
          'age': age,
          'gender': gender,
          'height_cm': height,
          'weight_kg': weight,
          'bmi': bmi,
          'registration_date': FieldValue.serverTimestamp(),
        };
        
        await FirebaseFirestore.instance.collection('memberships').add(docData);
        _showSnackbar('Membership saved successfully✅', const Color.fromARGB(255, 0, 204, 0));
        return true;

    } on FirebaseException catch (e) {
        print("Firebase Error saving profile: $e");
        _showSnackbar('❌ Failed to save data to Firestore: ${e.code}', AppColors.redColor);
        return false;
    } catch (e) {
        print("General Error saving profile: $e");
        _showSnackbar('❌ Failed to save data to Firestore.', AppColors.redColor);
        return false;
    }
  }

  // =========================================================================
  // 📞 Function to share PDF via WhatsApp (Modified to Save Automatically)
  // =========================================================================
  Future<void> _sharePdfViaWhatsApp(String name, String dob, String gender, int age, String height, String weight, String bmi) async {
    try {
      final userData = {
        'name': name,
        'gender': gender,
        'dob': dob,
        'age': age,
        'height': height,
        'weight': weight,
        'bmi': bmi, 
      };

      // 1. Generate PDF file in memory
      final pdfBytes = await _generatePdfReport(userData);

      final String filename = 'Subscription_${name}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      // 🔥 التعديل: الحفظ التلقائي إلى مجلد المستندات الخاص بالتطبيق
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String savePath = '${appDocDir.path}/$filename';
      final File pdfFile = File(savePath);
      await pdfFile.writeAsBytes(pdfBytes); 
      // تم حفظ الملف تلقائياً هنا!

      // 2. Prepare the automatic WhatsApp message
      final String textMessage = 
          "📄 *New Membership Subscription Request (Automated)*\n\n"
          "Name: $name\n"
          "Calculated BMI: $bmi\n"
          "----------------------------------\n"
          "Attached is the complete subscription form (PDF) for the new member. Please review and print it.\n\n"
          "Reminder, the Reception number is: *$_RECEPTION_WHATSAPP_NUMBER* (Please make sure to send the file to this number when the share list appears).";

      // 3. Use Printing.sharePdf لفتح نافذة المشاركة (باستخدام البايتات)
      // ملاحظة: على الرغم من أننا حفظناه، فإن Printing.sharePdf يعمل بكفاءة أكبر مع البايتات.
      await Printing.sharePdf(
        bytes: pdfBytes, 
        filename: filename,
        subject: "New Membership Subscription Form",
        body: textMessage,
      );

      // 4. Success message and transition
      // ✅ رسالة تأكيد الحفظ التلقائي ومكان وجود الملف
      _showSnackbar('✅ تم حفظ الملف تلقائياً على الهاتف في "ملفات التطبيق" باسم: $filename. يرجى الآن اختيار واتساب لإرسال النموذج.', AppColors.accentColor);
      
      await Future.delayed(const Duration(milliseconds: 500)); 

      if (mounted) {
         Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
      }
      
    } catch (e) {
      print("Error generating, saving, or sharing PDF: $e");
      if (mounted) {
        _showSnackbar('❌ فشل في إنشاء أو حفظ الملف. تأكد من إضافة حزمة path_provider.', AppColors.redColor);
      }
    }
  }

  // =========================================================================
  // 5. Validation and Submission Function (submitAndContinue)
  // =========================================================================
  void submitAndContinue() async {
    if (!_formKey.currentState!.validate() || _selectedGender == null || _selectedDateOfBirth == null || !_termsAgreed) {
      if (!_termsAgreed) {
         _showSnackbar('You must agree to the Terms and Conditions.', AppColors.redColor);
      } else {
         _showSnackbar('Please complete all required fields.', AppColors.redColor);
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
        final name = _nameController.text;
        final dobString = _dobTextController.text;
        final gender = _selectedGender!;
        
        final heightCm = double.tryParse(_heightController.text) ?? 0.0;
        final weightKg = double.tryParse(_weightController.text) ?? 0.0;
        final age = calculateAge(_selectedDateOfBirth!);
        final bmi = calculateBMI(weightKg, heightCm); 

        final saved = await _saveUserProfile(name, age, gender, heightCm, weightKg, bmi);
        
        if (!saved) {
           _showSnackbar('❌ Operation halted. Failed to save data.', AppColors.redColor);
           return;
        }

        await _sharePdfViaWhatsApp(name, dobString, gender, age, heightCm.toString(), weightKg.toString(), bmi);

    } finally {
        if (mounted) {
           setState(() {
             _isLoading = false;
           });
        }
    }
  }

  // =========================================================================
  // 📄 PDF Generation Logic (Using Courier Font for Arabic Support)
  // =========================================================================
  Future<Uint8List> _generatePdfReport(Map<String, dynamic> userData) async {
      final pdf = pw.Document();

      final pw.Font bodyFont = pw.Font.courier(); 
      final pw.Font font = pw.Font.courierBold(); 
      
      final String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(userData['dob']));

      final pageTheme = pw.PageTheme(
        textDirection: pw.TextDirection.ltr,
        margin: const pw.EdgeInsets.all(30),
        pageFormat: PdfPageFormat.a4, 
      );

      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (pw.Context context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Gym Membership Subscription Form', 
                    style: pw.TextStyle(font: font, fontSize: 24, color: PdfColor.fromInt(AppColors.primaryColor1.value))),
                  
                  pw.SizedBox(height: 25),
                  
                  // Member Information
                  _buildPdfDataRow(bodyFont, 'Full Name', userData['name']!),
                  _buildPdfDataRow(bodyFont, 'Gender', userData['gender']!),
                  _buildPdfDataRow(bodyFont, 'Date of Birth', formattedDate),
                  _buildPdfDataRow(bodyFont, 'Age', '${userData['age']} years'),
                  pw.Divider(height: 20, borderStyle: pw.BorderStyle.dashed),
                  _buildPdfDataRow(bodyFont, 'Height', '${userData['height']} cm'),
                  _buildPdfDataRow(bodyFont, 'Weight', '${userData['weight']} kg'),
                  _buildPdfDataRow(bodyFont, 'Body Mass Index (BMI)', userData['bmi']!),
                  
                  pw.SizedBox(height: 40),
                  
                  // Terms and Signature Section
                  pw.Text('I, the undersigned, confirm the above data is correct and agree to the club\'s terms and conditions.', 
                    style: pw.TextStyle(font: bodyFont, fontSize: 12)),
                  
                  pw.SizedBox(height: 50),
                  
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Employee Signature:', style: pw.TextStyle(font: bodyFont)), 
                      pw.Text('Member Signature:', style: pw.TextStyle(font: bodyFont)), 
                    ]
                  ),
                ],
              ),
            );
          },
        ),
      );

      return pdf.save();
  }

  // Helper function to create a data row in PDF 
  pw.Widget _buildPdfDataRow(pw.Font font, String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('$label:', style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)), 
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 14)), 
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.blackColor, 
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(right: 15,left: 15, top: 25, bottom: 25),
            child: Form( 
              key: _formKey,
              child: Column(
                children: [
                  Image.network(
                      "https://placehold.co/${media.width * 0.75}x250/92A3FD/1D1617?text=Subscription+Form",
                      width: media.width * 0.75,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_pin_circle, size: 100, color: AppColors.primaryColor1),
                  ),
                  const SizedBox(height: 15),
                 const Center(
                    child:  Text(
                      "Membership Subscription ", 
                      style: TextStyle(
                        color: AppColors.whiteColor, 
                        fontSize: 24, 
                        fontWeight: FontWeight.w700
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Please fill in all details to generate and send the subscription form.", 
                    style: TextStyle(
                      color: AppColors.darkGrayColor, 
                      fontSize: 14, 
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Name Field 
                  RoundTextField(
                    hintText: "Full Name", 
                    icon: "https://placehold.co/20x20/C0C0C0/1D1617?text=N",
                    textInputType: TextInputType.name,
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name.'; 
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Gender Selection Field
                  Container(
                    decoration: BoxDecoration(
                        color: AppColors.cardBackgroundColor, 
                        borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      children: [
                        Container(
                            alignment: Alignment.center,
                            width: 50,
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Image.network(
                              "https://placehold.co/20x20/00C4CC/1D1617?text=G",
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              color: AppColors.accentColor, 
                               errorBuilder: (context, error, stackTrace) => const Icon(Icons.wc, size: 20, color: AppColors.accentColor),
                            )),
                        Expanded(child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGender, 
                            dropdownColor: AppColors.cardBackgroundColor, 
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.darkGrayColor),
                            items: _genders.map((name) => DropdownMenuItem(value:name,child: Text(
                              name,
                              style: const TextStyle(color: AppColors.whiteColor,fontSize: 14), 
                            ))).toList(), 
                            onChanged: (value) {
                               setState(() {
                                 _selectedGender = value;
                               });
                            },
                            isExpanded: true,
                            hint: const Text("Select Gender",style: TextStyle(color: AppColors.darkGrayColor,fontSize: 14)), 
                          ),
                        )),
                        const SizedBox(width: 8)
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Date of Birth Field (using Date Picker)
                  InkWell(
                    onTap: _isLoading ? null : () => _selectDate(context),
                    child: AbsorbPointer( 
                      child: RoundTextField(
                        hintText: "Date of Birth (Day/Month/Year)", 
                        icon: "assets/icons/calendar_icon.png",
                        textInputType: TextInputType.text,
                        controller: _dobTextController,
                        isReadOnly: true,
                        validator: (value) {
                           if (_selectedDateOfBirth == null) {
                            return 'Please select your date of birth.'; 
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Weight Field
                  RoundTextField(
                    hintText: "Weight (kg)", 
                    icon: "assets/icons/weight_icon.png",
                    textInputType: TextInputType.number,
                    controller: _weightController,
                    validator: (value) {
                      if (double.tryParse(value ?? '') == null || (double.tryParse(value!) ?? 0) <= 0) {
                        return 'Please enter a valid weight.'; 
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Height Field
                  RoundTextField(
                    hintText: "Height (cm)", 
                    icon: "assets/icons/swap_icon.png",
                    textInputType: TextInputType.number,
                    controller: _heightController,
                    validator: (value) {
                      if (double.tryParse(value ?? '') == null || (double.tryParse(value!) ?? 0) <= 0) {
                        return 'Please enter a valid height.'; 
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 25),
                  
                  // Terms and Conditions Checkbox
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start, 
                      children: [
                         Checkbox(
                          value: _termsAgreed,
                          onChanged: (bool? newValue) {
                            setState(() {
                              _termsAgreed = newValue ?? false;
                            });
                          },
                          activeColor: AppColors.accentColor, 
                          checkColor: AppColors.blackColor, 
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _termsAgreed = !_termsAgreed;
                              });
                            },
                            child: const Text(
                              "I agree to the Terms, Conditions, and Privacy Policy", 
                              textAlign: TextAlign.left, 
                              style: TextStyle(
                                color: AppColors.whiteColor,
                                fontSize: 13,
                                decoration: TextDecoration.underline, 
                                decorationColor: AppColors.whiteColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Button to submit data via WhatsApp (Changed Text)
                  SizedBox(
                    width: media.width,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: AppColors.primaryG,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor1.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : submitAndContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, 
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: _isLoading 
                          ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, color: AppColors.whiteColor),
                                SizedBox(width: 8),
                                Text(
                                  "Submit and Continue", 
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}