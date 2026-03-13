import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? get currentUser => _auth.currentUser;

  // THAY ĐỔI 1: Dùng Singleton .instance
  // (Không được dùng new GoogleSignIn() nữa)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // --- THÊM HÀM NÀY ĐỂ LẤY ROLE TỪ FIRESTORE ---
  Future<String?> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          return data?['role'] as String?;
        }
      } catch (e) {
        print("Lỗi khi lấy Role: $e");
      }
    }
    return null; // Trả về null nếu có lỗi hoặc không tìm thấy
  }
  // ----------------------------------------------

  Future<String?> loginWithGoogle() async {
    try {
      // THAY ĐỔI 2: Khởi tạo & Truyền serverClientId
      // Mã này là Web Client ID bạn lấy từ Firebase Console
      await _googleSignIn.initialize(
        serverClientId: "501388421930-610ost62oop0k4vu1p6pqigh1ej0s65p.apps.googleusercontent.com",
      );

      // THAY ĐỔI 3: Dùng authenticate() thay cho signIn()
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) {
        return "Đã hủy chọn tài khoản";
      }

      // Lấy thông tin xác thực (chỉ chứa idToken)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // THAY ĐỔI 4: accessToken để null
      // (Firebase chỉ cần idToken để xác minh danh tính)
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: null,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập vào Firebase
      UserCredential res = await _auth.signInWithCredential(credential);
      User? user = res.user;

      // Lưu user vào Firestore (Logic cũ của bạn - Giữ nguyên)
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email ?? '',
            'name': user.displayName ?? "User Google",
            'role': 'User',
            'avatar': user.photoURL,
            'createdAt': DateTime.now(),
          });
        }
      }

      return null; // Thành công
    } catch (e) {
      String errorStr = e.toString().toLowerCase();

      // Kiểm tra nếu lỗi là do người dùng hủy
      if (errorStr.contains("cancel") || errorStr.contains("canceled")) {
        print("Người dùng đã hủy đăng nhập.");
        return "cancel";
      }

      print("Lỗi Google Sign-In: $e");
      return "Đăng nhập thất bại: $e";
    }
  }

  // --- Các hàm khác giữ nguyên ---
  Future<String?> register({required String email, required String password, required String name, required String role}) async {
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(res.user!.uid).set({
        'uid': res.user!.uid, 'email': email, 'name': name, 'role': role, 'createdAt': DateTime.now(),
      });
      return null;
    } on FirebaseAuthException catch (e) { return e.message; }
  }

  Future<String?> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) { return e.message; }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}