import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/bai_post_controller.dart';
import '../../../shared/widgets/history_date_list_view.dart';
import '../../../shared/widgets/the_lich_su.dart';
import '../../../data/services/lich_su_thang.dart';
import '../../../core/widgets/thong_bao.dart';
import '../../../core/utils/quyen_anh.dart';
import '../../../core/utils/dong_bo.dart';

/// Tên hiển thị của mã nền tảng máy chủ lưu.
String tenNenTang(String? ma) => switch ((ma ?? '').toUpperCase()) {
      'FACEBOOK' => 'Facebook',
      'TIKTOK' => 'TikTok',
      'ZALO' => 'Zalo',
      _ => 'Khác',
    };

String goiYLink(String nenTang) => switch (nenTang) {
      'TIKTOK' => 'https://www.tiktok.com/@ten/video/...',
      'ZALO' => 'Không bắt buộc với Zalo',
      _ => 'https://facebook.com/username/posts/...',
    };

/// Facebook / TikTok bắt buộc link; Zalo để trống được. Có dán thì phải là link.
String? kiemTraLink(String nenTang, String? v) {
  final s = v?.trim() ?? '';
  if (s.isEmpty) {
    return nenTang == 'ZALO' ? null : 'Dán link bài trên ${tenNenTang(nenTang)} để Admin mở ra kiểm tra';
  }
  if (!s.toLowerCase().startsWith('http')) return 'Link phải bắt đầu bằng http';
  return null;
}

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

  /// FACEBOOK / TIKTOK / ZALO. Facebook và TikTok có link từng bài nên bắt buộc
  /// dán link; Zalo không có link công khai nên không bắt (máy chủ kiểm lại).
  String _nenTang = 'FACEBOOK';
  bool get _canLink => _nenTang != 'ZALO';

  /// Hashtag công ty — chỉ để nhắc, không bắt buộc, không chặn gửi. Hashtag
  /// khác mỗi người tự thêm. (Bỏ #bds, #kpi theo yêu cầu 11/11/2026.)
  static const List<String> _goiYHashtag = ["#trilongland", "#kientaosubenvung"];

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
      platform: _nenTang,
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
      locTuChoi: true,
      onFetchHistory: (date) => controller.fetchHistory(date),
      onFetchMonth: (month) => taiLichSuThang('/social-posts/my-posts', month),
      thoiDiemCua: (item) => item['submittedAt']?.toString(),
      emptyMessageThang: 'Không có bài post nào trong tháng này.',
      loaiDongBo: DongBo.baiDang,
      emptyMessage: 'Không có bài post nào trong ngày này.',
      itemBuilder: (item, index) {
        final isVideo = item['contentType'] == 'VIDEO';
        final loai = isVideo ? 'Video xây kênh' : 'Bài đăng';
        final nenTang = tenNenTang(item['platform']?.toString());
        final status = (item['status'] ?? 'PENDING').toString();
        return TheLichSu(
          anh: item['screenshotUrl']?.toString(),
          bieuTuong: isVideo ? Icons.videocam_rounded : Icons.article_rounded,
          tieuDe: '$loai · $nenTang',
          phu: (item['link'] ?? '').toString(),
          noiDung: item['caption']?.toString(),
          submittedAt: item['submittedAt'],
          trangThai: status,
          lyDoTuChoi: lyDoTuChoiCua(item),
          onTap: () => xemChiTietLichSu(
            tieuDe: loai,
            lyDoTuChoi: lyDoTuChoiCua(item),
            submittedAt: item['submittedAt'],
            trangThai: status,
            nhomDiem: 'Lan tỏa',
            thongTin: [MapEntry('Nền tảng', nenTang)],
            noiDung: item['caption']?.toString(),
            link: item['link']?.toString(),
            anh: item['screenshotUrl']?.toString(),
          ),
        );
      },
    );
  }

  Widget _chipNenTang(String value, String label, IconData icon) {
    final bool selected = _nenTang == value;
    return GestureDetector(
      onTap: () => setState(() => _nenTang = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F2C59) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF0F2C59) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: selected ? Colors.white : const Color(0xFF1B3B6F)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : const Color(0xFF1B3B6F),
                  )),
            ),
          ],
        ),
      ),
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
                    "Đăng bài truyền thông dự án lên Facebook / TikTok / Zalo rồi gửi ảnh chụp màn hình bài đăng. Facebook và TikTok cần dán link bài; Zalo không cần. Bài được duyệt +5 điểm nhóm Lan tỏa.",
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

                  // Đăng trên nền tảng nào
                  const Text("ĐĂNG TRÊN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _chipNenTang('FACEBOOK', 'Facebook', Icons.facebook)),
                      const SizedBox(width: 8),
                      Expanded(child: _chipNenTang('TIKTOK', 'TikTok', Icons.music_note_rounded)),
                      const SizedBox(width: 8),
                      Expanded(child: _chipNenTang('ZALO', 'Zalo', Icons.chat_bubble_outline_rounded)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Đường dẫn bài đăng
                  Text(_canLink ? "LINK BÀI VIẾT (BẮT BUỘC)" : "LINK BÀI VIẾT (KHÔNG BẮT BUỘC)",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: goiYLink(_nenTang),
                      prefixIcon: const Icon(Icons.link, color: Color(0xFF1B3B6F)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (v) => kiemTraLink(_nenTang, v),
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

                  // Hashtag gợi ý — không bắt buộc
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
                          "HASHTAG (KHÔNG BẮT BUỘC)",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB8860B)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Nên có 2 hashtag công ty dưới đây, hashtag khác tùy bạn thêm.",
                          style: TextStyle(fontSize: 11, color: Color(0xFF8A6D1F)),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          runSpacing: 6,
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
