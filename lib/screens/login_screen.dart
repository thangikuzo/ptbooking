import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/main_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Trạng thái
  bool isLogin = true;
  bool isLoading = false;
  bool isPasswordVisible = false;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // Logic & Service
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final Color primaryColor = const Color(0xFF2E3B55);
  final Color accentColor = const Color(0xFFFCA311);

  // Xử lý Submit
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    String? errorMessage;

    FocusScope.of(context).unfocus();

    if (isLogin) {
      // Đăng nhập
      errorMessage = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      // Đăng ký: Mặc định ai cũng là User hết
      errorMessage = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: 'User', // <-- Đã đổi thành mặc định là User
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

      // LẤY ROLE TỪ SERVER ĐỂ ĐIỀU HƯỚNG
      String? role = await _authService.getUserRole();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainWrapper(userRole: role ?? 'User')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  // Xử lý Google Login
  void _googleSignIn() async {
    setState(() => isLoading = true);
    String? result = await _authService.loginWithGoogle();
    setState(() => isLoading = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Google thành công!"), backgroundColor: Colors.green),
      );

      // LẤY ROLE SAU KHI LOGIN GOOGLE
      String? role = await _authService.getUserRole();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainWrapper(userRole: role ?? 'User')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $result"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.fitness_center, size: 80, color: primaryColor),
                  const SizedBox(height: 10),
                  Text(
                    "PT BOOKING",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isLogin ? "Chào mừng trở lại!" : "Tạo tài khoản mới",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 40),

                  if (!isLogin) ...[
                    _buildTextField(
                      controller: _nameController,
                      label: "Họ và tên",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    // ĐÃ XÓA DROPDOWN Ở ĐÂY CHO GỌN GÀNG!
                  ],

                  _buildTextField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _passwordController,
                    label: "Mật khẩu",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isPassVisible: isPasswordVisible,
                    onTogglePass: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),

                  if (isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text("Quên mật khẩu?", style: TextStyle(color: primaryColor)),
                      ),
                    )
                  else
                    const SizedBox(height: 20),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                        isLogin ? "ĐĂNG NHẬP" : "ĐĂNG KÝ",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text("HOẶC", style: TextStyle(color: Colors.grey[500])),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _googleSignIn,
                    icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 32),
                    label: const Text(
                      "Tiếp tục với Google",
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 20),

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
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
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
        if (val == null || val.isEmpty) return "Vui lòng nhập $label";
        if (label == "Email" && !val.contains("@")) return "Email không hợp lệ";
        if (label == "Mật khẩu" && val.length < 6) return "Mật khẩu phải trên 6 ký tự";
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            (isPassVisible ?? false) ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: onTogglePass,
        )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}