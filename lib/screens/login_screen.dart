import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/main_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool isLoading = false;
  bool isPasswordVisible = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final Color primaryColor = const Color(0xFF0B2447);
  final Color accentColor = const Color(0xFF4BA3E3);

  /// =========================================================
  /// 🚀 SUBMIT
  /// =========================================================
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    String? errorMessage;

    FocusScope.of(context).unfocus();

    if (isLogin) {
      /// 🔹 LOGIN
      errorMessage = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      /// 🔹 REGISTER → LUÔN ROLE USER
      errorMessage = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: 'user', // 🔥 FIX QUAN TRỌNG
      );
    }

    setState(() => isLoading = false);

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isLogin ? "Đăng nhập thành công!" : "Đăng ký thành công!"),
          backgroundColor: Colors.green,
        ),
      );

      /// 🔥 LẤY ROLE TỪ FIRESTORE
      String? role = await _authService.getUserRole();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainWrapper(userRole: role ?? 'user'), // 🔥 FIX
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    }
  }

  /// =========================================================
  /// 🔥 GOOGLE LOGIN
  /// =========================================================
  void _googleSignIn() async {
    setState(() => isLoading = true);

    String? result = await _authService.loginWithGoogle();

    setState(() => isLoading = false);

    if (result == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login Google thành công!"), backgroundColor: Colors.green));

      String? role = await _authService.getUserRole();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainWrapper(userRole: role ?? 'user'), // 🔥 FIX
          ),
        );
      }
    } else if (result == "cancel") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bạn đã hủy đăng nhập"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $result"), backgroundColor: Colors.red));
    }
  }

  /// =========================================================
  /// 🧱 UI
  /// =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.fitness_center, size: 80, color: primaryColor),

                  const SizedBox(height: 10),

                  Text(
                    "PT BOOKING",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    isLogin ? "Chào mừng trở lại!" : "Tạo tài khoản mới",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 40),

                  /// 🔹 NAME
                  if (!isLogin) ...[
                    _buildTextField(controller: _nameController, label: "Họ và tên", icon: Icons.person_outline),
                    const SizedBox(height: 16),
                  ],

                  /// 🔹 EMAIL
                  _buildTextField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  /// 🔹 PASSWORD
                  _buildTextField(
                    controller: _passwordController,
                    label: "Mật khẩu",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isPassVisible: isPasswordVisible,
                    onTogglePass: () {
                      setState(() => isPasswordVisible = !isPasswordVisible);
                    },
                  ),

                  const SizedBox(height: 20),

                  /// 🔥 BUTTON
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isLogin ? "ĐĂNG NHẬP" : "ĐĂNG KÝ",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// 🔥 GOOGLE BUTTON
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _googleSignIn,
                    icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 32),
                    label: const Text("Tiếp tục với Google", style: TextStyle(color: Colors.black)),
                  ),

                  const SizedBox(height: 20),

                  /// 🔄 SWITCH LOGIN/REGISTER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLogin ? "Chưa có tài khoản? " : "Đã có tài khoản? ",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isLogin = !isLogin;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: Text(
                          isLogin ? "Đăng ký ngay" : "Đăng nhập",
                          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
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
    );
  }

  /// =========================================================
  /// 🧩 TEXT FIELD
  /// =========================================================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool? isPassVisible,
    VoidCallback? onTogglePass,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !(isPassVisible ?? false),
      keyboardType: keyboardType,
      validator: (val) {
        if (val == null || val.isEmpty) {
          return "Vui lòng nhập $label";
        }
        if (label == "Email" && !val.contains("@")) {
          return "Email không hợp lệ";
        }
        if (label == "Mật khẩu" && val.length < 6) {
          return "Mật khẩu ≥ 6 ký tự";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon((isPassVisible ?? false) ? Icons.visibility : Icons.visibility_off),
                onPressed: onTogglePass,
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
