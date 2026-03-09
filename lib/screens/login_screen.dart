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
  bool isLogin = true; // true: Đăng nhập, false: Đăng ký
  bool isLoading = false;
  bool isPasswordVisible = false;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // Logic & Service
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Màu chủ đạo (Bạn có thể đổi màu theo ý thích)
  final Color primaryColor = const Color(0xFF2E3B55); // Màu xanh đậm
  final Color accentColor = const Color(0xFFFCA311);  // Màu cam năng động

  // Xử lý Submit
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    String? errorMessage;

    // Tắt bàn phím
    FocusScope.of(context).unfocus();

    if (isLogin) {
      // Đăng nhập
      errorMessage = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      // Đăng ký
      errorMessage = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: 'User', // Mặc định tạo là User, muốn làm PT phải đăng ký riêng
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainWrapper()));
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
      // Thành công thật sự (trả về null)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Google thành công!"), backgroundColor: Colors.green),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainWrapper()),
      );
    } else if (result == "cancel") {
      // Người dùng hủy
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bạn đã hủy đăng nhập"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      // Lỗi thật sự
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
                  // 1. Header: Logo hoặc Text lớn
                  Icon(Icons.fitness_center, size: 80, color: primaryColor),
                  const SizedBox(height: 10),
                  Text(
                    "PT BOOKING",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isLogin ? "Chào mừng trở lại!" : "Tạo tài khoản mới",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 40),

                  // 2. Input Fields
                  if (!isLogin) ...[
                    _buildTextField(
                      controller: _nameController,
                      label: "Họ và tên",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
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

                  // Quên mật khẩu (chỉ hiện khi login)
                  if (isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {}, // Chưa làm chức năng này
                        child: Text("Quên mật khẩu?", style: TextStyle(color: primaryColor)),
                      ),
                    )
                  else
                    const SizedBox(height: 20),

                  // 3. Main Action Button
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

                  // 4. Divider Or
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

                  // 5. Google Button
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

                  // 6. Toggle Login/Register
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
                            _formKey.currentState?.reset(); // Xóa lỗi cũ
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

  // Widget con để vẽ TextField cho gọn code
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
        fillColor: Colors.grey[100], // Màu nền xám nhẹ
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Bỏ viền đen mặc định
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2), // Viền màu khi bấm vào
        ),
      ),
    );
  }
}