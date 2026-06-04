import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ptbooking/features/auth/models/user_model.dart'; // <-- IMPORT MODEL

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  User? get currentUser => _auth.currentUser;

  // Lấy trọn gói thông tin User dưới dạng Model
  Future<UserModel?> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    }
    return null;
  }

  // Hàm cũ lấy role (giữ lại để không lỗi các màn hình khác)
  Future<String?> getUserRole() async {
    UserModel? userModel = await getUserData();
    return userModel?.role;
  }

  // Login với Google (Đã đồng bộ lưu vào Model)
  Future<String?> loginWithGoogle() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: "501388421930-610ost62oop0k4vu1p6pqigh1ej0s65p.apps.googleusercontent.com",
      );
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return "cancel";

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      UserCredential res = await _auth.signInWithCredential(credential);
      User? user = res.user;

      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          // Lưu data ban đầu cho User mới
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email ?? '',
            'name': user.displayName ?? "User Google",
            'role': 'User',
            'createdAt': DateTime.now(),
          });
        }
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register({required String email, required String password, required String name, required String role}) async {
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(res.user!.uid).set({
        'uid': res.user!.uid, 'email': email, 'name': name, 'role': role, 'createdAt': DateTime.now(),
      });
      return null;
    } on FirebaseAuthException catch (e) { return e.message; }
  }

  // --- ADMIN ---
  Future<String?> login({required String email, required String password}) async {
    try {
      UserCredential res = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = res.user;

      if (user != null) {
        // Kiểm tra nếu là email của sếp thì cấp quyền tối cao luôn
        if (email.toLowerCase() == 'admin@gmail.com') {
          DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

          // Lỡ bị xóa bảng users thì tự động đẻ ra lại dòng này
          if (!doc.exists) {
            await _firestore.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'email': email,
              'name': 'Quản Trị Hệ Thống',
              'role': 'Admin',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
