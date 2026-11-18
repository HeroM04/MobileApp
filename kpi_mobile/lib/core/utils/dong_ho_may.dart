import 'package:flutter/services.dart';

/// Một lần đọc đồng hồ tính từ lúc bật máy.
class MocMay {
  /// Mili giây từ lúc bật máy — chạy cả lúc máy ngủ, người dùng không chỉnh được.
  final int msTuLucBat;

  /// Ước lượng lúc bật máy theo giờ điện thoại (mili giây epoch). Hai lần đọc
  /// cùng một lần bật máy thì gần như bằng nhau; lệch nhiều là máy đã khởi động
  /// lại (đồng hồ bắt đầu lại từ 0) hoặc giờ điện thoại vừa bị chỉnh.
  final int lucBatMs;

  const MocMay(this.msTuLucBat, this.lucBatMs);

  Map<String, dynamic> toJson() => {'ms': msTuLucBat, 'bat': lucBatMs};

  static MocMay? fromJson(Object? j) {
    if (j is! Map) return null;
    final ms = j['ms'], bat = j['bat'];
    return (ms is int && bat is int) ? MocMay(ms, bat) : null;
  }
}

/// Đo thời gian chờ của lượt chấm công gửi chậm do mạng.
///
/// Máy chủ tính giờ bấm = giờ của máy chủ − thời gian chờ. Thời gian chờ phải đo
/// bằng đồng hồ người dùng không chỉnh được — đo bằng giờ điện thoại thì chỉnh lùi
/// giờ trước khi chụp là "đi sớm" được. Android: SystemClock.elapsedRealtime;
/// iOS: CLOCK_MONOTONIC (MainActivity.kt, AppDelegate.swift).
class DongHoMay {
  DongHoMay._();

  static const _kenh = MethodChannel('trilong/dong_ho_may');

  /// Đọc đồng hồ; null khi không đọc được (bản cài thiếu phần native, máy tính…).
  static Future<MocMay?> doc() async {
    try {
      final ms = await _kenh.invokeMethod<int>('mocKhoiDong');
      if (ms == null || ms <= 0) return null;
      return MocMay(ms, DateTime.now().millisecondsSinceEpoch - ms);
    } catch (_) {
      return null;
    }
  }

  /// Lệch ước lượng lúc bật máy quá mức này thì không tin số đo nữa.
  static const int lechToiDaMs = 2 * 60 * 1000;

  /// Số giây đã trôi qua từ [truoc] tới [sau].
  ///
  /// Null khi không đo được: thiếu một trong hai lần đọc, máy đã khởi động lại,
  /// hoặc giờ điện thoại bị chỉnh giữa chừng. Khi đó máy chủ lấy giờ điện thoại
  /// và bắt lượt đó chờ duyệt.
  static int? daTroiQuaGiay(MocMay? truoc, MocMay? sau) {
    if (truoc == null || sau == null) return null;
    if ((truoc.lucBatMs - sau.lucBatMs).abs() > lechToiDaMs) return null;
    final d = sau.msTuLucBat - truoc.msTuLucBat;
    if (d < 0) return null;
    return d ~/ 1000;
  }
}
