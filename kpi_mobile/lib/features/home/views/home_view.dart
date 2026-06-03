import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../shell/controllers/shell_controller.dart';
import '../controllers/kpi_controller.dart';

class HomeView extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();
  final ShellController shellController = Get.find<ShellController>();
  final KpiController kpiController = Get.put(KpiController());

  HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = authController.currentUser;
      final roleName = user['role'] ?? 'SALE';
      final isSaleOrTpkd = roleName == 'SALE' || roleName == 'TRUONG_PHONG';
      final isTpkd = roleName == 'TRUONG_PHONG';

      return RefreshIndicator(
        onRefresh: () async {
          await kpiController.fetchKpiData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── CHÀO BUỔI SÁNG & PROFILE CARD ──────────────────────────────
            _buildWelcomeHeader(),
            const SizedBox(height: 20),

            // ── TỔNG QUAN KPI (CHỈ HIỂN THỊ CHO SALE & TPKD) ──────────────
            if (isSaleOrTpkd) ...[
              _buildKpiOverviewCard(),
              const SizedBox(height: 20),
            ],

            // ── THỐNG KÊ KPI PHÒNG BAN (CHỈ TPKD MỚI THẤY) ──────────────────
            if (isTpkd) ...[
              _buildDepartmentKpiCard(),
              const SizedBox(height: 20),
            ],

            // ── TRỢ LÝ ẢO NẮC NHỞ (CHỈ HIỂN THỊ CHO SALE & TPKD) ─────────────
            if (isSaleOrTpkd) ...[
              _buildAssistantNudgeCard(),
              const SizedBox(height: 24),
            ],

            // ── CÁC PHÂN HỆ NGHIỆP VỤ (QUICK ACTIONS CARD) ─────────────────
            const Text(
              "Phân hệ nghiệp vụ",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F2C59),
              ),
            ),
            const SizedBox(height: 12),
            _buildModulesGrid(),
            const SizedBox(height: 30),
          ],
        ),
      ));
    });
  }

  Widget _buildWelcomeHeader() {
    return Obx(() {
      final user = authController.currentUser;
      final name = user['fullName'] ?? 'Nhân viên';
      final roleName = user['role'] ?? 'SALE';
      final dept = user['departmentName'] ?? 'Phòng Kinh Doanh';
      
      String displayRole = "Cộng tác viên";
      if (roleName == "ADMIN") displayRole = "Quản trị viên";
      if (roleName == "TRUONG_PHONG") displayRole = "Trưởng phòng Kinh doanh";
      if (roleName == "SALE") displayRole = "Chuyên viên tư vấn";
      if (roleName == "VAN_PHONG") displayRole = "Nhân viên văn phòng";

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Xin chào, $name 👋",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F2C59),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "$displayRole • $dept",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFD4AF37).withOpacity(0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildKpiOverviewCard() {
    return Column(
      children: [
        _buildSingleKpiCard("Điểm tích lũy KPI tuần", kpiController.kpiWeeklyPoints, kpiController.kpiWeeklyTarget),
        const SizedBox(height: 16),
        _buildSingleKpiCard("Điểm tích lũy KPI tháng", kpiController.kpiPoints, kpiController.kpiTarget),
      ],
    );
  }

  Widget _buildSingleKpiCard(String title, RxDouble pointsObs, RxDouble targetObs) {
    return Obx(() {
      final kpi = pointsObs.value;
      final target = targetObs.value;
      final percent = (target > 0) ? (kpi / target).clamp(0.0, 1.0) : 0.0;
      final percentStr = (percent * 100).toStringAsFixed(0);

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F2C59).withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                  ),
                ),
                Text(
                  "$percentStr%",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F2C59),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${kpi.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} Điểm",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F2C59),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F3E6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      percent >= 1.0 ? "Đạt chỉ tiêu tối đa" : (percent >= 0.5 ? "Đang tiến độ tốt" : "Cần cố gắng thêm"),
                      style: const TextStyle(
                        color: Color(0xFFB8860B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }



  Widget _buildAssistantNudgeCard() {
    return Obx(() {
      final kpi = kpiController.kpiPoints.value;
      
      String assistantNudge = "Bạn đang hoàn thành tốt kế hoạch! Hãy tiếp tục duy trì tác phong.";
      if (kpi < 50) {
        assistantNudge = "Chỉ số KPI của bạn hiện đang ở mức thấp. Trợ lý gợi ý bạn cần tích cực đi thị trường thực chiến (+10đ) và đăng bài truyền thông (+5đ).";
      } else if (kpi < 80) {
        assistantNudge = "Bạn đang gần chạm mốc đạt chỉ tiêu! Tối nay có lớp đào tạo của công ty, hãy quét mã chuyên cần để nhận thêm 5 điểm KPI tác phong.";
      } else if (kpi >= 100) {
        assistantNudge = "Tuyệt vời! Bạn đã xuất sắc hoàn thành 100% KPI chỉ tiêu tháng. Hãy nỗ lực chốt thêm căn để nhận thưởng hoa hồng không giới hạn.";
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF5), // Warm soft gold/cream
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF9E7B9), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFD4AF37),
              child: Icon(Icons.psychology, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Trợ Lý Ảo Trí Long AI",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB8860B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    assistantNudge,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: Color(0xFF5C4033),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildModulesGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _buildModuleCard(
          title: "Chấm công",
          subtitle: "Check-in GPS",
          icon: Icons.fingerprint,
          color: const Color(0xFF0F2C59),
          index: 1, // Shell index for Checkin
        ),
        _buildModuleCard(
          title: "Thực chiến",
          subtitle: "Gặp khách hàng",
          icon: Icons.groups,
          color: const Color(0xFFD4AF37),
          index: 2, // Shell index for Thuc Chien
        ),
        _buildModuleCard(
          title: "Bài post",
          subtitle: "Truyền thông KPI",
          icon: Icons.post_add,
          color: const Color(0xFF1B3B6F),
          index: 3, // Shell index for Bai Post
        ),
        _buildModuleCard(
          title: "Đào tạo",
          subtitle: "Quét mã chuyên cần",
          icon: Icons.school_outlined,
          color: Colors.green,
          index: 4, // Shell index for Dao Tao
        ),
        _buildModuleCard(
          title: "Phản hồi",
          subtitle: "Góp ý kiến Admin",
          icon: Icons.chat_bubble_outline,
          color: Colors.teal,
          index: 5, // Shell index for Phan Hoi
        ),
        _buildModuleCard(
          title: "Chốt căn",
          subtitle: "Đăng ký chốt căn",
          icon: Icons.domain_verification_outlined,
          color: Colors.redAccent,
          index: 6, // Shell index for Chot Can
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    return InkWell(
      onTap: () {
        shellController.changeMenuIndex(index);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F2C59).withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2C59),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentKpiCard() {
    return Obx(() {
      // Hiển thị loading indicator khi đang tải
      if (kpiController.isLoadingDepartment.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        );
      }

      final membersList = kpiController.departmentMembers;
      if (membersList.isEmpty) {
        return const SizedBox();
      }

      final members = membersList.map((m) {
        return {
          'name': m['fullName'] ?? 'Nhân viên',
          'role': m['role'] == 'SALE' ? 'Chuyên viên tư vấn' : m['role'] ?? 'Nhân sự',
          'points': (m['total'] as num?)?.toDouble() ?? 0.0,
          'weeklyPoints': (m['weeklyTotal'] as num?)?.toDouble() ?? 0.0,
          'target': kpiController.kpiTarget.value, // Monthly target
          'weeklyTarget': kpiController.kpiWeeklyTarget.value, // Weekly target
          'isLive': false,
        };
      }).toList();

      final totalStaff = members.length;
      final achievedStaff = members.where((m) => (m['points'] as double) >= (m['target'] as double)).length;
      final avgPerformance = totalStaff > 0 
          ? (members.map((m) => (m['points'] as double) / (m['target'] as double)).reduce((a, b) => a + b) / totalStaff * 100)
          : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2C59).withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "KPI ${authController.currentUser['departmentName']?.toString().toUpperCase() ?? 'PHÒNG KINH DOANH'}",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Thành viên quản lý ($totalStaff nhân sự)",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F2C59),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2C59).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Trực thuộc bạn",
                  style: TextStyle(
                    color: Color(0xFF0F2C59),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Thống kê tóm tắt số nhân viên và tiến trình KPI trong phòng
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2C59).withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Tổng nhân sự",
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$totalStaff nhân sự",
                        style: const TextStyle(fontSize: 15, color: Color(0xFF0F2C59), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Đạt KPI chỉ tiêu",
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$achievedStaff/$totalStaff",
                        style: const TextStyle(fontSize: 15, color: Color(0xFFB8860B), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Hiệu suất phòng",
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${avgPerformance.toStringAsFixed(0)}%",
                        style: const TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 16),
            itemBuilder: (context, index) {
              final m = members[index];
              final name = m['name'] as String;
              final role = m['role'] as String;
              final isLive = m['isLive'] as bool;
              
              final monthlyPoints = m['points'] as double;
              final monthlyTarget = m['target'] as double;
              final monthlyPercent = (monthlyTarget > 0) ? (monthlyPoints / monthlyTarget).clamp(0.0, 1.2) : 0.0;
              
              final weeklyPoints = m['weeklyPoints'] as double;
              final weeklyTarget = m['weeklyTarget'] as double;
              final weeklyPercent = (weeklyTarget > 0) ? (weeklyPoints / weeklyTarget).clamp(0.0, 1.2) : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: (isLive ? const Color(0xFFD4AF37) : const Color(0xFF0F2C59)).withOpacity(0.1),
                        child: Text(
                          name.isNotEmpty ? name[0] : 'S',
                          style: TextStyle(
                            color: isLive ? const Color(0xFFB8860B) : const Color(0xFF0F2C59),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Color(0xFF0F2C59),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isLive) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.red.shade100, width: 0.5),
                                  ),
                                  child: const Text(
                                    "BẠN TEST",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            role,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMemberProgressRow("Tiến độ tuần", weeklyPoints, weeklyTarget, weeklyPercent),
                  const SizedBox(height: 8),
                  _buildMemberProgressRow("Tiến độ tháng", monthlyPoints, monthlyTarget, monthlyPercent),
                ],
              );
            },
          ),
        ],
      ),
    );
    });
  }

  Widget _buildMemberProgressRow(String label, double points, double target, double percent) {
    Color statusColor = Colors.orange;
    String statusText = "Cần cố gắng";
    if (percent >= 1.0) {
      statusColor = Colors.green;
      statusText = "Đạt chỉ tiêu";
    } else if (percent >= 0.7) {
      statusColor = const Color(0xFFD4AF37);
      statusText = "Khá";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(
                  "${points.toStringAsFixed(0)}/${target.toStringAsFixed(0)} điểm",
                  style: const TextStyle(
                    color: Color(0xFF0F2C59),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percent >= 1.0 ? Colors.green : (percent >= 0.7 ? const Color(0xFFD4AF37) : Colors.orangeAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "${(percent * 100).toStringAsFixed(0)}%",
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
