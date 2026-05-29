import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/widgets/logo_widget.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController authController = Get.find<AuthController>();
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light grey-blue background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF), // White
              Color(0xFFF1F5F9), // Slate 100
              Color(0xFFE2E8F0), // Slate 200
            ],
            stops: [0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // ── BRANDING LOGO (Light Theme Style) ──────────────────────
                  const TriLongLogo(
                    height: 90,
                    isHorizontal: false,
                    spacing: 12,
                  ),
                  const SizedBox(height: 40),

                  // ── LOGIN FORM CARD ────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F2C59).withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Đăng nhập hệ thống",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F2C59), // Navy Blue
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Vui lòng đăng nhập bằng tài khoản nội bộ của bạn",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B), // Muted grey
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Trường nhập Số điện thoại
                          const Text(
                            "SỐ ĐIỆN THOẠI",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Color(0xFF1B3B6F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Color(0xFF0F2C59), fontSize: 15, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: "Nhập số điện thoại đăng ký",
                              hintStyle: TextStyle(color: const Color(0xFF94A3B8).withOpacity(0.7), fontSize: 14),
                              prefixIcon: const Icon(Icons.phone_iphone_outlined, color: Color(0xFF1B3B6F)),
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9), // Light grey
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                  return "Số điện thoại không được để trống";
                              }
                              if (value.trim().length < 9 || value.trim().length > 11) {
                                return "Số điện thoại phải từ 9 đến 11 số";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Trường nhập Mật khẩu
                          const Text(
                            "MẬT KHẨU",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Color(0xFF1B3B6F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Color(0xFF0F2C59), fontSize: 15, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: "Nhập mật khẩu của bạn",
                              hintStyle: TextStyle(color: const Color(0xFF94A3B8).withOpacity(0.7), fontSize: 14),
                              prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF1B3B6F)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFF1B3B6F),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Mật khẩu không được để trống";
                              }
                              if (value.length < 6) {
                                return "Mật khẩu phải từ 6 ký tự trở lên";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Nút đăng nhập Gold Gradient với hiệu ứng Loading
                          Obx(() => Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFD4AF37), // Gold
                                  Color(0xFFE5C060), // Light Gold
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: authController.isLoading.value
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        FocusScope.of(context).unfocus();
                                        authController.login(
                                          _phoneController.text.trim(),
                                          _passwordController.text,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: authController.isLoading.value
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      "ĐĂNG NHẬP",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── TÀI KHOẢN CHẠY THỬ / QUICK LOGIN CHIPS ──────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.people_outline_rounded, color: Color(0xFFD4AF37), size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Tài khoản demo (Nhấn chọn nhanh)",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F2C59),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildDemoAccountChip("Admin", "0900000001"),
                            _buildDemoAccountChip("Trưởng Phòng", "0900000002"),
                            _buildDemoAccountChip("Sale A", "0900000003"),
                            _buildDemoAccountChip("Sale B", "0900000004"),
                            _buildDemoAccountChip("Văn Phòng", "0900000005"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── CHÚ THÍCH HỆ THỐNG ─────────────────────────────────────
                  const Text(
                    "Phiên bản Mobile 2.0.0 (Light Theme)",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "© 2026 Công Ty Cổ Phần Bất Động Sản Trí Long",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAccountChip(String label, String phone) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _phoneController.text = phone;
          _passwordController.text = "123456";
        });
        Get.snackbar(
          "Chọn tài khoản",
          "Đã điền tài khoản $label ($phone)",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0F2C59),
          colorText: Colors.white,
          duration: const Duration(milliseconds: 1500),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0F2C59),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
