import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/checkin_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../shared/widgets/history_date_list_view.dart';

class CheckinView extends StatelessWidget {
  final CheckinController controller = Get.put(CheckinController());
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  CheckinView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              indicatorColor: Color(0xFF0F2C59),
              labelColor: Color(0xFF0F2C59),
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(
                  icon: Icon(Icons.fingerprint_rounded),
                  text: "CHẤM CÔNG",
                ),
                Tab(
                  icon: Icon(Icons.history_rounded),
                  text: "LỊCH SỬ",
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSubmitTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return HistoryDateListView(
      onFetchHistory: (date) => controller.fetchHistory(date),
      emptyMessage: 'Không có dữ liệu chấm công trong ngày này.',
      itemBuilder: (item, index) {
        final checkinTime = item['checkinTime'];
        final dateStr = formatIsoDate(checkinTime?.toString());
        final note = item['note'] ?? 'Không có ghi chú';
        final status = item['status'] ?? 'APPROVED';
        final actionType = item['actionType'] ?? 'CHECK_IN';
        final isCheckOut = actionType == 'CHECK_OUT';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isCheckOut ? Colors.red.shade50 : Colors.green.shade50,
              child: Icon(
                isCheckOut ? Icons.logout_rounded : Icons.login_rounded,
                color: isCheckOut ? Colors.red : Colors.green,
                size: 22,
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCheckOut ? Colors.red.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isCheckOut ? 'Check-out' : 'Check-in',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCheckOut ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateStr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                note,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel(status),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor(status),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // ── PROFILE BANNER ──────────────────────────────────────────
          Obx(() {
            final user = authController.currentUser;
            final name = user['fullName'] ?? 'Chưa đăng nhập';
            final dept = user['departmentName'] ?? 'Phòng ban';
            final role = user['role'] ?? 'SALE';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2C59).withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFD4AF37).withOpacity(0.15),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Color(0xFF0F2C59),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dept,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        color: Color(0xFFB8860B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ── TOGGLE: CHẤM CÔNG VÀO / RA ──────────────────────────────
          Obx(() => Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // Nút CHẤM CÔNG VÀO
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.selectedActionType.value = 'CHECK_IN',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: controller.selectedActionType.value == 'CHECK_IN'
                            ? Colors.green
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: controller.selectedActionType.value == 'CHECK_IN'
                            ? [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.login_rounded,
                            size: 18,
                            color: controller.selectedActionType.value == 'CHECK_IN' ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CHẤM CÔNG VÀO',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: controller.selectedActionType.value == 'CHECK_IN' ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Nút CHẤM CÔNG RA
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.selectedActionType.value = 'CHECK_OUT',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: controller.selectedActionType.value == 'CHECK_OUT'
                            ? Colors.red
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: controller.selectedActionType.value == 'CHECK_OUT'
                            ? [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: controller.selectedActionType.value == 'CHECK_OUT' ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CHẤM CÔNG RA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: controller.selectedActionType.value == 'CHECK_OUT' ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),

          // ── KHU VỰC ẢNH CHÂN DUNG ────────────────────────────────────
          Obx(() => GestureDetector(
            onTap: () => controller.takePhoto(),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0F2C59).withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2C59).withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: controller.selectedImage.value == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 54, color: Color(0xFFD4AF37)),
                        const SizedBox(height: 10),
                        const Text(
                          "Chạm để chụp ảnh xác thực",
                          style: TextStyle(color: Color(0xFF0F2C59), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "(Hệ thống sẽ đối soát khuôn mặt với CSDL)",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(controller.selectedImage.value!, fit: BoxFit.cover),
                    ),
            ),
          )),
          const SizedBox(height: 16),

          // ── GHI CHÚ CÔNG VIỆC ──────────────────────────────────────────
          TextField(
            controller: noteController,
            style: const TextStyle(color: Color(0xFF0F2C59), fontWeight: FontWeight.w600, fontSize: 14),
            decoration: InputDecoration(
              labelText: "Ghi chú công việc hôm nay",
              labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.edit_note, color: Color(0xFF1B3B6F)),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── NÚT XÁC NHẬN ──────────────────────────────────────────────
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
            }

            // Nếu ngoài phạm vi -> Ô nhập lý do + Nút gửi duyệt
            if (controller.isOutOfRange.value) {
              return Column(
                children: [
                  TextField(
                    controller: reasonController,
                    style: const TextStyle(color: Color(0xFF0F2C59), fontWeight: FontWeight.w600, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Lý do đi thị trường (Bắt buộc)",
                      labelStyle: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.orangeAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => controller.submitApprovalRequest(reasonController.text),
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    label: const Text(
                      "GỬI YÊU CẦU XÉT DUYỆT",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              );
            }

            // Trong phạm vi -> Nút chấm công theo loại đã chọn
            return Obx(() => ElevatedButton.icon(
              onPressed: () {
                controller.performCheckin(noteController.text);
              },
              icon: Icon(
                controller.selectedActionType.value == 'CHECK_OUT'
                    ? Icons.logout_rounded
                    : Icons.check_circle_outline,
                color: Colors.white,
              ),
              label: Text(
                controller.selectedActionType.value == 'CHECK_OUT'
                    ? "XÁC NHẬN CHẤM CÔNG RA"
                    : "XÁC NHẬN CHẤM CÔNG VÀO",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: controller.selectedActionType.value == 'CHECK_OUT'
                    ? Colors.red.shade700
                    : const Color(0xFF0F2C59),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ));
          }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}