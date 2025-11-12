import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // نحتاجها لحفظ بيانات المستخدم الجديد

// يُفضل استخدام هذه المكتبات لأنها جزء أساسي من إدارة حالة التطبيق
import 'dart:async'; 

class AuthService {
  // إنشاء مُتغيرات الوصول لخدمات Firebase و Google
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ❌ الخطأ كان هنا: final GoogleSignIn _googleSignIn = GoogleSignIn();
  // ✅ التصحيح: يجب استخدام .instance للوصول للمثيل الواحد.
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance; 
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // للتعامل مع قاعدة بيانات Firestore
  
  // مفتاح ثابت لتخزين مُعرّف المستخدم محلياً
  static const String _userTokenKey = 'user_token';

  // ----------------------------------------------------------------------
  // 1. تسجيل الدخول باستخدام جوجل (Google Sign-In) - مُحدّث
  // ----------------------------------------------------------------------

  /// يُسجل دخول المستخدم عبر جوجل ويربطه بمصادقة Firebase.
  Future<User?> signInWithGoogle() async {
    try {
      // 1. طلب تسجيل الدخول من جوجل
      // 💡 ملاحظة: لا حاجة لاستدعاء GoogleSignIn.instance مرة أخرى هنا.
      // 💡 ولا حاجة لاستدعاء .initialize() هنا، حيث يتم عادةً مرة واحدة في التهيئة أو قبل الاستدعاء مباشرةً.
      // نستخدم مباشرةً المثيل الذي تم تعريفه في بداية الكلاس: _googleSignIn.
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email','profile'], // طلب الصلاحيات
      );

      if (googleUser == null) {
        // المستخدم ألغى عملية تسجيل الدخول
        return null; 
      }

      // 2. الحصول على تفاصيل التصديق (Authentication Details)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. إنشاء بيانات اعتماد Firebase (Auth Credential)
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. تسجيل الدخول الفعلي في Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // 5. حفظ بيانات المستخدم في Firestore لو جديد (نفس منطقك)
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email?.toLowerCase(),
            'fullName': user.displayName ?? 'Google User',
            'photoUrl': user.photoURL,
            'isAdmin': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        
        // 6. حفظ مُعرّف المستخدم (UID) محلياً 
        await _saveUserToken(user.uid); 
      }
      
      return user;
      
    } catch (e) {
      print("Error signing in with Google: $e");
      // يُفضل استخدام SnackBar أو أي طريقة تنبيه أخرى في الواجهة
      return null;
    }
  }

  // ----------------------------------------------------------------------
  // 2. تسجيل الخروج (Sign-Out)
  // ----------------------------------------------------------------------

  /// يُسجل خروج المستخدم من Firebase و Google ويزيل التوكن المحلي.
  Future<void> signOut() async {
    try {
      // 1. تسجيل الخروج من جوجل (مهم لتنظيف الجلسة)
      await _googleSignIn.signOut();
      
      // 2. تسجيل الخروج من Firebase 
      await _auth.signOut();
      
      // 3. مسح التوكن المحفوظ محلياً
      await _removeUserToken();
      
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  // ----------------------------------------------------------------------
  // 3. إدارة حالة التخزين المحلي (Shared Preferences)
  // ----------------------------------------------------------------------

  /// يحفظ مُعرّف المستخدم (UID) في التخزين المحلي.
  Future<void> _saveUserToken(String uid) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userTokenKey, uid);
  }

  /// يمسح مُعرّف المستخدم من التخزين المحلي.
  Future<void> _removeUserToken() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userTokenKey);
  }

  /// يتحقق مما إذا كان هناك مُعرّف مستخدم محفوظ محلياً (كبديل سريع للتحقق)
  Future<bool> checkLocalUser() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_userTokenKey);
  }
}