// Dựng ảnh mã QR tải app Android để in / gửi nhóm Zalo.
//
//   flutter test test_thu_cong/ma_qr_android_test.dart --update-goldens
//
// Ảnh ra ở test_thu_cong/anh/ma_qr_android.png. Mã trỏ tới link "latest" của
// GitHub Releases nên LUÔN tải bản mới nhất — build bản mới không phải in lại.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpi_mobile/core/utils/cap_nhat_app.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _navy = Color(0xFF14365C);
const _xam = Color(0xFF475569);

String get linkApkMoiNhat => 'https://github.com/$khoPhatHanh/releases/latest/download/kpi-trilong.apk';

Future<void> _napPhong() async {
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  final thuMuc = '$sdk/bin/cache/artifacts/material_fonts';
  Future<ByteData> doc(String ten) async => ByteData.view((await File('$thuMuc/$ten').readAsBytes()).buffer);
  final p = FontLoader('Roboto');
  for (final f in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']) {
    p.addFont(doc(f));
  }
  await p.load();
}

Widget _buoc(String so, String chu) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: _navy, width: 1.5), borderRadius: BorderRadius.circular(13)),
            child: Text(so, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _navy)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(chu, style: const TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF1E293B)))),
        ],
      ),
    );

void main() {
  setUpAll(_napPhong);

  testWidgets('mã QR tải app Android', (tester) async {
    tester.view.physicalSize = const Size(600 * 3, 880 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(40, 40, 40, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TRÍ LONG LAND', style: TextStyle(fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold, color: _xam)),
              const SizedBox(height: 6),
              const Text('Tải app KPI cho Android',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _navy)),
              const SizedBox(height: 4),
              const Text('Quét mã để tải bản mới nhất', style: TextStyle(fontSize: 16, color: _xam)),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(12)),
                  child: QrImageView(
                    data: linkApkMoiNhat,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                    size: 340,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              _buoc('1', 'Mở Camera hoặc Zalo, quét mã. Quét bằng Zalo thì bấm dấu ba chấm, chọn "Mở bằng trình duyệt".'),
              _buoc('2', 'Tải file kpi-trilong.apk (khoảng 100 MB), xong bấm Mở.'),
              _buoc('3', 'Android hỏi "Cho phép cài ứng dụng từ nguồn này" thì bật lên, quay lại bấm Cài đặt.'),
              _buoc('4', 'Mở app, đăng nhập bằng số điện thoại.'),
              const Spacer(),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 6),
              const Text('Mã này luôn tải bản mới nhất. Đã cài rồi thì app tự báo khi có bản mới.',
                  style: TextStyle(fontSize: 12.5, color: _xam)),
              const SizedBox(height: 2),
              const Text('iPhone: cài qua TestFlight theo link Admin gửi.', style: TextStyle(fontSize: 12.5, color: _xam)),
            ],
          ),
        ),
      ),
    ));
    await tester.pump();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('anh/ma_qr_android.png'));
  });
}
