// ignore_for_file: use_build_context_synchronously

import 'package:churchapp/aus/signup/signup_screen.dart';
import 'package:churchapp/screens/homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; // 👈 1. تم إضافة الاستيراد

// =========================================================================
// 1. Colors and Utility Components (Royal/Dark Theme)
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
// 2. Main User Login Screen (UserLoginScreen)
// =========================================================================

class UserLoginScreen extends StatefulWidget {
  static const String routeName = '/user_login';
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  bool _isFacebookLoading = false;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


// =========================================================================
  // . apple Logic (تم التعديل: حفظ التوكن)
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
      // ✅ حفظ التوكن في SharedPreferences
      final String? idToken = await user.getIdToken();
      if (idToken != null) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_token', idToken); 
          print("✅ تم حفظ التوكن (Apple) في SharedPreferences بنجاح.");
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
        Navigator.pushReplacement(
          context,
            MaterialPageRoute(builder: (context) => const HomePage()),
        );
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
  // . googel Logic (تم التعديل: حفظ التوكن)
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
      // ✅ حفظ التوكن في SharedPreferences
      final String? idToken = await user.getIdToken();
      if (idToken != null) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_token', idToken); 
          print("✅ تم حفظ التوكن (Google) في SharedPreferences بنجاح.");
      }
      
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

      if (mounted) {
        Navigator.pushReplacement(
          context,
            MaterialPageRoute(builder: (context) => const HomePage()),
        );
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
  // 3. facebooklogin Logic (تم التعديل: حفظ التوكن)
  // =========================================================================
Future<void> _signInWithFacebook() async {
  setState(() {
    _isFacebookLoading = true;
  });

  try {
    // 🔹 بدء تسجيل الدخول عبر فيسبوك
    final LoginResult result = await FacebookAuth.instance.login(
      loginBehavior: LoginBehavior.webOnly, 
    );

    if (result.status == LoginStatus.success) {
      // 🔹 إنشاء الـ Credential
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(result.accessToken!.tokenString);

      // 🔹 تسجيل الدخول باستخدام Firebase
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);

      final user = userCredential.user;

      if (user != null) {
         // ✅ حفظ التوكن في SharedPreferences
        final String? idToken = await user.getIdToken();
        if (idToken != null) {
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_token', idToken); 
            print("✅ تم حفظ التوكن (Facebook) في SharedPreferences بنجاح.");
        }
        
        // 🔹 تحقق إذا كان المستخدم موجود في Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // 💡 إنشاء مستخدم جديد في Firestore إذا لم يكن موجودًا
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email?.toLowerCase(),
            'fullName': user.displayName ?? '',
            'photoUrl': user.photoURL,
            'isAdmin': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Facebook login failed: ${result.message}")),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during Facebook login: $e")),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isFacebookLoading = false;
      });
    }
  }
}
 // =========================================================================
  // 3. Password Reset Logic
  // =========================================================================

  Future<void> _resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email!'),
            backgroundColor: AppColors.primaryColor1,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error: Failed to send reset email.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.redColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: AppColors.redColor,
          ),
        );
      }
    }
  }

  // دالة مساعدة لعرض مربع حوار نسيان كلمة المرور 
  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController emailResetController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // 🌟 تم تعديل خلفية ولون مربع الحوار
          backgroundColor: AppColors.primaryDark,
          title: const Text('Reset Password', style: TextStyle(color: AppColors.accentColor)),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: emailResetController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.whiteColor),
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: TextStyle(color: AppColors.whiteColor.withOpacity(0.6)),
                prefixIcon: const Icon(Icons.email, color: AppColors.accentColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(10),
                   borderSide: const BorderSide(color: AppColors.primaryColor1),
                ),
                focusedBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(10),
                   borderSide: const BorderSide(color: AppColors.accentColor, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: AppColors.whiteColor.withOpacity(0.7))),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  Navigator.of(context).pop(); 
                  _resetPassword(emailResetController.text.trim()); 
                }
              },
              // 🌟 زر موافق بلون ذهبي
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentColor),
              child: const Text('Send Reset Link', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // 4. Authentication Logic (تم التعديل: حفظ التوكن)
  // =========================================================================

  // Sign In function 
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final User? user = userCredential.user;

      if (user != null) {
          // ✅ حفظ التوكن في SharedPreferences بعد نجاح الدخول
          final String? idToken = await user.getIdToken();
          if (idToken != null) {
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_token', idToken); 
              print("✅ تم حفظ التوكن (Email Login) في SharedPreferences بنجاح.");
          }
        
          // تحديث/دمج بيانات المستخدم في Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email!.toLowerCase(), 
          }, SetOptions(merge: true));
      }


      // Authentication successful, navigate to the main user screen
      if (mounted) {
        // الانتقال إلى شاشة Dashboard وإزالة جميع المسارات السابقة
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
          (Route<dynamic> route) => false, 
        );      
      }
      
    } on FirebaseAuthException catch (e) {
      String message = 'Login error. Please try again.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
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
  
  // Navigate to Sign Up screen (لم يتم المساس به)
  void _goToSignUpScreen() {
    Navigator.of(context).pushNamed(UserSignUpScreen.routeName);
  }

  // =========================================================================
  // 5. Build Method (UI)
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    // 🌟 تصميم مبهر: خلفية داكنة مع تباين قوي
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          // ⚠️ افتراض مسار صورة مناسبة للكنيسة
          image: AssetImage("assets/images/church_background.png"), 
          fit: BoxFit.cover, 
          ),
      ),
      child: Stack(
        children: [
          // طبقة التعتيم الداكنة (Dark Overlay) لزيادة وضوح النص
          Container(
            color: Colors.black.withOpacity(0.7), 
          ),
          // 🛑 تغيير لون الـ Scaffold ليصبح شفافاً
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
                        'أهلاً بك مجدداً', 
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
                      //  Text(
                      //   'سجل دخولك    .',
                      //   style: TextStyle(
                      //     // 🌟 لون ذهبي خفيف
                      //     color: AppColors.accentColor.withOpacity(0.8), 
                      //     fontSize: 18, // خط أكبر قليلاً
                      //     fontWeight: FontWeight.w500,
                      //   ),
                      //   textAlign: TextAlign.center,
                      // ),
                      const SizedBox(height: 40),

                      // Email field
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

                      // Password field
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'كلمة المرور', 
                        icon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),

                      // Forgot Password button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            _showForgotPasswordDialog(context);
                          },
                          child: Text(
                            'هل نسيت كلمة المرور؟', 
                            style: TextStyle(
                              // 🌟 لون ذهبي خفيف
                              color: AppColors.accentColor.withOpacity(0.8), 
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Error message
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 15.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.redColor, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 30),

                      // Login button
                      _buildLoginButton(),


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
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ),



                      const SizedBox(height: 10),

                      // Google Login Button (بقي كما هو - أحمر)
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
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Facebook Login Button (بقي كما هو - أزرق فيسبوك)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading || _isFacebookLoading ? null : _signInWithFacebook,
                          icon: const Icon(Icons.facebook, color: Colors.white),
                          label: _isFacebookLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
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

                      
                      // Sign Up option
                      const SizedBox(height: 20),
                     Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ' اذا ليس لديك حساب ', 
                        style: TextStyle(
                          // 🌟 لون أبيض خفيف
                          color: AppColors.whiteColor.withOpacity(0.7), 
                          fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const UserSignUpScreen()), 
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
        ],
      ),
    );
  }

  // Login button widget (باستخدام التدرج اللوني)
  Widget _buildLoginButton() {
    return Container(
      decoration: BoxDecoration(
        // 🌟 تطبيق التدرج اللوني هنا (ذهبي)
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
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // لجعل التدرج يظهر
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0, // إزالة ظل الزر الأصلي
        ),
        child: _isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2))
            : const Text(
                'تسجيل الدخول', 
                style: TextStyle(
                  color: AppColors.primaryDark, // لون داكن للنص يبرز على الذهبي
                  fontSize: 18, 
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }

  // Styled text field widget (تم تحديثه لثيم Dark/Royal)
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