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
            _buildModulesGrid(context),
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
        _buildSingleKpiCard("Điểm KPI tuần", kpiController.kpiWeeklyPoints, kpiController.kpiWeeklyTarget),
        const SizedBox(height: 16),
        _buildSingleKpiCard("Điểm KPI tháng", kpiController.kpiPoints, kpiController.kpiTarget),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E9F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F2C59).withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                  ),
                ),
                // FittedBox: chữ to thì số % co lại cho nằm gọn trong vòng tròn
                SizedBox(
                  width: 52,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "$percentStr%",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F2C59),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Số điểm to, "/ chỉ tiêu điểm" nhỏ — cùng một dòng, không gãy giữa số và chữ "Điểm"
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: kpi.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F2C59)),
                      ),
                      TextSpan(
                        text: " / ${target.toStringAsFixed(0)} điểm",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F3E6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      percent >= 1.0 ? "Đạt chỉ tiêu tối đa" : (percent >= 0.5 ? "Đang tiến độ tốt" : "Cần cố gắng thêm"),
                      style: const TextStyle(
                        color: Color(0xFF9A6B00),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
      // So theo % chỉ tiêu THÁNG (số thứ Hai × 100), không so với số điểm cố
      // định: trước đây mới 100 điểm (1/4 chỉ tiêu 400) đã báo "hoàn thành 100%".
      final mucTieu = kpiController.kpiTarget.value;
      final tiLe = mucTieu > 0 ? kpiController.kpiPoints.value / mucTieu : 0.0;

      String assistantNudge = "Bạn đang hoàn thành tốt kế hoạch! Hãy tiếp tục duy trì tác phong.";
      if (tiLe < 0.5) {
        assistantNudge = "Chỉ số KPI của bạn hiện đang ở mức thấp. Trợ lý gợi ý bạn cần tích cực đi thị trường thực chiến (+10đ) và đăng bài truyền thông (+5đ).";
      } else if (tiLe < 0.8) {
        assistantNudge = "Bạn đang gần chạm mốc chỉ tiêu tháng! Đi đủ các buổi đào tạo trong tuần (+15đ), gặp khách (+10đ) và đăng bài (+5đ) để về đích.";
      } else if (tiLe >= 1) {
        assistantNudge = "Tuyệt vời! Bạn đã hoàn thành 100% KPI chỉ tiêu tháng. Hãy nỗ lực chốt thêm căn để nhận thưởng hoa hồng không giới hạn.";
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

  /*
   * Phân hệ nghiệp vụ.
   *
   * Văn phòng (Back-Office) và Admin không thuộc diện chấm KPI — họ chỉ chấm
   * công. Bày ra "Thực chiến", "Bài post", "Chốt căn"… thì họ bấm vào, gửi báo
   * cáo, rồi chờ điểm không bao giờ tới. Nên chỉ hiện những phân hệ họ thật sự
   * dùng: chấm công và phản hồi.
   */
  Widget _buildModulesGrid(BuildContext context) {
    final vaiTro = authController.currentUser['role']?.toString() ?? 'SALE';
    final chamKpi = vaiTro == 'SALE' || vaiTro == 'TRUONG_PHONG';

    // Chiều cao ô theo cỡ chữ (không dùng tỉ lệ cố định): chữ to thì ô cao thêm
    // cho vừa tên + mô tả, thay vì chữ bị cắt ở đáy ô.
    final heSoChu = MediaQuery.textScalerOf(context).scale(10) / 10;
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 84 + 40 * heSoChu,
      ),
      children: [
        _buildModuleCard(
          title: "Chấm công",
          subtitle: "Check-in GPS",
          icon: Icons.fingerprint,
          color: const Color(0xFF0F2C59),
          index: 1, // Shell index for Checkin
        ),
        if (chamKpi) ...[
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
            title: "Gieo hạt",
            subtitle: "Giới thiệu người mới",
            icon: Icons.eco_outlined,
            color: const Color(0xFFD4AF37),
            index: 5, // Shell index for Gieo Hat
          ),
        ],
        _buildModuleCard(
          title: "Phản hồi",
          subtitle: "Góp ý kiến Admin",
          icon: Icons.chat_bubble_outline,
          color: Colors.teal,
          index: 6, // Shell index for Phan Hoi
        ),
        if (chamKpi)
          _buildModuleCard(
            title: "Chốt căn",
            subtitle: "Đăng ký chốt căn",
            icon: Icons.domain_verification_outlined,
            color: Colors.redAccent,
            index: 7, // Shell index for Chot Can
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expanded: tên phòng dài / chữ to thì xuống dòng, không đẩy nhãn bên phải ra ngoài
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "KPI ${authController.currentUser['departmentName']?.toString().toUpperCase() ?? 'PHÒNG KINH DOANH'}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Thành viên quản lý ($totalStaff nhân sự)",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F2C59),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
          // Thống kê tóm tắt số nhân viên và tiến trình KPI trong phòng.
          // IntrinsicHeight: ba ô cao bằng nhau kể cả khi một nhãn xuống 2 dòng.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _oThongKe("Nhân sự", "$totalStaff", const Color(0xFF0F2C59)),
                const SizedBox(width: 8),
                _oThongKe("Đạt chỉ tiêu", "$achievedStaff/$totalStaff", const Color(0xFFB8860B)),
                const SizedBox(width: 8),
                _oThongKe("Hiệu suất", "${avgPerformance.toStringAsFixed(0)}%", const Color(0xFF15803D)),
              ],
            ),
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
                      Expanded(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF0F2C59),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
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

  /// Ô số liệu nhỏ trong thẻ KPI phòng: nhãn trên, số dưới. Số co lại cho vừa ô
  /// (FittedBox) thay vì tràn khi người dùng để cỡ chữ to.
  Widget _oThongKe(String nhan, String giaTri, Color mau) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              nhan,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(giaTri, style: TextStyle(fontSize: 16, color: mau, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
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
        // Wrap: chữ to / màn hẹp thì phần điểm + đánh giá xuống dòng thay vì tràn ra ngoài
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 2,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: "${points.toStringAsFixed(0)}/${target.toStringAsFixed(0)} điểm",
                  style: const TextStyle(color: Color(0xFF0F2C59), fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: "  ·  $statusText",
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                ),
              ]),
              style: const TextStyle(fontSize: 11),
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
