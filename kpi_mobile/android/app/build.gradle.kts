import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Nạp google-services.json để bật thông báo đẩy Firebase.
    //
    // Plugin này BẮT BUỘC phải có tệp android/app/google-services.json — thiếu
    // là build hỏng. Tệp đó bị .gitignore loại trừ (không lên kho công khai),
    // nên máy build phải tự chuẩn bị: máy dev đặt tệp thật vào, còn Codemagic
    // nạp từ biến môi trường GOOGLE_SERVICES_JSON (base64) trước khi build.
    id("com.google.gms.google-services")
}

// ─── Thông tin ký số bản phát hành ────────────────────────────────────────
// Đọc từ file android/key.properties (KHÔNG commit lên Git).
// Thiếu file này thì tự lùi về khoá debug để `flutter run` vẫn chạy được,
// nhưng bản phát hành thật BẮT BUỘC phải có khoá riêng — nếu ký bằng khoá
// debug thì mỗi máy build ra một chữ ký khác nhau, Android sẽ từ chối cài đè
// khi cập nhật ("App not installed").
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "vn.trilongland.kpi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Cho phép dùng API Java mới trên máy Android đời cũ. Gói
        // flutter_local_notifications (hiện thông báo khi app đang mở) bắt buộc
        // bật mục này, thiếu là build hỏng ngay ở bước kiểm tra thư viện.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Định danh app — phải trùng với Bundle ID bên iOS và với app đã khai
        // trên Firebase. Đổi giá trị này coi như là một ứng dụng khác.
        applicationId = "vn.trilongland.kpi"
        minSdk = flutter.minSdkVersion // Yêu cầu từ mobile_scanner
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                // Dùng rootProject.file() để đường dẫn tính từ thư mục android/
                // (nơi đặt key.properties), không phải android/app/.
                // Đường dẫn tuyệt đối vẫn dùng được bình thường — Codemagic ghi kiểu đó.
                storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Chỉ dùng khi chạy thử trên máy dev
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Thư viện đi kèm bắt buộc khi bật isCoreLibraryDesugaringEnabled ở trên.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
