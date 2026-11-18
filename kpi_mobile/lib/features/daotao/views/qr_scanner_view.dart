import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class QrScannerView extends StatefulWidget {
  const QrScannerView({Key? key}) : super(key: key);

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR', style: TextStyle(color: Color(0xFF0F2C59), fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0F2C59)),
        actions: [
          IconButton(
            color: const Color(0xFF0F2C59),
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                  default:
                    return const Icon(Icons.flash_off);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: const Color(0xFF0F2C59),
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                  default:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            // Mặc định thư viện chỉ hiện màn đen + biểu tượng lỗi, không nói gì —
            // bị chặn quyền camera là nhân viên đứng nhìn, không biết bật ở đâu.
            errorBuilder: (context, loi) => LoiCameraQuetMa(maLoi: loi.errorCode),
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _isScanned = true;
                  final String code = barcode.rawValue!;
                  Get.back(result: code); // Trả kết quả code về trang trước
                  break;
                }
              }
            },
          ),
          // Khung ngắm + lời nhắc — ẩn khi không mở được camera để khỏi đè lên lời hướng dẫn
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: cameraController,
            builder: (context, state, _) => state.error != null
                ? const SizedBox.shrink()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      // Khung viền UI quét mã
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFD4AF37), width: 3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  width: 240,
                                  height: 2,
                                  color: Colors.red.withOpacity(0.5),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        bottom: 80,
                        left: 0,
                        right: 0,
                        child: Text(
                          "Đưa mã QR của lớp học vào khung hình",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Màn thay cho khung camera khi không mở được camera để quét mã.
class LoiCameraQuetMa extends StatelessWidget {
  final MobileScannerErrorCode maLoi;
  const LoiCameraQuetMa({super.key, required this.maLoi});

  @override
  Widget build(BuildContext context) {
    final thieuQuyen = maLoi == MobileScannerErrorCode.permissionDenied;
    final (tieuDe, noiDung) = switch (maLoi) {
      MobileScannerErrorCode.permissionDenied => (
          'Chưa cho phép dùng camera',
          'App cần camera để quét mã QR điểm danh.\n\n'
              'Vào Cài đặt → Trí Long Land → bật Camera, rồi quay lại bấm quét mã lần nữa.',
        ),
      MobileScannerErrorCode.unsupported => (
          'Máy không quét được mã',
          'Điện thoại này không mở được camera để quét. Nhờ người phụ trách lớp điểm danh tay cho bạn.',
        ),
      _ => (
          'Không mở được camera',
          'Có thể ứng dụng khác đang dùng camera (gọi video, Zalo...). '
              'Tắt ứng dụng đó, quay lại rồi bấm quét mã lần nữa.',
        ),
    };

    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(thieuQuyen ? Icons.no_photography_outlined : Icons.videocam_off_outlined,
                  size: 48, color: const Color(0xFF0F2C59)),
              const SizedBox(height: 16),
              Text(tieuDe,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF0F2C59), fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 10),
              Text(noiDung,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF334155), fontSize: 14, height: 1.45)),
              const SizedBox(height: 20),
              if (thieuQuyen)
                ElevatedButton.icon(
                  onPressed: Geolocator.openAppSettings,
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('Mở Cài đặt'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2C59), foregroundColor: Colors.white),
                ),
              TextButton(onPressed: () => Get.back(), child: const Text('Quay lại')),
            ],
          ),
        ),
      ),
    );
  }
}
