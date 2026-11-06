import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

/// Hộp "Đổi mật khẩu" ở trang Cá nhân.
void moHopDoiMatKhau(AuthController controller) {
  final oldPasswordCtrl = TextEditingController();
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
      child: const Text("Hủy", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
    ),
  );
}
