import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpi_mobile/core/network/api_client.dart';

/// Máy chủ giả: [ketLan] lần đầu không mở được kết nối, sau đó trả lời 200.
class _MayChuGia implements HttpClientAdapter {
  int ketLan;
  int soLan = 0;
  int maTraVe;
  final noiDungNhan = <String>[];
  _MayChuGia({this.ketLan = 1, this.maTraVe = 200});

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    soLan++;
    // Đọc hết thân yêu cầu như adapter thật — FormData đọc lần hai mà không
    // sao chép là hỏng ở đây
    if (requestStream != null) {
      noiDungNhan.add(utf8.decode(await requestStream.expand((b) => b).toList(), allowMalformed: true));
    }
    if (soLan <= ketLan) {
      throw DioException.connectionTimeout(timeout: const Duration(seconds: 12), requestOptions: o);
    }
    return ResponseBody.fromString('{"status":"SUCCESS"}', maTraVe, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://may-chu-gia/api/v1');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (c) async => null);
  });

  test('kết nối kẹt lần đầu → tự mở kết nối mới, lần hai thành công', () async {
    final may = _MayChuGia(ketLan: 1);
    ApiClient.dio.httpClientAdapter = may;
    final r = await ApiClient.dio.get('/kpi-scores/me');
    expect(r.data['status'], 'SUCCESS');
    expect(may.soLan, 2);
  });

  test('vẫn kẹt → chỉ thử lại MỘT lần rồi báo lỗi, không lặp mãi', () async {
    final may = _MayChuGia(ketLan: 99);
    ApiClient.dio.httpClientAdapter = may;
    await expectLater(ApiClient.dio.get('/x'),
        throwsA(isA<DioException>().having((e) => e.type, 'type', DioExceptionType.connectionTimeout)));
    expect(may.soLan, 2);
  });

  test('gửi ảnh (FormData) bị kẹt → gửi lại đủ ảnh lần hai', () async {
    final may = _MayChuGia(ketLan: 1);
    ApiClient.dio.httpClientAdapter = may;
    final form = FormData.fromMap({'file': MultipartFile.fromBytes(utf8.encode('ANH-CHAM-CONG'), filename: 'a.jpg')});
    final r = await ApiClient.dio.post('/upload/image', data: form);
    expect(r.statusCode, 200);
    expect(may.soLan, 2);
    expect(may.noiDungNhan.last, contains('ANH-CHAM-CONG'));
  });

  test('máy chủ đã trả lời (kể cả lỗi 500) → không gửi lại', () async {
    final may = _MayChuGia(ketLan: 0, maTraVe: 500);
    ApiClient.dio.httpClientAdapter = may;
    await expectLater(ApiClient.dio.get('/x'), throwsA(isA<DioException>()));
    expect(may.soLan, 1);
  });

  test('nenThuLaiKetNoi: chỉ lỗi chưa kết nối được, và chỉ một lần', () {
    final o = RequestOptions(path: '/x');
    expect(ApiClient.nenThuLaiKetNoi(DioException(requestOptions: o, type: DioExceptionType.connectionTimeout)), isTrue);
    expect(ApiClient.nenThuLaiKetNoi(DioException(requestOptions: o, type: DioExceptionType.connectionError)), isTrue);
    expect(ApiClient.nenThuLaiKetNoi(DioException(requestOptions: o, type: DioExceptionType.receiveTimeout)), isFalse);
    o.extra['thuLaiKetNoi'] = 1;
    expect(ApiClient.nenThuLaiKetNoi(DioException(requestOptions: o, type: DioExceptionType.connectionTimeout)), isFalse);
  });
}
