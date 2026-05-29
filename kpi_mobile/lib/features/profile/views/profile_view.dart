import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  // Helper chuyển đổi tên vai trò sang Tiếng Việt
  String _getRoleNameVi(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Quản trị hệ thống';
      case 'TRUONG_PHONG':
        return 'Trưởng phòng Kinh doanh';
      case 'SALE':
        return 'Chuyên viên Kinh doanh';
      case 'VAN_PHONG':
        return 'Nhân viên Văn phòng';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final user = authController.currentUser;
    final name = user['fullName'] ?? 'Nhân viên';
    final phoneNumber = user['phoneNumber'] ?? '';
    final role = user['role'] ?? 'SALE';
    final dept = user['departmentName'] ?? 'Phòng ban';
    
    // Tạo mã nhân viên dựa trên userId
    final userId = user['userId'] ?? 1;
    final employeeId = "TL-${userId.toString().padLeft(3, '0')}";
    final mockEmail = phoneNumber.isNotEmpty 
        ? "$phoneNumber@trilongland.vn"
        : "nhanvien$userId@trilongland.vn";

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Profile Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2C59), Color(0xFF1B3B6F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2C59).withOpacity(0.12),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar tròn lớn
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Color(0xFF0F2C59),
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Họ tên & Chức vụ
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _getRoleNameVi(role),
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Badge hoạt động
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                      SizedBox(width: 6),
                      Text(
                        "Đang hoạt động",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Thẻ Thông tin Nhân sự
          _buildSectionTitle("Thông tin nhân sự"),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2C59).withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.badge_outlined,
                  label: "MÃ NHÂN VIÊN",
                  value: employeeId,
                ),
                const Divider(height: 1, indent: 56),
                _buildInfoTile(
                  icon: Icons.business_outlined,
                  label: "PHÒNG BAN",
                  value: dept,
                ),
                const Divider(height: 1, indent: 56),
                _buildInfoTile(
                  icon: Icons.phone_android_outlined,
                  label: "SỐ ĐIỆN THOẠI",
                  value: phoneNumber,
                ),
                const Divider(height: 1, indent: 56),
                _buildInfoTile(
                  icon: Icons.email_outlined,
                  label: "EMAIL CÔNG TY",
                  value: mockEmail,
                ),
              ],
            ),
          ),
          // 3. Thẻ Cài đặt bảo mật
          _buildSectionTitle("Cài đặt bảo mật"),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2C59).withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _showChangePasswordDialog(context, authController),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Đổi mật khẩu",
                        style: TextStyle(
                          color: Color(0xFF0F2C59),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Cửa sổ Đổi mật khẩu
  void _showChangePasswordDialog(BuildContext context, AuthController controller) {
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

  // Widget tiêu đề nhóm thông tin
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF0F2C59),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget hiển thị từng dòng thông tin
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          // Icon tròn màu Navy nhạt
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2C59).withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0F2C59),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Nội dung text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0F2C59),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
