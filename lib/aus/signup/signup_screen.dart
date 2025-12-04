// ignore_for_file: use_build_context_synchronously

import 'package:churchapp/aus/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; 
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// =========================================================================
// 1. App Colors and Helper Components (Stunning Church Theme)
// =========================================================================

class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617);
  static const Color primaryDark = Color(0xFF0F1B3A); // أزرق داكن/كحلي للخلفيات
  static const Color primaryColor1 = Color(0xFF5B7EB3); // أزرق ملكي متوسط
  static const Color accentColor = Color(0xFFEBC76D); 
  static const List<Color> accentGradient = [Color(0xFFEBC76D), Color(0xFFB39744)]; 
  static const Color redColor = Color(0xFFEA4E79);
  static const Color fieldFillColor = Color(0xFF2E3B54); 
}

// =========================================================================
// 2. Main User Sign Up Screen (UserSignUpScreen)
// =========================================================================

class UserSignUpScreen extends StatefulWidget {
  static const String routeName = '/user_signup';
  const UserSignUpScreen({super.key});

  @override
  State<UserSignUpScreen> createState() => _UserSignUpScreenState();
}

class _UserSignUpScreenState extends State<UserSignUpScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  
  
  bool _isFacebookLoading = false;
  bool _isLoading = false;
  // تم إلغاء _errorMessage للاعتماد على SnackBar
  String? _errorMessage; // تم الإبقاء عليه فقط لمعالجة خطأ عدم تطابق كلمة المرور

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


// =========================================================================
// 3. Firebase Error Helper Function (جديد)
// =========================================================================
String _getFirebaseAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      // الأخطاء المتعلقة ببيانات الاعتماد والمستخدم
      case 'account-exists-with-different-credential':
        return 'يوجد حساب مرتبط بنفس البريد الإلكتروني. يرجى تسجيل الدخول بالطريقة الأخرى (Google/Email) لربط حسابك.'; 
      case 'weak-password':
        return 'كلمة المرور ضعيفة جدًا. يرجى اختيار كلمة مرور أقوى.';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مسجل بالفعل. يرجى تسجيل الدخول أو استخدام بريد آخر.';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صالحة.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب من قبل المسؤول.';
      case 'operation-not-allowed':
        return 'عملية المصادقة غير مسموحة. (تأكد من تفعيل المزود في Firebase).';
      case 'invalid-credential':
        return 'بيانات الاعتماد غير صالحة.';
      case 'user-not-found':
        return 'لم يتم العثور على مستخدم مسجل بهذا البريد.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة.';

      // ** الأخطاء المتعلقة بالشبكة والاتصال (لحل مشكلة ضعف/فصل النت) **
      case 'unavailable':
      case 'network-request-failed':
        return 'فشل الاتصال. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
      case 'timeout':
        return 'انتهت مهلة الاتصال بالخادم. يرجى المحاولة لاحقًا.';

      // رسالة الخطأ الافتراضية لأي خطأ آخر غير مغطى
      default:
        return 'فشل عملية المصادقة: $errorCode';
    }
}
  
// =========================================================================
// 4. Apple Logic (تم التعديل)
// =========================================================================
Future<void> _signInWithApple() async {
  setState(() => _isLoading = true);
  try {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );

    final oAuthProvider = OAuthProvider('apple.com');
    final authCredential = oAuthProvider.credential(
      idToken: credential.identityToken,
      accessToken: credential.authorizationCode,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(authCredential);
    final user = userCredential.user;

    if (user != null) {

      final String? idToken = await user.getIdToken();
    if (idToken != null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', idToken); 
        print("✅ تم حفظ التوكن (Apple) في SharedPreferences بنجاح.");
        await prefs.setBool('data_completed', false); 
        print("✅ تم حفظ التوكن وحالة البيانات (غير مكتملة) .");
    }
      
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email?.toLowerCase(),
          'fullName': credential.givenName != null
              ? '${credential.givenName} ${credential.familyName ?? ''}'
              : 'Apple User',
          'photoUrl': null,
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        // ✅ التوجيه باستخدام اسم المسار الثابت
        Navigator.pushReplacementNamed(context, '/MemberDataEntryScreen');
      }
    }
  } on FirebaseAuthException catch (e) {
      String message = _getFirebaseAuthErrorMessage(e.code);
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
          );
      }
  } catch (e) {
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تسجيل الدخول عبر Apple: ${e.toString()}')),
        );
    }
  } finally {
    setState(() => _isLoading = false);
  }
}

