import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/widgets/logo_widget.dart';
import '../../../core/widgets/thong_bao.dart';

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

  /// Ô "Ghi nhớ đăng nhập". Mặc định tích — đúng cách app vẫn chạy trước nay
  /// (đăng nhập một lần, mở app là vào thẳng).
  bool _ghiNho = true;

  @override
  void initState() {
    super.initState();
    // Điền sẵn số điện thoại + mật khẩu đã ghi nhớ (sau khi đăng xuất / hết phiên)
    authController.docGhiNho().then((g) {
      if (!mounted) return;
      setState(() {
        _ghiNho = g.ghiNho;
        if (_phoneController.text.isEmpty && g.sdt != null) _phoneController.text = g.sdt!;
        if (_passwordController.text.isEmpty && g.matKhau != null) _passwordController.text = g.matKhau!;
      });
    });
  }

  /// Quên mật khẩu: hỏi số điện thoại, đặt lại về 123456 nếu máy này từng
  /// đăng nhập tài khoản đó; không thì chỉ cách nhờ Admin.
  Future<void> _quenMatKhau() async {
    FocusScope.of(context).unfocus();
    final sdtCtrl = TextEditingController(text: _phoneController.text.trim());
    final sdt = await Get.dialog<String>(
      AlertDialog(
        title: const Text("Quên mật khẩu",
            style: TextStyle(color: Color(0xFF0F2C59), fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Mật khẩu sẽ được đặt lại về 123456. Mọi máy đang đăng nhập tài khoản này "
                "sẽ bị đăng xuất.",
                style: TextStyle(fontSize: 14, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              const Text(
                "Chỉ làm được trên điện thoại bạn đã từng đăng nhập tài khoản này. "
                "Máy khác thì nhờ Admin đặt lại.",
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sdtCtrl,
                keyboardType: TextInputType.phone,
                autofocus: sdtCtrl.text.isEmpty,
                decoration: InputDecoration(
                  labelText: "Số điện thoại",
                  prefixIcon: const Icon(Icons.phone_iphone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F2C59)),
            onPressed: () {
              final v = sdtCtrl.text.trim();
              if (v.isNotEmpty) Get.back(result: v);
            },
            child: const Text("Đặt lại về 123456",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (sdt == null || !mounted) return;

    if (!await authController.coKhoaKhoiPhuc(sdt)) {
      await Get.dialog(AlertDialog(
        title: const Text("Không tự đặt lại được",
            style: TextStyle(color: Color(0xFF0F2C59), fontWeight: FontWeight.w800)),
        content: Text(
          "Điện thoại này chưa từng đăng nhập tài khoản $sdt (trên bản app có nút Quên mật khẩu), "
          "nên không tự đặt lại được — để người khác không reset được tài khoản của bạn.\n\n"
          "Nhờ Admin đặt lại mật khẩu trên web (Nhân sự → Đặt lại mật khẩu).",
        ),
        actions: [TextButton(onPressed: () => Get.back(), child: const Text("Đã hiểu"))],
      ));
      return;
    }

    if (await authController.quenMatKhau(sdt) && mounted) {
      setState(() {
        _phoneController.text = sdt;
        _passwordController.text = AuthController.matKhauMacDinh;
      });
      snack("Đã đặt lại mật khẩu",
          "Mật khẩu giờ là 123456 (đã điền sẵn). Bấm Đăng nhập rồi đặt mật khẩu mới.",
          duration: const Duration(seconds: 6));
    }
  }

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
                          const SizedBox(height: 12),

                          // Ghi nhớ đăng nhập. "Quên mật khẩu?" để riêng dưới nút
                          // Đăng nhập: chung một hàng thì máy 360 dp đã không vừa.
                          Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              onTap: () => setState(() => _ghiNho = !_ghiNho),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: _ghiNho,
                                        onChanged: (v) => setState(() => _ghiNho = v ?? true),
                                        activeColor: const Color(0xFF0F2C59),
                                        side: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        "Ghi nhớ đăng nhập",
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1B3B6F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

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
                                          ghiNho: _ghiNho,
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
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: _quenMatKhau,
                              child: const Text(
                                "Quên mật khẩu?",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B3B6F),
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFF1B3B6F),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── CHÚ THÍCH HỆ THỐNG ─────────────────────────────────────
                  // Không ghi số phiên bản ở đây: dòng cũ ghi cứng "2.0.0" trong khi
                  // pubspec là 1.2.0 — số sai còn tệ hơn không có số.
                  const Text(
                    "© 2026 Công ty TNHH Bất động sản Trí Long",
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
}
