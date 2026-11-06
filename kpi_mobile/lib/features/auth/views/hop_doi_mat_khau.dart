import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

/// Hộp "Đổi mật khẩu" — dùng ở trang Cá nhân và ngay sau khi đăng nhập bằng
/// mật khẩu mặc định 123456.
///
/// [matKhauCu] điền sẵn ô "Mật khẩu hiện tại" (vừa đăng nhập bằng 123456 thì
/// khỏi gõ lại). [loiNhac] hiện một dòng giải thích phía trên các ô.
void moHopDoiMatKhau(AuthController controller, {String? matKhauCu, String? loiNhac}) {
  final oldPasswordCtrl = TextEditingController(text: matKhauCu ?? '');
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  Get.defaultDialog(
    title: "Đổi mật khẩu",
    titleStyle: const TextStyle(
      color: Color(0xFF0F2C59),
      fontWeight: FontWeight.bold,
      fontSize: 18,
    ),
    contentPadding: const EdgeInsets.all(16),
    content: Column(
      children: [
        if (loiNhac != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF5D08A)),
            ),
            child: Text(loiNhac, style: const TextStyle(fontSize: 13, color: Color(0xFF7A4B00))),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: oldPasswordCtrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Mật khẩu hiện tại",
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: newPasswordCtrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Mật khẩu mới",
            prefixIcon: const Icon(Icons.lock_reset, color: Colors.blue),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: confirmPasswordCtrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Xác nhận mật khẩu mới",
            prefixIcon: const Icon(Icons.check_circle_outline, color: Colors.green),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    ),
    confirm: Obx(() => ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F2C59),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: controller.isLoading.value ? null : () {
        controller.changePassword(
          oldPasswordCtrl.text.trim(),
          newPasswordCtrl.text.trim(),
          confirmPasswordCtrl.text.trim(),
        );
      },
      child: controller.isLoading.value
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Text("Xác nhận", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    )),
    cancel: TextButton(
      onPressed: () => Get.back(),
      child: Text(loiNhac != null ? "Để sau" : "Hủy",
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
    ),
  );
}
