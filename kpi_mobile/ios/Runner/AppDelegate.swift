import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Đồng hồ tính từ lúc bật máy (mili giây). CLOCK_MONOTONIC trên iOS chạy cả
    // lúc máy ngủ và không đổi khi người dùng chỉnh giờ. Dùng đo thời gian chờ
    // của lượt chấm công gửi chậm do mạng — xem lib/core/utils/dong_ho_may.dart.
    if let registrar = self.registrar(forPlugin: "DongHoMay") {
      let kenh = FlutterMethodChannel(name: "trilong/dong_ho_may", binaryMessenger: registrar.messenger())
      kenh.setMethodCallHandler { call, result in
        if call.method == "mocKhoiDong" {
          result(Int(clock_gettime_nsec_np(CLOCK_MONOTONIC) / 1_000_000))
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