// =========================================================================
// 5. Google Logic (تم التعديل)
// =========================================================================
Future<void> _signInWithGoogle() async {
  setState(() => _isLoading = true);
  try {
    final googleSignIn = GoogleSignIn.instance; 
    await googleSignIn.initialize();
    
    final GoogleSignInAccount? googleUser = await googleSignIn.authenticate(
      scopeHint: ['email','profile'],
    );

    if (googleUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );


    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final String? idToken = await user.getIdToken();
    if (idToken != null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', idToken); // 👈 **هنا يتم الحفظ**
        print("✅ تم حفظ التوكن (Google) في SharedPreferences بنجاح.");
        await prefs.setBool('data_completed', false); 
        print("✅ تم حفظ التوكن وحالة البيانات (غير مكتملة) .");
    }
      // حفظ بيانات المستخدم في Firestore لو جديد
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email?.toLowerCase(),
          'fullName': user.displayName ?? 'Google User',
          'photoUrl': user.photoURL,
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // التوجيه إلى MemberDataEntryScreenPage بعد التسجيل أو تسجيل الدخول
      if (mounted) {
        // ✅ التوجيه باستخدام اسم المسار الثابت
        Navigator.pushReplacementNamed(context, '/MemberDataEntryScreen');
      }
    }


  } on FirebaseAuthException catch (e) {
      String message = _getFirebaseAuthErrorMessage(e.code);
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
          );
      }
  } catch (e) {
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تسجيل الدخول عبر Google: ${e.toString()}')),
        );
    }
  } finally {
    setState(() => _isLoading = false);
  }
}

// =========================================================================
// 6. Facebook Logic (تم التعديل)
// =========================================================================
Future<void> _signInWithFacebook() async {
  setState(() => _isFacebookLoading = true);

  try {
    await FacebookAuth.instance.logOut(); 

    final LoginResult result = await FacebookAuth.instance.login(
      loginBehavior: LoginBehavior.webOnly, 
    );


    if (result.status == LoginStatus.success) {
      final credential = FacebookAuthProvider.credential(
        result.accessToken!.token,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        final String? idToken = await user.getIdToken();
        if (idToken != null) {
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_token', idToken); 
            print("✅ تم حفظ التوكن (Facebook) في SharedPreferences بنجاح.");
            await prefs.setBool('data_completed', false); 
            print("✅ تم حفظ التوكن وحالة البيانات (غير مكتملة) .");
        }
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'email': user.email?.toLowerCase(),
            'fullName': user.displayName ?? 'Facebook User',
            'photoUrl': user.photoURL,
            'isAdmin': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          // ✅ التوجيه باستخدام اسم المسار الثابت
          Navigator.pushReplacementNamed(context, '/MemberDataEntryScreen');
        }
      }
    } else if (result.status == LoginStatus.cancelled) {
        if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم إلغاء تسجيل الدخول عبر فيسبوك")),
            );
        }
    } else {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("فشل تسجيل الدخول عبر فيسبوك: ${result.message}")),
            );
        }
    }
  } on FirebaseAuthException catch (e) {
      String message = _getFirebaseAuthErrorMessage(e.code);
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
          );
      }
  } catch (e) {
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("خطأ غير متوقع أثناء تسجيل الدخول عبر فيسبوك: ${e.toString()}")),
        );
    }
  } finally {
    setState(() => _isFacebookLoading = false);
  }
}

// =========================================================================
// 7. Sign Up Function (تم التعديل)
// =========================================================================
Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'كلمتا المرور غير متطابقتين.'; // ⚠️ هنا سنستخدم _errorMessage لتحديث UI
      });
      return;
    }
    
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null; // إعادة تعيين رسالة الخطأ
    });

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final User? user = userCredential.user;

      if (user != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email!.toLowerCase(), 
            'fullName': _nameController.text.trim(),
            'isAdmin': false, 
            'createdAt': FieldValue.serverTimestamp(),
          });

          final String? idToken = await user.getIdToken();
          if (idToken != null) {
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_token', idToken); 
              await prefs.setBool('data_completed', false); 
          }
          await user.updateDisplayName(_nameController.text.trim());
      }
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/MemberDataEntryScreen');
      }
      
    } on FirebaseAuthException catch (e) {
        String message = _getFirebaseAuthErrorMessage(e.code);
        if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
            );
        }
    } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ غير متوقع: ${e.toString()}')),
          );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


