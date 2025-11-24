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
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }




// =========================================================================
  // . apple Logic (تم التعديل)
  // =========================================================================
Future<void> _signInWithApple() async {
  setState(() => _isLoading = true);
  try {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );

    // إنشاء Credential لتسجيل الدخول إلى Firebase
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
    }
      // تحقق من وجود المستخدم في Firestore
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
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Apple Sign-In failed: $e')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

// =========================================================================
  // . googel Logic (تم التعديل)
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


  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Google Sign-In failed: $e')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  
// =========================================================================
  // 3. facebooklogin Logic (تم التعديل)
  // =========================================================================
Future<void> _signInWithFacebook() async {
  setState(() => _isFacebookLoading = true);

  try {
    await FacebookAuth.instance.logOut(); // تأمين الجلسة القديمة

    final LoginResult result = await FacebookAuth.instance.login(
      loginBehavior: LoginBehavior.webOnly, 
    );


    if (result.status == LoginStatus.success) {
      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Facebook login cancelled")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Facebook login failed: ${result.message}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error during Facebook login: $e")),
    );
  } finally {
    setState(() => _isFacebookLoading = false);
  }
}

  

  // Sign Up Function (صحيحة بالفعل)
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final User? user = userCredential.user;

      if (user != null) {
          // 2. حفظ بيانات المستخدم في Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email!.toLowerCase(), 
            'fullName': _nameController.text.trim(),
            'isAdmin': false, 
            'createdAt': FieldValue.serverTimestamp(),
          });


          final String? idToken = await user.getIdToken();
    if (idToken != null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', idToken); // 👈 **هنا يتم الحفظ**
        print("✅ تم حفظ التوكن في SharedPreferences بنجاح.");
    }
          


          // Optional Step: Update User's Display Name
          await user.updateDisplayName(_nameController.text.trim());
      }
      

      // Authentication successful, navigate to the main screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/MemberDataEntryScreen');
      }
      
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to create account. Please try again.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
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
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          // ⚠️ افتراض مسار صورة مناسبة للكنيسة
          image: AssetImage("assets/images/church_background.png"), 
          fit: BoxFit.cover, // لتغطية كامل الشاشة
          ),
      ),
      child: Stack(
        children: [
          // طبقة التعتيم الداكنة (Dark Overlay) لزيادة وضوح النص
          Container(
            color: Colors.black.withOpacity(0.7), 
          ),
       Scaffold(
       // ✅ لجعل الخلفية تظهر من خلال Scaffold
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
                      // 🌟 لون أبيض لامع على خلفية داكنة
                      color: AppColors.whiteColor, 
                      fontSize: 34, // خط أكبر
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
                    'لتكون عضواً في تطبيق الكنيسة', 
                    style: TextStyle(
                      // 🌟 لون ذهبي خفيف
                      color: AppColors.accentColor.withOpacity(0.8), 
                      fontSize: 18, // خط أكبر قليلاً
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
      
                  // Full Name Field
                  _buildTextField(
                    controller: _nameController,
                    label: 'الاسم الكامل', 
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال الاسم الكامل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    label: 'البريد الإلكتروني', 
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'الرجاء إدخال بريد إلكتروني صالح';
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
      
                  const SizedBox(height: 40),
      
                  // Sign Up Button (CTA - مع تدرج لوني)
                  _buildSignUpButton(),
      
      
      
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // 🌟 Divider بلون ذهبي
                      const Expanded(child: Divider(color: AppColors.accentColor, thickness: 1.2)), 
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'أو تابع بواسطة', 
                          style: TextStyle(
                            // 🌟 لون ذهبي خفيف
                            color: AppColors.accentColor.withOpacity(0.8), 
                            fontSize: 14),
                        ),
                      ),
                      // 🌟 Divider بلون ذهبي
                      const Expanded(child: Divider(color: AppColors.accentColor, thickness: 1.2)), 
                    ],
                  ),
                  const SizedBox(height: 10),
      
                  // Apple Login Button (بقي كما هو - أسود)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 50, // ارتفاع أكبر قليلاً
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
                        elevation: 5, // ظل أوضح
                      ),
                    ),
                  ),
      
                  const SizedBox(height: 10),
      
                  // Google Login Button (بقي كما هو - أحمر)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 50, // ارتفاع أكبر قليلاً
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
      
                  // Facebook Login Button (بقي كما هو - أزرق فيسبوك)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8, 
                    height: 50, // ارتفاع أكبر قليلاً
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
                        backgroundColor: const Color(0xFF1877F2), // Facebook Blue
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
                          // 🌟 لون أبيض خفيف
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
                          // 🌟 لون أساسي جديد
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






  // Sign Up Button Widget (باستخدام تدرج لوني)
  Widget _buildSignUpButton() {
    return Container(
      decoration: BoxDecoration(
        // 🌟 تطبيق التدرج اللوني هنا
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
          backgroundColor: Colors.transparent, // لجعل التدرج يظهر
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0, // إزالة ظل الزر الأصلي
        ),
        child: _isLoading 
            ? const SizedBox(height: 10, width: 10, child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2)) // لون الداكن للخلفية
            : const Text(
                'تسجيل عضوية جديدة', 
                style: TextStyle(
                  color: AppColors.primaryDark, // لون داكن للنص يبرز على الذهبي
                  fontSize: 18, 
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }

  // Styled Text Field Widget (Updated for Dark/Royal Theme)
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
      // 🌟 النص المدخل أصبح بلون أبيض بارز
      style: const TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.w600), 
      decoration: InputDecoration(
        labelText: label,
        // 🌟 أيقونة بلون ذهبي بارز
        prefixIcon: Icon(icon, color: AppColors.accentColor), 
        // 🌟 الـ Label باللون الأبيض الخفيف
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
          // 🌟 حدود واضحة بلون ذهبي
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
        // 🌟 خلفية الحقول داكنة وأكثر وضوحاً
        fillColor: AppColors.primaryDark.withOpacity(0.8), 
        filled: true,
      ),
    );
  }
}