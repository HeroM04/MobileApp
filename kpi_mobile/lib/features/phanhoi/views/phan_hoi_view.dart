import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/phan_hoi_controller.dart';
import '../../../shared/widgets/history_date_list_view.dart';

class PhanHoiView extends StatefulWidget {
  const PhanHoiView({super.key});

  @override
  State<PhanHoiView> createState() => _PhanHoiViewState();
}

class _PhanHoiViewState extends State<PhanHoiView> {
  final PhanHoiController controller = Get.put(PhanHoiController());
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  String _selectedCategory = "Khiếu nại điểm KPI";
  final List<String> _categories = [
    "Khiếu nại điểm KPI",
    "Góp ý tính năng ứng dụng",
    "Ý kiến đóng góp phòng ban",
    "Báo cáo sự cố kỹ thuật",
  ];

  int _rating = 5;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await controller.submitFeedback(
      title: _titleController.text,
      category: _selectedCategory,
      content: _contentController.text,
      rating: _rating,
    );

    if (success) {
      Get.snackbar(
        "Gửi thành công",
        "Phản hồi đã được truyền qua hệ thống đến Ban quản lý. Ban giám đốc/HR sẽ phản hồi bạn sớm nhất!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      setState(() {
        _titleController.clear();
        _contentController.clear();
        _rating = 5;
      });
    } else {
      Get.snackbar("Lỗi", "Không thể gửi phản hồi, vui lòng thử lại sau.", backgroundColor: Colors.red, colorText: Colors.white);
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
                  icon: Icon(Icons.edit_note_rounded),
                  text: "GỬI PHẢN HỒI",
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
                _buildSubmitFormTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitFormTab() {
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
                    "Gửi phản hồi kiến nghị",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Nếu có khiếu nại về chấm công, lỗi hệ thống hoặc kiến nghị nghiệp vụ, hãy gửi ngay đến ban quản lý Admin.",
                    style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
                  ),
                  const Divider(height: 24),

                  // Chủ đề phản hồi
                  const Text("TIÊU ĐỀ PHẢN HỒI", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: "Ví dụ: Khiếu nại chấm công ngày 20/05 bị thiếu...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (v) => v == null || v.isEmpty ? "Vui lòng điền tiêu đề phản hồi" : null,
                  ),
                  const SizedBox(height: 16),

                  // Danh mục phản hồi
                  const Text("DANH MỤC PHẢN HỒI", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nội dung phản hồi
                  const Text("NỘI DUNG CHI TIẾT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _contentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Trình bày cụ thể nội dung khiếu nại hoặc ý kiến đóng góp của bạn...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    validator: (v) => v == null || v.isEmpty ? "Vui lòng nhập nội dung chi tiết" : null,
                  ),
                  const SizedBox(height: 16),

                  // Đánh giá sao
                  const Text("MỨC ĐỘ HÀI LÒNG / ĐÁNH GIÁ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Nút submit
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                    }
                    return ElevatedButton.icon(
                      onPressed: _submitFeedback,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: const Text(
                        "GỬI PHẢN HỒI ĐẾN ADMIN",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2C59),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
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

  Widget _buildHistoryTab() {
    return HistoryDateListView(
      onFetchHistory: (date) => controller.fetchHistory(date),
      emptyMessage: 'Không có phản hồi nào trong ngày này.',
      itemBuilder: (fb, index) {
        final title = fb['title'] ?? 'Góp ý';
        final category = fb['category'] ?? 'Góp ý';
        final content = fb['content'] ?? '';
        final status = fb['status'] ?? 'UNREAD';
        final createdAtStr = fb['createdAt'];
        final rating = fb['rating'] ?? 5;
        final String? adminReply = fb['adminReply'];
        final bool hasReply = adminReply != null && adminReply.toString().trim().isNotEmpty;
        
        final isResolved = status == 'RESOLVED' || hasReply;
        final statusText = isResolved ? "Dạ xử lý" : "Chờ xử lý";
        final badgeColor = isResolved ? Colors.green : Colors.orange;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2C59).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (starIndex) =>
                            Icon(starIndex < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 14, color: Colors.amber)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                    const SizedBox(height: 4),
                    Text(_formatDateTime(createdAtStr), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              const Divider(height: 24, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(content, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4)),
                ),
              ),
              if (hasReply) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border(left: BorderSide(color: Colors.green.shade600, width: 3.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.support_agent_rounded, size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 6),
                            Text('Phản hồi từ ${fb['resolvedByFullName'] ?? 'Ban quản lý'}:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(fb['adminReply'], style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.4)),
                      ],
                    ),
                  ),
                ),
              ] else const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }



  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dt = DateTime.parse(dateTimeStr);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) {
      return dateTimeStr;
    }
  }
}
