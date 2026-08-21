import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Hiện một thông báo trượt từ trên xuống.
///
/// Thay cho việc gọi thẳng [Get.snackbar] ở 65 chỗ rải rác, mỗi chỗ một kiểu.
/// Gom về một chỗ để sửa hai thứ khiến thông báo cảm giác chậm và trễ:
///
/// 1. **Hiệu ứng trượt quá chậm.** GetX mặc định để 1 giây cho cả lúc trượt vào
///    lẫn trượt ra. Người dùng thao tác xong phải nhìn thông báo bò xuống mất
///    một giây rồi lại bò lên mất một giây nữa. Nay còn 220 mili giây — vẫn
///    thấy chuyển động nhưng không phải chờ.
///
/// 2. **Thông báo xếp hàng chờ nhau.** GetX chỉ hiện một cái tại một thời điểm,
///    cái sau nằm trong hàng đợi. Một màn hình bắn ra hai ba thông báo liên
///    tiếp, mà có cái đặt tới 8 giây, thì cái cuối phải đợi cả chục giây mới
///    xuất hiện — đúng cảm giác "bị trễ". Nay thông báo mới đóng cái đang hiện
///    rồi lên ngay.
void snack(
  String tieuDe,
  String noiDung, {
  Color? backgroundColor,
  Color? colorText,
  Duration? duration,
  Widget? icon,
  EdgeInsets? margin,
  bool? isDismissible,
  SnackPosition? snackPosition,
}) {
  if (Get.isSnackbarOpen) Get.closeAllSnackbars();

  Get.snackbar(
    tieuDe,
    noiDung,
    backgroundColor: backgroundColor,
    colorText: colorText,
    icon: icon,
    margin: margin ?? const EdgeInsets.fromLTRB(12, 12, 12, 0),
    isDismissible: isDismissible ?? true,
    snackPosition: snackPosition ?? SnackPosition.TOP,
    animationDuration: const Duration(milliseconds: 220),
    forwardAnimationCurve: Curves.easeOutCubic,
    reverseAnimationCurve: Curves.easeInCubic,
    // Mặc định 3 giây: đủ đọc một câu ngắn. Thông báo lỗi cần đọc kỹ thì nơi gọi
    // tự truyền dài hơn.
    duration: duration ?? const Duration(seconds: 3),
  );
}
