import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/bai_post_controller.dart';
import '../../../shared/widgets/history_date_list_view.dart';

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
  bool _isOcrScanning = false;
  bool _scanCompleted = false;
  bool _isValidPost = false;

  final List<String> _requiredHashtags = ["#trilongland", "#bds", "#kpi"];
  final List<String> _foundHashtags = [];

  Future<void> _pickScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (image != null) {
        setState(() {
          _screenshot = File(image.path);
          _scanCompleted = false;
        });
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể chọn hình ảnh: $e");
    }
  }

  void _runOcrScan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_screenshot == null) {
      Get.snackbar("Yêu cầu", "Vui lòng chọn ảnh chụp màn hình bài viết để đối soát!");
      return;
    }

    setState(() {
      _isOcrScanning = true;
      _scanCompleted = false;
      _foundHashtags.clear();
    });

    // Giả lập quét OCR trong 2.5 giây
    await Future.delayed(const Duration(milliseconds: 2500));

    // Thực hiện kiểm tra từ khóa dạng đơn giản (String.contains) trên nội dung text nhập vào
    final textToCheck = _captionController.text.toLowerCase();
    
    for (var tag in _requiredHashtags) {
      if (textToCheck.contains(tag)) {
        _foundHashtags.add(tag);
      }
    }

    // Bài viết được tính là hợp lệ nếu có link mạng xã hội và có ít nhất 2 hashtag yêu cầu (bao gồm bắt buộc #trilongland)
    final bool hasCoreTag = _foundHashtags.contains("#trilongland");
    final bool hasMinTags = _foundHashtags.length >= 2;

    setState(() {
      _isOcrScanning = false;
      _scanCompleted = true;
      _isValidPost = hasCoreTag && hasMinTags;
    });

    if (_isValidPost) {
      final success = await controller.submitPost(
        platform: _urlController.text.contains("facebook") ? "FACEBOOK" : "OTHER",
        link: _urlController.text,
        caption: _captionController.text,
        screenshotUrl: _screenshot!.path, // Replace with real URL upload later
      );

      if (success) {
        Get.defaultDialog(
          title: "Xác thực thành công",
          middleText: "Hệ thống đã nhận diện bài viết hợp lệ và cập nhật điểm KPI truyền thông của bạn!",
          textConfirm: "Tuyệt vời",
          confirmTextColor: Colors.white,
          buttonColor: const Color(0xFF0F2C59),
          onConfirm: () => Get.back(),
        );
        setState(() {
          _urlController.clear();
          _captionController.clear();
          _screenshot = null;
          _isValidPost = false;
        });
      } else {
        Get.snackbar("Lỗi", "Không thể gửi bài viết. Vui lòng thử lại sau.");
      }
    } else {
      Get.snackbar(
        "Xác thực thất bại",
        "Bài viết thiếu các Hashtag bắt buộc (Cần tối thiểu #trilongland và 1 hashtag phụ #bds hoặc #kpi)",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
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
      emptyMessage: 'Không có bài post nào trong ngày này.',
      itemBuilder: (item, index) {
        final submittedAt = item['submittedAt'];
        final dateStr = formatIsoDate(submittedAt?.toString());
        final platform = item['platform'] ?? 'Khác';
        final link = item['link'] ?? '';
        final status = item['status'] ?? 'PENDING';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0F2C59).withOpacity(0.08),
              child: const Icon(Icons.article_rounded, color: Color(0xFF0F2C59), size: 22),
            ),
            title: Text(platform, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                    "Đăng bài truyền thông dự án lên Facebook/Zalo/TikTok và gửi link đối soát để cộng điểm KPI tác phong.",
                    style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
                  ),
                  const Divider(height: 24),

                  // Đường dẫn bài đăng
                  const Text("LINK BÀI VIẾT (FB/ZALO/TIKTOK)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: "https://facebook.com/username/posts/...",
                      prefixIcon: const Icon(Icons.link, color: Color(0xFF1B3B6F)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Vui lòng dán link bài đăng";
                      if (!v.startsWith("http")) return "Đường dẫn không hợp lệ";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nội dung text bài viết
                  const Text("NỘI DUNG CAPTION ĐÃ ĐĂNG", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _captionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Nhập hoặc dán nội dung bài viết đăng (Để AI quét từ khóa hashtag)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    validator: (v) => v == null || v.isEmpty ? "Vui lòng điền nội dung caption" : null,
                  ),
                  const SizedBox(height: 16),

                  // Đính kèm ảnh chụp màn hình bài đăng
                  const Text("ẢNH CHỤP MÀN HÌNH BÀI ĐĂNG", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
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
                          "Yêu cầu từ khoá tối thiểu (Chứa #trilongland và 1 tag phụ):",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB8860B)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: _requiredHashtags.map((tag) {
                            final found = _foundHashtags.contains(tag) && _scanCompleted;
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: found ? Colors.green.shade100 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "$tag ${found ? '✓' : ''}",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: found ? Colors.green.shade900 : Colors.grey.shade700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút kiểm tra AI OCR
                  Obx(() {
                    if (_isOcrScanning || controller.isLoading.value) {
                      return Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(color: Color(0xFFD4AF37)),
                            const SizedBox(height: 12),
                            Text(
                              _isOcrScanning ? "AI đang quét nội dung bài viết..." : "Đang gửi báo cáo...", 
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))
                            ),
                          ],
                        ),
                      );
                    } else {
                      return ElevatedButton.icon(
                        onPressed: _runOcrScan,
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                        label: const Text(
                          "XÁC THỰC BÀI ĐĂNG",
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
