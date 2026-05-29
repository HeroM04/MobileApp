import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/views/login_view.dart';
import 'features/shell/views/shell_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo AuthController là permanent để tồn tại suốt vòng đời app
  final authController = Get.put(AuthController(), permanent: true);
  
  // Đợi kiểm tra trạng thái login trước khi khởi chạy giao diện
  await authController.checkLoginStatus();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    
    return GetMaterialApp(
      title: 'Trí Long KPI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF0F2C59),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F2C59),
          primary: const Color(0xFF0F2C59),
          secondary: const Color(0xFFD4AF37),
        ),
      ),
      // Lắng nghe thay đổi của isLoggedIn để vẽ giao diện phù hợp
      home: Obx(() => authController.isLoggedIn.value 
          ? ShellView() 
          : const LoginView()),
    );
  }
}