// =========================================================================
// 8. Build Method (UI) - تم إزالة منطق عرض _errorMessage من النص
// =========================================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/church_background.png"), 
          fit: BoxFit.cover,
          ),
      ),
      child: Stack(
        children: [
          Container(
            color: Colors.black.withOpacity(0.7), 
          ),
       Scaffold(
       backgroundColor: Colors.transparent, 
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Title
                  const Text(
                    'إنشاء حساب', 
                    style: TextStyle(
                      color: AppColors.whiteColor, 
                      fontSize: 34, 
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: AppColors.accentColor, blurRadius: 1)
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Motto
                  Text(
                    ' اذا اول مره تفتح التطبيق', 
                    style: TextStyle(
                      color: AppColors.accentColor.withOpacity(0.8), 
                      fontSize: 18, 
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
      
                  // Full Name Field 
                  _buildTextField(
                    controller: _nameController,
                    label: 'الاسم رباعي', 
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال الاسم الكامل';
                      }
                      
                      final names = value.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

                      if (names.length < 4) {
                        return 'يجب إدخال الاسم رباعيًا ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    label: 'البريد الإلكتروني ', 
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'مثال: name@gmail.com';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
      
                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    label: 'كلمة المرور (6 أحرف كحد أدنى)', 
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Confirm Password Field
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'تأكيد كلمة المرور', 
                    icon: Icons.check_circle_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'كلمتا المرور غير متطابقتين';
                      }
                      return null;
                    },
                  ),
      
                  // Error Message (تم إبقاؤه فقط لخطأ عدم تطابق كلمة المرور)
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.redColor, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
      
                  const SizedBox(height: 40),
      
                  // Sign Up Button 
                  _buildSignUpButton(),
      
      
      
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.accentColor, thickness: 1.2)), 
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'أو تابع بواسطة', 
                          style: TextStyle(
                            color: AppColors.accentColor.withOpacity(0.8), 
                            fontSize: 14),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.accentColor, thickness: 1.2)), 
                    ],
                  ),
                  const SizedBox(height: 10),
      
                  // Apple Login Button 
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 50, 
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithApple,
                      icon: const Icon(Icons.apple, size: 28, color: Colors.white),
                      label: const Text(
                        'المتابعة باستخدام Apple', 
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 5, 
                      ),
                    ),
                  ),
      
                  const SizedBox(height: 10),
      
                  // Google Login Button 
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 50, 
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: const Icon(
                        Icons.g_mobiledata,
                        size: 28,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'المتابعة باستخدام Google', 
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDB4437),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 5,
                      ),
                    ),
                  ),
                
                
                  const SizedBox(height: 10),
      
                  // Facebook Login Button 
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8, 
                    height: 50, 
                    child: ElevatedButton.icon(
                      onPressed: _isLoading || _isFacebookLoading ? null : _signInWithFacebook,
                      icon: const Icon(Icons.facebook, color: Colors.white),
                      label: _isFacebookLoading
                          ? const SizedBox(
                              height: 10,
                              width: 10,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'المتابعة باستخدام Facebook', 
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 5,
                        
                      ),
                    ),
                  ),
                  
                  
                  // Log In Option
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'اذا لديك حساب بالفعل', 
                        style: TextStyle(
                          color: AppColors.whiteColor.withOpacity(0.7), 
                          fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const UserLoginScreen()), 
                            (Route<dynamic> route) => false,
                          );
                        },
      
                        child: const Text(
                          'اضغط هنا', 
                          style: TextStyle(color: AppColors.primaryColor1, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
       ),
    ]),
    );
  }


// =========================================================================
// 9. Widget Helpers
// =========================================================================

  // Sign Up Button Widget 
  Widget _buildSignUpButton() {
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
        onPressed: _isLoading ? null : _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0, 
        ),
        child: _isLoading 
            ? const SizedBox(height: 10, width: 10, child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2)) 
            : const Text(
                'تسجيل عضوية جديدة', 
                style: TextStyle(
                  color: AppColors.primaryDark, 
                  fontSize: 18, 
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }

  // Styled Text Field Widget 
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.w600), 
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.accentColor), 
        labelStyle: const TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.w400), 
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.accentColor, width: 2), 
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.redColor, width: 2), 
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.redColor, width: 2),
        ),
        fillColor: AppColors.primaryDark.withOpacity(0.8), 
        filled: true,
      ),
    );
  }
}