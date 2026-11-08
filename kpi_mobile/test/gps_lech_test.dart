import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kpi_mobile/features/checkin/controllers/checkin_controller.dart';

/// GPS lệch nhiều (dưới hầm xe, tắt "Vị trí chính xác") làm người đứng ở công
/// ty bị báo ngoài phạm vi: app đọc lại GPS vài giây, lấy lần chính xác nhất.
void main() {
  Position vt(double saiSo, {bool gia = false, double lat = 20.99}) => Position(
        latitude: lat,
        longitude: 105.78,
        timestamp: DateTime.now(),
        accuracy: saiSo,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
        isMocked: gia,
      );

  test('lần đọc đầu lệch 1800 m → lấy lần chính xác nhất, dừng khi đủ tin', () async {
    final docThem = Stream.fromIterable([vt(900, lat: 1), vt(35, lat: 2), vt(10, lat: 3)]);
    final kq = await CheckinController.chonViTriTotNhat(vt(1800), docThem);
    expect(kq.accuracy, 35); // ≤ 50 m là đủ tin, không chờ thêm
    expect(kq.latitude, 2);
  });

  test('đọc mãi vẫn yếu → giữ lần tốt nhất trong thời gian chờ', () async {
    final docThem = Stream.fromIterable([vt(1200), vt(400), vt(700)]);
    final kq = await CheckinController.chonViTriTotNhat(vt(1800), docThem);
    expect(kq.accuracy, 400);
  });

  test('không có lần đọc mới → hết giờ chờ thì dùng lần đầu, không treo', () async {
    final treo = StreamController<Position>();
    final kq = await CheckinController.chonViTriTotNhat(vt(1800), treo.stream,
        cho: const Duration(milliseconds: 200));
    expect(kq.accuracy, 1800);
    await treo.close();
  });

  test('lần đọc lại là vị trí giả → trả luôn để chặn', () async {
    final docThem = Stream.fromIterable([vt(20, gia: true)]);
    final kq = await CheckinController.chonViTriTotNhat(vt(1800), docThem);
    expect(kq.isMocked, isTrue);
  });

  test('câu nhắc: tắt Vị trí chính xác / GPS yếu / GPS tốt (thật sự ở xa)', () {
    expect(CheckinController.goiYNgoaiPhamVi(ganDung: true, saiSo: 2000), contains('Vị trí chính xác'));
    expect(CheckinController.goiYNgoaiPhamVi(ganDung: false, saiSo: 640), contains('640 m'));
    expect(CheckinController.goiYNgoaiPhamVi(ganDung: false, saiSo: 12), isEmpty);
  });
}
