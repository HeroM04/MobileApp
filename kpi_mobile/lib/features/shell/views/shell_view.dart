import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/shell_controller.dart';
import '../../home/views/home_view.dart';
import '../../checkin/views/checkin_view.dart';
import '../../thucchien/views/thuc_chien_view.dart';
import '../../baipost/views/bai_post_view.dart';
import '../../daotao/views/dao_tao_view.dart';
import '../../phanhoi/views/phan_hoi_view.dart';
import '../../chotcan/views/chot_can_view.dart';
import '../../profile/views/profile_view.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/widgets/logo_widget.dart';

class ShellView extends StatelessWidget {
  final ShellController shellController = Get.put(ShellController());
  final AuthController authController = Get.find<AuthController>();

  ShellView({super.key});

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return HomeView();
      case 1:
        return CheckinView();
      case 2:
        return const ThucChienView();
      case 3:
        return const BaiPostView();
      case 4:
        return const DaoTaoView();
      case 5:
        return const PhanHoiView();
      case 6:
        return const ChotCanView();
      case 7:
        return const ProfileView();
      default:
        return HomeView();
    }
  }

  IconData _getMenuIcon(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard_outlined;
      case 1:
        return Icons.fingerprint_outlined;
      case 2:
        return Icons.groups_outlined;
      case 3:
        return Icons.post_add_outlined;
      case 4:
        return Icons.school_outlined;
      case 5:
        return Icons.chat_bubble_outline_outlined;
      case 6:
        return Icons.domain_verification_outlined;
      case 7:
        return Icons.person_outline;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F2C59)),
        title: Obx(() {
          final currentIdx = shellController.selectedIndex.value;
          final titleStr = shellController.menuItems[currentIdx];
          return Text(
            titleStr,
            style: const TextStyle(
              color: Color(0xFF0F2C59),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          );
        }),
        actions: [
          // Hiển thị logo thương hiệu nhỏ gọn góc phải AppBar
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: TriLongLogo(
              height: 28,
              isHorizontal: true,
              spacing: 6,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1.0,
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Drawer Header: Brand logo + User profile
            _buildDrawerHeader(),
            
            // Drawer Menu List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                itemCount: shellController.menuItems.length,
                itemBuilder: (context, index) {
                  return Obx(() {
                    final isSelected = shellController.selectedIndex.value == index;
                    return InkWell(
                      onTap: () {
                        shellController.changeMenuIndex(index);
                        Get.back(); // Đóng drawer
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFFD4AF37).withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? const Color(0xFFD4AF37).withOpacity(0.3)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getMenuIcon(index),
                              color: isSelected ? const Color(0xFFB8860B) : const Color(0xFF0F2C59),
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              shellController.menuItems[index],
                              style: TextStyle(
                                color: isSelected ? const Color(0xFFB8860B) : const Color(0xFF0F2C59),
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
            
            // Footer: Logout
            const Divider(color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: InkWell(
                onTap: () {
                  Get.back(); // Đóng Drawer
                  _showLogoutConfirmation();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text(
                        "Đăng xuất",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Obx(() => _getBody(shellController.selectedIndex.value)),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F2C59),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomPaint(
                size: const Size(24, 32),
                painter: DoubleLPainter(),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "TRÍ L",
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 0.8, left: 0.2, right: 0.2),
                        child: CustomPaint(
                          size: const Size(13, 13),
                          painter: DragonOPainter(),
                        ),
                      ),
                      const Text(
                        "NG",
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        " LAND",
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    "KIÊN TẠO SỰ BỀN VỮNG",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 6,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Thông tin tài khoản nhân viên
          Obx(() {
            final user = authController.currentUser;
            final name = user['fullName'] ?? 'Nhân viên';
            final dept = user['departmentName'] ?? 'Phòng ban';
            final role = user['role'] ?? 'SALE';
            
            return InkWell(
              onTap: () {
                shellController.changeMenuIndex(7);
                Get.back(); // Đóng Drawer
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFD4AF37).withOpacity(0.2),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$role • $dept",
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white60),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    Get.defaultDialog(
      title: "Xác nhận",
      middleText: "Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?",
      textCancel: "HỦY BỎ",
      textConfirm: "ĐỒNG Ý",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        Get.back(); // Đóng Dialog
        authController.logout();
      },
    );
  }
}

// DoubleLPainterDrawer removed, DoubleLPainter reused directly.
