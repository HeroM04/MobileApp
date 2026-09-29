import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kpi_mobile/data/services/feedback_service.dart';

/// Góp ý kèm ảnh gửi một lượt dạng multipart — tên trường phải khớp
/// FeedbackController.submitFeedbackWithImages bên máy chủ.
void main() {
  late Directory tam;

  setUp(() async => tam = await Directory.systemTemp.createTemp('gop_y_'));
  tearDown(() async => tam.delete(recursive: true));

  test('các trường chữ đổi sang chuỗi, bỏ trường rỗng; ảnh cùng tên "images"', () async {
    final a = await File('${tam.path}/loi-1.jpg').writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);
    final b = await File('${tam.path}/loi-2.png').writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

    final form = await FeedbackService.taoForm(
      {'title': 'App treo', 'category': 'Báo cáo sự cố kỹ thuật', 'content': 'Xem ảnh', 'rating': 4, 'khong': null},
      [a, b],
    );

    final truong = {for (final f in form.fields) f.key: f.value};
    expect(truong, {'title': 'App treo', 'category': 'Báo cáo sự cố kỹ thuật', 'content': 'Xem ảnh', 'rating': '4'});
    expect(form.files.map((f) => f.key), ['images', 'images']);
    expect(form.files.map((f) => f.value.filename), ['loi-1.jpg', 'loi-2.png']);
  });

  test('giới hạn 5 ảnh khớp máy chủ', () {
    expect(FeedbackService.toiDaAnh, 5);
  });
}
