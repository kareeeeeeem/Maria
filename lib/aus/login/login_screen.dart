// ignore_for_file: use_build_context_synchronously

import 'package:churchapp/aus/signup/signup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'dart:developer'; // لاستخدام log في Debug Console

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
  String? _errorMessage; // تم الإبقاء عليه فقط لعرض الأخطاء الداخلية في النموذج

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

// =========================================================================
// 3. Firebase Error Helper Function
// =========================================================================
  String _getFirebaseAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      // الأخطاء المتعلقة ببيانات الاعتماد والمستخدم
      case 'account-exists-with-different-credential':
        return 'يوجد حساب مرتبط بنفس البريد الإلكتروني. يرجى تسجيل الدخول بالطريقة الأخرى لربط حسابك.'; 
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
      case 'cancelled':
        return 'تم إلغاء عملية تسجيل الدخول من قبل المستخدم.';

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
// 4. Global Error Handler Function (جديد)
// =========================================================================

/// دالة مساعدة موحدة للتعامل مع أي استثناء في التسجيل الاجتماعي وطباعته للمطور
void _handleSocialLoginError(dynamic e, String providerName) {
    // 1. طباعة الخطأ الحقيقي للمطور في debug console
    log('❌ خطأ حقيقي في $providerName: ${e.toString()}', name: 'AUTH_ERROR');
    
    String message;
    if (e is FirebaseAuthException) {
        message = _getFirebaseAuthErrorMessage(e.code);
        log('Firebase Auth Code: ${e.code}', name: 'AUTH_ERROR'); 
    } else {
        message = 'خطأ غير متوقع أثناء تسجيل الدخول عبر $providerName. الرجاء المحاولة لاحقاً.';
    }

    // 2. عرض رسالة الخطأ للمستخدم في SnackBar
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
        );
    }
}


// =========================================================================
// 5. Conditional Navigation Helper
// =========================================================================
  Future<void> _navigateToNextScreen() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // تحقق مما إذا كان المستخدم قد أكمل إدخال البيانات
      final bool dataCompleted = prefs.getBool('data_completed') ?? false;

      final String nextRoute = dataCompleted
          ? '/HomePage'
          : '/MemberDataEntryScreen';
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, nextRoute);
      }
  }

// =========================================================================
// 6. Social Login Logic (Apple, Google, Facebook) - تم تحديث معالجة الأخطاء
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
          await prefs.setBool('data_completed', prefs.getBool('data_completed') ?? false); 
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
        // إذا كان مستخدماً جديداً، تأكد من تعيين data_completed إلى false
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('data_completed', false);
      }

      await _navigateToNextScreen();
    }
  } catch (e) {
    _handleSocialLoginError(e, 'Apple');
  } finally {
    setState(() => _isLoading = false);
  }
}

