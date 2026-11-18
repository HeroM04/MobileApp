package vn.trilongland.kpi

import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Đồng hồ tính từ lúc bật máy (mili giây), chạy cả lúc máy ngủ, người dùng
        // không chỉnh được. Dùng đo thời gian chờ của lượt chấm công gửi chậm do
        // mạng — xem lib/core/utils/dong_ho_may.dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "trilong/dong_ho_may")
            .setMethodCallHandler { call, result ->
                if (call.method == "mocKhoiDong") {
                    result.success(SystemClock.elapsedRealtime())
                } else {
                    result.notImplemented()
                }
            }
    }
}
