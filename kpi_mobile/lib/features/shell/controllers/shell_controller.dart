import 'package:get/get.dart';

class ShellController extends GetxController {
  // Chỉ số tab hiện tại
  var selectedIndex = 0.obs;

  // Danh sách các đề mục trong Sidebar
  final List<String> menuItems = [
    "Trang chủ",
    "Chấm công",
    "Thực chiến",
    "Bài post",
    "Đào tạo",
    "Phản hồi",
    "Chốt căn",
    "Trang cá nhân",
  ];

  void changeMenuIndex(int index) {
    selectedIndex.value = index;
  }
}
