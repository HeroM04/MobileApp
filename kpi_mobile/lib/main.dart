import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Thêm để dùng kReleaseMode
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Thêm dotenv
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/views/login_view.dart';
import 'features/shell/views/shell_view.dart';
import 'features/thucchien/controllers/thuc_chien_controller.dart';
import 'data/services/websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nền Firebase cho thông báo đẩy. Đọc cấu hình từ google-services.json
  // (Android) và GoogleService-Info.plist (iOS) đã đặt sẵn trong dự án. Bọc
  // try để nếu thiếu cấu hình thì app vẫn chạy, chỉ là không có thông báo đẩy.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (kDebugMode) print('[Firebase] Không khởi tạo được: $e');
  }

  // Load biến môi trường tùy theo chế độ chạy (Release = Prod, Debug = Dev)
  const envFile = kReleaseMode ? '.env.production' : '.env.development';
  await dotenv.load(fileName: envFile);

  // Khởi tạo AuthController là permanent để tồn tại suốt vòng đời app
  final authController = Get.put(AuthController(), permanent: true);
  
  // Đợi kiểm tra trạng thái login trước khi khởi chạy giao diện
  await authController.checkLoginStatus();

  runApp(const MyApp());
}

/// Khi người dùng chuyển sang ứng dụng khác hoặc khoá màn hình thì cắt hết
/// hoạt động mạng chạy ngầm, mở lại app mới nối lại.
///
/// Trước đây kênh WebSocket và bộ dò mạng của màn hình Thực chiến vẫn chạy tiếp
/// dù app nằm trong nền, nên sóng điện thoại không bao giờ được ngủ — đây là
/// nguyên nhân chính làm tụt pin.
class _AppLifecycle extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final rongNen = state == AppLifecycleState.paused
        || state == AppLifecycleState.detached
        || state == AppLifecycleState.hidden;

    if (rongNen) {
      WebSocketService().disconnect();
      if (Get.isRegistered<ThucChienController>()) {
        Get.find<ThucChienController>().stopAutoSync();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        final uid = auth.currentUser['userId'];
        if (auth.isLoggedIn.value && uid != null) WebSocketService().connect(uid);
      }
      if (Get.isRegistered<ThucChienController>()) {
        Get.find<ThucChienController>().startAutoSync();
      }
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _lifecycle = _AppLifecycle();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycle);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycle);
    super.dispose();
  }

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
      // Bấm ra chỗ trống bất kỳ là ẩn bàn phím. Đặt ở đây một lần cho cả app,
      // thay vì phải bọc lại ở từng màn hình có ô nhập.
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          final focus = FocusManager.instance.primaryFocus;
          if (focus != null && focus.hasFocus) focus.unfocus();
        },
        child: child,
      ),
      // Lắng nghe thay đổi của isLoggedIn để vẽ giao diện phù hợp
      home: Obx(() => authController.isLoggedIn.value
          ? ShellView()
          : const LoginView()),
    );
  }
}