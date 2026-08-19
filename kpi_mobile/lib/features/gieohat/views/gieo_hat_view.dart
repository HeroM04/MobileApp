import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/referral_controller.dart';

/// Màn hình "Gieo hạt" — nhân sự giới thiệu người mới vào công ty.
///
/// Gửi đơn xong Admin duyệt trên WebAdmin thì tài khoản của người được giới
/// thiệu được mở. Một tháng sau, nếu người đó vẫn còn làm thì người giới thiệu
/// được +15đ nhóm Lan tỏa.
class GieoHatView extends StatefulWidget {
  const GieoHatView({super.key});

  @override
  State<GieoHatView> createState() => _GieoHatViewState();
}

class _GieoHatViewState extends State<GieoHatView> {
  final ReferralController controller = Get.put(ReferralController());
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  static const Color _navy = Color(0xFF0F2C59);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final err = await controller.submit(
      name: _nameController.text,
      phone: _phoneController.text,
      note: _noteController.text,
    );
    if (!mounted) return;

    if (err == null) {
      _nameController.clear();
      _phoneController.clear();
      _noteController.clear();
      Get.snackbar(
        'Đã gửi đơn giới thiệu',
        'Admin sẽ xét duyệt và mở tài khoản cho người bạn giới thiệu.',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar('Không gửi được', err,
          backgroundColor: Colors.redAccent, colorText: Colors.white);
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
              indicatorColor: _navy,
              labelColor: _navy,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(icon: Icon(Icons.person_add_alt_1_rounded), text: "GIỚI THIỆU"),
                Tab(icon: Icon(Icons.history_rounded), text: "ĐƠN ĐÃ GỬI"),
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

  Widget _buildSubmitTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRuleCard(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: _navy.withOpacity(0.03),
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
                  const Text('Thông tin người được giới thiệu',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navy)),
                  const Divider(height: 24),

                  const Text('HỌ VÀ TÊN',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: Nguyễn Văn A',
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1B3B6F)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
                  ),
                  const SizedBox(height: 16),

                  const Text('SỐ ĐIỆN THOẠI',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: '09xxxxxxxx',
                      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF1B3B6F)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      helperText: 'Số này sẽ là tài khoản đăng nhập của bạn ấy',
                      helperStyle: const TextStyle(fontSize: 11),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                      if (!RegExp(r'^0\d{8,10}$').hasMatch(v.trim())) {
                        return 'Số điện thoại không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text('GIỚI THIỆU THÊM',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Quen biết thế nào, kinh nghiệm gì, vì sao phù hợp với công ty...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),

                  Obx(() => ElevatedButton.icon(
                        onPressed: controller.isSubmitting.value ? null : _submit,
                        icon: controller.isSubmitting.value
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, color: Colors.white),
                        label: Text(
                          controller.isSubmitting.value ? 'ĐANG GỬI...' : 'GỬI ĐƠN GIỚI THIỆU',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: _navy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRuleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, Color(0xFF1B3B6F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.eco_rounded, color: Color(0xFFD4AF37), size: 32),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gieo hạt nhân sự mới — +15đ',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 6),
                Text(
                  'Giới thiệu người vào công ty, một tháng sau người đó vẫn còn làm thì bạn '
                  'được +15đ nhóm Lan tỏa. Ví dụ giới thiệu ngày 15/7, đến 15/8 bạn ấy vẫn '
                  'đi làm thì bạn được cộng điểm.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.mySubmissions.isEmpty) {
        return RefreshIndicator(
          onRefresh: controller.loadMine,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 120),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.eco_outlined, size: 56, color: Color(0xFFCBD5E1)),
                    SizedBox(height: 12),
                    Text('Bạn chưa giới thiệu ai vào công ty.',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.loadMine,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: controller.mySubmissions.length,
          itemBuilder: (context, i) => _buildCard(controller.mySubmissions[i]),
        ),
      );
    });
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final status = (r['status'] ?? 'PENDING').toString();
    final rewarded = r['rewardGranted'] == true;
    final meta = _statusMeta(status, rewarded);
    final canCancel = status == 'PENDING';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(meta.icon, size: 20, color: meta.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['candidateName']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(r['candidatePhone']?.toString() ?? '',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: meta.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(meta.label,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold, color: meta.color)),
                ),
              ],
            ),
            if ((r['note']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r['note'].toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.35)),
            ],
            if (status == 'APPROVED' && !rewarded && r['rewardDate'] != null) ...[
              const SizedBox(height: 6),
              Text('Được +15đ từ ngày ${_fmt(r['rewardDate']?.toString())} nếu bạn ấy vẫn còn làm',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF1B3B6F))),
            ],
            if ((r['reviewNote']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Admin: ${r['reviewNote']}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
            if (canCancel)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final err = await controller.cancel(r['id'] as int);
                    if (err != null) {
                      Get.snackbar('Không rút được đơn', err,
                          backgroundColor: Colors.redAccent, colorText: Colors.white);
                    }
                  },
                  icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                  label: const Text('Rút đơn',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(String? ymd) {
    if (ymd == null || ymd.length < 10) return '—';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(ymd));
    } catch (_) {
      return ymd;
    }
  }

  _StatusMeta _statusMeta(String status, bool rewarded) {
    if (status == 'APPROVED') {
      return rewarded
          ? const _StatusMeta('Đã +15đ', Colors.green, Icons.verified_rounded)
          : const _StatusMeta('Chờ đủ tháng', Color(0xFF1B3B6F), Icons.hourglass_bottom_rounded);
    }
    if (status == 'REJECTED') {
      return const _StatusMeta('Bị từ chối', Colors.grey, Icons.cancel_outlined);
    }
    return const _StatusMeta('Chờ duyệt', Colors.orange, Icons.hourglass_top_rounded);
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusMeta(this.label, this.color, this.icon);
}
