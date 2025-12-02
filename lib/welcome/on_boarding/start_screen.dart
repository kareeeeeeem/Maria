import 'dart:ui';
import 'package:churchapp/welcome/on_boarding/on_boarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_core/firebase_core.dart'; 

// تأكد من أن تطبيقك مُهيأ لـ Firebase في ملف main.dart أولاً

class StartScreen extends StatefulWidget {
  static String routeName = "/StartScreen";

  const StartScreen({Key? key}) : super(key: key);

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeLogo;
  late Animation<double> _scaleLogo;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _fadeText;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeLogo = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.5)),
    );

    _scaleLogo = Tween<double>(begin: 0.7, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeText = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8)),
    );

    _buttonSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🔒 دالة جلب الرمز السري من Firestore
  Future<String?> _getSecretCodeFromFirebase() async {
    try {
      // 1. تحديد المسار: (Collection: 'settings', Document: 'app_config')
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('app_config')
          .get();

      if (doc.exists) {
        // 2. جلب قيمة الحقل 'secret_code'
        // تأكد أن الحقل في Firestore هو 'secret_code'
        return doc.get('secret_code') as String?;
      }
      return null;
    } on FirebaseException catch (e) {
      // ⚠️ التعامل مع الأخطاء (مثل عدم وجود اتصال بالإنترنت)
      print("Firebase Error: ${e.message}");
      return null;
    }
  }

  // 🛡️ دالة عرض مربع حوار الرمز السري (المُحسَّنة)
  void _showSecretCodeDialog() {
    final TextEditingController _codeController = TextEditingController();
    bool _isError = false;
    // لون ثابت ومناسب من تصميم الزر
    const Color primaryBlue = Color(0xFF4FC3F7); 
    const Color darkBlue = Color(0xFF1E88E5); 

    showDialog(
      context: context,
      // للحفاظ على الأمان (يجب إدخال الرمز للخروج)
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              // تصميم جمالي مميز للديالوج
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25), 
                side: const BorderSide(color: primaryBlue, width: 3), 
              ),
              elevation: 10,
              titlePadding: const EdgeInsets.only(top: 25, bottom: 5),
              title: Column(
                children: [
                  const Icon(Icons.lock_open, color: darkBlue, size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    "إدخال رمز الوصول",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Cairo",
                      fontWeight: FontWeight.w800, 
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(color: Colors.black12, height: 15, indent: 20, endIndent: 20),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "الرجاء إدخال الرمز السري لبدء استخدام التطبيق:",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    // 💡 تم التعديل للسماح بالحروف والأرقام
                    keyboardType: TextInputType.text, 
                    obscureText: true,
                    // 💡 تم إزالة قيود الأرقام والطول للسماح بإدخال حر
                    inputFormatters: [], 
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      hintText: "الرمز السري",
                      errorText: _isError ? "الرمز غير صحيح. حاول مرة أخرى." : null,
                      filled: true,
                      fillColor: Colors.blue.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20),
                      
                      // تصميم الحقل في الوضع العادي
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: _isError ? Colors.red.shade400 : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      // تصميم الحقل عند التركيز
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 2,
                        ),
                      ),
                      // تصميم الحقل الأساسي (يُستخدم كـ fallback)
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      
                      counterText: "",
                      suffixIcon: _isError ? const Icon(Icons.error, color: Colors.red) : null,
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceAround,
              actions: [
                // زر الإلغاء
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "إلغاء",
                    style: TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // زر الدخول (ElevatedButton)
                ElevatedButton( 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  ),
                  onPressed: () async { 
                    String? correctCode = await _getSecretCodeFromFirebase();
                    String enteredCode = _codeController.text;
                    
                    if (correctCode != null && enteredCode == correctCode) {
                      Navigator.of(context).pop();
                      _navigateToOnBoarding();
                    } else {
                      setState(() {
                        _isError = true;
                      });
                    }
                  },
                  child: const Text(
                    "دخول",
                    style: TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🚀 دالة الانتقال إلى الشاشة التالية
  void _navigateToOnBoarding() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OnBoardingScreen()),
        (Route<dynamic> route) => false,

    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // تم تعيين لون الخلفية هنا لضمان وجودها
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          // 🕊️ الخلفية (صورة العذراء)
          Positioned.fill(
            // يجب استبدال "eladra.png" بمسار صورة فعلية لديك في مجلد assets/images
            child: Image.asset(
              "assets/images/eladra.png",
              fit: BoxFit.cover,
              // وضع معالج خطأ في حالة عدم وجود الصورة
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.lightBlue.shade900, 
                  child: const Center(
                    child: Text("✝️ صورة الكنيسة", style: TextStyle(color: Colors.white70, fontFamily: "Cairo")),
                  ),
                );
              },
            ),
          ),

          // ✨ تدرّج شفاف لإضافة عمق ودفء
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6), // زيادة التعتيم قليلاً
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // 💫 تأثير ضبابي خفيف يعطي لمسة احترافية
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
            child: Container(color: Colors.black.withOpacity(0.1)),
          ),

          // ✝️ المحتوى المتحرك
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ✝️ العنوان الرئيسي (اسم الكنيسة)
                FadeTransition(
                  opacity: _fadeLogo,
                  child: ScaleTransition(
                    scale: _scaleLogo,
                    child: const Text(
                      "كنيسة السيده العذراء مريم\nوالقديس نيقولاوس",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Cairo",
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.6,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black87, // لون ظل أغمق
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 🕊️ النص الفرعي
                FadeTransition(
                  opacity: _fadeText,
                  child: const Text(
                    "❤️ الله محبة",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Cairo",
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // 🌈 زر البدء الجميل
                SlideTransition(
                  position: _buttonSlide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40.0, vertical: 30),
                    child: GestureDetector(
                      onTap: _showSecretCodeDialog, 
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFB3E5FC),
                              Color(0xFF81D4FA),
                              Color(0xFF4FC3F7),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4FC3F7).withOpacity(0.6), // ظل مطابق للون الزر
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "ابدأ",
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: "Cairo",
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}