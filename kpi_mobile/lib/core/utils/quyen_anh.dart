import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

/// Người dùng đã từ chối quyền camera hoặc thư viện ảnh.
///
/// iOS chỉ hỏi quyền MỘT lần: lỡ bấm "Không cho phép" là từ đó mỗi lần mở
/// camera image_picker ném `camera_access_denied`, không hỏi lại nữa — phải tự
/// vào Cài đặt bật lên. Trước đây app in thẳng chuỗi PlatformException ra màn
/// hình, nhân viên đọc không hiểu phải làm gì.
bool laLoiThieuQuyenAnh(Object e) =>
    e is PlatformException && (e.code == 'camera_access_denied' || e.code == 'photo_access_denied');

/// Gặp lỗi thiếu quyền thì hiện hướng dẫn kèm nút mở thẳng trang Cài đặt của
/// app và trả về true; lỗi khác trả về false để nơi gọi tự báo như cũ.
Future<bool> xuLyLoiQuyenAnh(Object e) async {
  if (!laLoiThieuQuyenAnh(e)) return false;
  final camera = (e as PlatformException).code == 'camera_access_denied';
  await Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        camera ? 'Chưa cho phép dùng camera' : 'Chưa cho phép truy cập ảnh',
        style: const TextStyle(color: Color(0xFF0F2C59), fontWeight: FontWeight.bold, fontSize: 17),
      ),
      content: Text(
        camera
            ? 'App chưa được phép mở camera.\n\nVào Cài đặt → Trí Long Land → bật Camera, rồi quay lại chụp lần nữa.'
            : 'App chưa được phép mở thư viện ảnh.\n\nVào Cài đặt → Trí Long Land → Ảnh → chọn "Tất cả ảnh", rồi quay lại chọn lần nữa.',
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Để sau', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () {
            Get.back();
            Geolocator.openAppSettings();
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F2C59), foregroundColor: Colors.white),
          child: const Text('Mở Cài đặt'),
        ),
      ],
    ),
  );
  return true;
}