Future<void> _signInWithGoogle() async {
  setState(() => _isLoading = true);
  try {
    final googleSignIn = GoogleSignIn.instance; 
    await googleSignIn.initialize(); 
    
    final GoogleSignInAccount? googleUser = await googleSignIn.authenticate(
      scopeHint: ['email','profile'],
    );

    if (googleUser == null) {
      // المستخدم قام بإلغاء العملية يدوياً
      _handleSocialLoginError( FirebaseAuthException(code: 'cancelled', message: 'User cancelled Google sign-in'), 'Google');
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
          await prefs.setString('user_token', idToken); 
          await prefs.setBool('data_completed', prefs.getBool('data_completed') ?? false); 
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
        // إذا كان مستخدماً جديداً، تأكد من تعيين data_completed إلى false
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('data_completed', false);
      }

      await _navigateToNextScreen();
    }

  } catch (e) {
    _handleSocialLoginError(e, 'Google');
  } finally {
    setState(() => _isLoading = false);
  }
}

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
            await prefs.setBool('data_completed', prefs.getBool('data_completed') ?? false); 
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
          // إذا كان مستخدماً جديداً، تأكد من تعيين data_completed إلى false
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('data_completed', false);
        }

        await _navigateToNextScreen();

      }
    } else if (result.status == LoginStatus.cancelled) {
        // التعامل مع الإلغاء بنفس طريقة الخطأ لعرض رسالة للمستخدم
        _handleSocialLoginError( FirebaseAuthException(code: 'cancelled', message: 'User cancelled Facebook sign-in'), 'Facebook');
    } else {
        // أي فشل آخر في عملية تسجيل الدخول عبر الفيسبوك نفسه
        _handleSocialLoginError(Exception("Facebook Login Failed: ${result.message}"), 'Facebook');
    }
  } catch (e) {
    _handleSocialLoginError(e, 'Facebook');
  } finally {
    setState(() => _isFacebookLoading = false);
  }
}

  // =========================================================================
  // 7. Password Reset Logic - تم تحديث معالجة الأخطاء
  // =========================================================================

  Future<void> _resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني!'),
            backgroundColor: AppColors.primaryColor1,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      log('❌ خطأ Firebase في إعادة تعيين كلمة المرور: ${e.toString()}', name: 'PASSWORD_RESET_ERROR');
      String message = 'حدث خطأ: فشل إرسال بريد إعادة التعيين.';
      if (e.code == 'user-not-found') {
        message = 'لا يوجد مستخدم مسجل بهذا البريد.';
      } else if (e.code == 'invalid-email') {
        message = 'صيغة البريد الإلكتروني غير صالحة.';
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
      log('❌ خطأ غير متوقع في إعادة تعيين كلمة المرور: ${e.toString()}', name: 'PASSWORD_RESET_ERROR');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: ${e.toString()}'),
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
          backgroundColor: AppColors.primaryDark,
          title: const Text('إعادة تعيين كلمة المرور', style: TextStyle(color: AppColors.accentColor)),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: emailResetController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.whiteColor),
              decoration: InputDecoration(
                hintText: 'أدخل بريدك الإلكتروني',
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
                  return 'الرجاء إدخال بريد إلكتروني صالح';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء', style: TextStyle(color: AppColors.whiteColor.withOpacity(0.7))),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  Navigator.of(context).pop(); 
                  _resetPassword(emailResetController.text.trim()); 
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentColor),
              child: const Text('إرسال رابط إعادة التعيين', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // 8. Email/Password Authentication Logic - تم تحديث معالجة الأخطاء
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
            await prefs.setBool('data_completed', prefs.getBool('data_completed') ?? false); 
        }
        
          // تحديث/دمج بيانات المستخدم في Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email!.toLowerCase(), 
          }, SetOptions(merge: true));
      }

      // التوجيه المشروط
      await _navigateToNextScreen();
      
    } on FirebaseAuthException catch (e) {
      // طباعة الخطأ الحقيقي للمطور
      log('❌ خطأ Firebase حقيقي في تسجيل الدخول: ${e.toString()}', name: 'EMAIL_LOGIN_ERROR');
      
      String message = _getFirebaseAuthErrorMessage(e.code);
      if (mounted) {
         // عرض الخطأ للمستخدم في SnackBar بدلاً من _errorMessage
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
         );
      }
      
    } catch (e) {
      log('❌ خطأ غير متوقع في تسجيل الدخول: ${e.toString()}', name: 'EMAIL_LOGIN_ERROR');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ غير متوقع: ${e.toString()}')),
        );
      }
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
  // 9. Build Method (UI)
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
                        'أهلاً بك مجدداً', 
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
                        'سجل دخولك الآن للبدء.',
                        style: TextStyle(
                          color: AppColors.accentColor.withOpacity(0.8), 
                          fontSize: 18, 
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
                              color: AppColors.accentColor.withOpacity(0.8), 
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Error message (تم إزالة استخدامه في الـ _login)
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
                            minimumSize: const Size(double.infinity, 50),
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
                            minimumSize: const Size(double.infinity, 50),
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

  // =========================================================================
  // 10. Widget Helpers
  // =========================================================================

  // Login button widget (باستخدام التدرج اللوني)
  Widget _buildLoginButton() {
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
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0, 
        ),
        child: _isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2))
            : const Text(
                'تسجيل الدخول', 
                style: TextStyle(
                  color: AppColors.primaryDark, 
                  fontSize: 18, 
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }

  // Styled text field widget (تم إكماله وتحديثه لثيم Dark/Royal)
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