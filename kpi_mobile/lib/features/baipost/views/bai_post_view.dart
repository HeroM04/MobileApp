import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/bai_post_controller.dart';
import '../../../shared/widgets/history_date_list_view.dart';
import '../../../data/services/lich_su_thang.dart';
import '../../../core/widgets/thong_bao.dart';
import '../../../core/utils/quyen_anh.dart';
import '../../../core/utils/dong_bo.dart';

class BaiPostView extends StatefulWidget {
  const BaiPostView({super.key});

  @override
  State<BaiPostView> createState() => _BaiPostViewState();
}

class _BaiPostViewState extends State<BaiPostView> {
  final BaiPostController controller = Get.put(BaiPostController());
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();

  File? _screenshot;
  /// VIDEO = video xây kênh, POST = bài đăng/story. Cả hai cùng 5đ nhóm Lan tỏa,
  /// tách ra để Admin theo dõi được ai chịu khó làm video.
  String _contentType = 'POST';

  /// Gợi ý hashtag — chỉ để nhắc, không chặn gửi (Admin xem trên ảnh chụp).
  final List<String> _goiYHashtag = ["#trilongland", "#bds", "#kpi"];

  Future<void> _pickScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (image != null) {
        setState(() => _screenshot = File(image.path));
      }
    } catch (e) {
      if (await xuLyLoiQuyenAnh(e)) return;
      snack("Lỗi", "Không thể chọn hình ảnh: $e");
    }
  }

  /// Gửi bài. Chỉ bắt buộc ẢNH CHỤP MÀN HÌNH — story, video xây kênh nhiều khi
  /// không có link hay caption để dán. Link và caption có thì gửi kèm.
  ///
  /// Trước đây có bước "AI quét hashtag": thực chất chờ 2,5 giây rồi tìm chữ
  /// trong ô caption, và chặn gửi nếu caption thiếu #trilongland — nên bài
  /// không có caption không gửi được. Admin đối chiếu trên ảnh chụp là đủ.
  void _guiBai() async {
    if (!_formKey.currentState!.validate()) return;
    if (_screenshot == null) {
      snack("Thiếu ảnh chụp", "Chọn ảnh chụp màn hình bài đăng để Admin đối chiếu.");
      return;
    }

    final link = _urlController.text.trim();
    final failure = await controller.submitPost(
      platform: link.contains("facebook") ? "FACEBOOK" : "OTHER",
      contentType: _contentType,
      link: link,
      caption: _captionController.text.trim(),
      screenshotUrl: _screenshot!.path,
    );

    if (failure == null) {
      Get.defaultDialog(
        title: "Đã gửi bài",
        middleText: "Bài đang chờ Admin duyệt. Được duyệt bạn nhận +5 điểm nhóm Lan tỏa.",
        textConfirm: "Đã hiểu",
        confirmTextColor: Colors.white,
        buttonColor: const Color(0xFF0F2C59),
        onConfirm: () => Get.back(),
      );
      setState(() {
        _urlController.clear();
        _captionController.clear();
        _screenshot = null;
      });
    } else {
      // Nói rõ hỏng ở đâu và ai sửa được, thay cho câu chung chung trước đây
      snack(
        failure.title,
        failure.isUserFixable
            ? failure.message
            : "${failure.message}\n(Lỗi hệ thống — nếu lặp lại, báo bộ phận kỹ thuật)",
        backgroundColor: failure.isUserFixable ? Colors.orange.shade800 : Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        isDismissible: true,
      );
    }
  }

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
                  icon: Icon(Icons.post_add_rounded),
                  text: "BÀI POST",
                ),
                Tab(
                  icon: Icon(Icons.history_rounded),
                  text: "LỊCH SỬ GỬI",
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
      onFetchMonth: (month) => taiLichSuThang('/social-posts/my-posts', month),
      thoiDiemCua: (item) => item['submittedAt']?.toString(),
      emptyMessageThang: 'Không có bài post nào trong tháng này.',
      loaiDongBo: DongBo.baiDang,
      emptyMessage: 'Không có bài post nào trong ngày này.',
      itemBuilder: (item, index) {
        final submittedAt = item['submittedAt'];
        final dateStr = formatIsoDate(submittedAt?.toString());
        final platform = item['platform'] ?? 'Khác';
        final link = item['link'] ?? '';
        final status = item['status'] ?? 'PENDING';
        final isVideo = item['contentType'] == 'VIDEO';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0F2C59).withOpacity(0.08),
              child: Icon(isVideo ? Icons.videocam_rounded : Icons.article_rounded,
                  color: const Color(0xFF0F2C59), size: 22),
            ),
            title: Text(
              '${isVideo ? "Video xây kênh" : "Bài đăng"} · $platform',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text('Ngày: $dateStr', style: const TextStyle(fontSize: 12, color: Color(0xFF0F2C59), fontWeight: FontWeight.w600)),
                if (link.isNotEmpty)
                  Text(link, style: const TextStyle(fontSize: 11, color: Colors.blue), overflow: TextOverflow.ellipsis),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel(status),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor(status)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon) {
    final bool selected = _contentType == value;
    return GestureDetector(
      onTap: () => setState(() => _contentType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F2C59) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF0F2C59) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : const Color(0xFF1B3B6F)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : const Color(0xFF1B3B6F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2C59).withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Truyền thông & Bài đăng KPI",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Đăng bài truyền thông dự án lên Facebook/Zalo/TikTok rồi gửi ảnh chụp màn hình bài đăng. Link và caption có thì dán, không có cũng được. Bài được duyệt +5 điểm nhóm Lan tỏa.",
                    style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
                  ),
                  const Divider(height: 24),

                  // Phân loại lan tỏa — video xây kênh hay bài đăng thường
                  const Text("PHÂN LOẠI NỘI DUNG", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildTypeChip('POST', 'Bài đăng / Story', Icons.article_outlined)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTypeChip('VIDEO', 'Video xây kênh', Icons.videocam_outlined)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Đường dẫn bài đăng
                  const Text("LINK BÀI VIẾT (KHÔNG BẮT BUỘC)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: "https://facebook.com/username/posts/...",
                      prefixIcon: const Icon(Icons.link, color: Color(0xFF1B3B6F)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    // Để trống được (story, video không có link); có dán thì phải là link
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isNotEmpty && !s.startsWith("http")) return "Link phải bắt đầu bằng http";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nội dung text bài viết
                  const Text("CAPTION ĐÃ ĐĂNG (KHÔNG BẮT BUỘC)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _captionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Dán nội dung bài viết nếu có",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Đính kèm ảnh chụp màn hình bài đăng
                  const Text("ẢNH CHỤP MÀN HÌNH BÀI ĐĂNG (BẮT BUỘC)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickScreenshot,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1.5, style: BorderStyle.solid),
                      ),
                      child: _screenshot == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 40, color: const Color(0xFFD4AF37).withOpacity(0.7)),
                                const SizedBox(height: 6),
                                const Text("Chọn ảnh chụp màn hình bài đăng", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                                const Text("(Định dạng JPG, PNG)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_screenshot!, fit: BoxFit.cover),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Yêu cầu từ khóa
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF9E7B9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Gợi ý: bài đăng nên có #trilongland và 1 tag phụ",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB8860B)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: _goiYHashtag.map((tag) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút gửi bài
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Color(0xFFD4AF37)),
                            SizedBox(height: 12),
                            Text("Đang gửi bài...", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                          ],
                        ),
                      );
                    } else {
                      return ElevatedButton.icon(
                        onPressed: _guiBai,
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        label: const Text(
                          "GỬI BÀI ĐĂNG",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2C59),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
