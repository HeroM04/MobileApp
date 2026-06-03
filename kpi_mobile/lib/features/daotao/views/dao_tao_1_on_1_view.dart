import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/training_controller.dart';
import '../../../data/services/upload_service.dart';

class DaoTao1On1View extends StatefulWidget {
  @override
  _DaoTao1On1ViewState createState() => _DaoTao1On1ViewState();
}

class _DaoTao1On1ViewState extends State<DaoTao1On1View> {
  final TrainingController controller = Get.find<TrainingController>();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isSubmitting = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Thêm hình ảnh chứng minh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceButton(
                  icon: Icons.camera_alt,
                  label: 'Chụp ảnh',
                  color: const Color(0xFF0F2C59),
                  onTap: () {
                    Get.back();
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceButton(
                  icon: Icons.photo_library,
                  label: 'Thư viện',
                  color: const Color(0xFFD4AF37),
                  onTap: () {
                    Get.back();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập nội dung đào tạo 1-1', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String photoUrl = '';
      if (_image != null) {
        final uploadService = UploadService();
        photoUrl = await uploadService.uploadFile(_image!) ?? '';
      }

      bool success = await controller.submitOneOnOne(_contentController.text.trim(), photoUrl);
      if (success) {
        Get.back();
        Get.snackbar('Thành công', 'Đã nộp báo cáo và cộng 5 điểm KPI', backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Thất bại', 'Có lỗi xảy ra', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể nộp báo cáo: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo Đào tạo 1-1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF0F2C59),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nội dung Đào tạo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung, kiến thức đã trao đổi...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hình ảnh minh chứng (Tùy chọn)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _showImagePickerModal,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Bấm để chọn ảnh', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
            ),
            if (_image != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _image = null),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  label: const Text('Xóa ảnh', style: TextStyle(color: Colors.red)),
                ),
              ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2C59),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Nộp Báo Cáo (+5 KPI)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
