# Hướng dẫn Build & Deploy bản iOS — App Trí Long Land (kpi_mobile)

## TÓM TẮT NHANH

App này là **Flutter** → **dùng chung một bộ mã nguồn cho cả Android và iOS**.
Không cần "viết lại app cho iOS". Phần cấu hình iOS **đã chuẩn bị xong** (xem mục 3).

⚠️ **Nhưng KHÔNG thể build file iOS trên Windows.** Apple bắt buộc phải có **macOS + Xcode**.
Trên Windows, Flutter thậm chí không có lệnh `flutter build ipa` (chỉ có apk/appbundle/web/windows).

→ Cần chọn 1 trong 3 cách ở mục 1 để tạo file cài iOS.

---

## 1. BA CÁCH ĐỂ BUILD RA FILE iOS

| Cách | Chi phí | Phù hợp khi |
|---|---|---|
| **A. Codemagic / CI đám mây** ⭐ | Có gói miễn phí (~500 phút/tháng) | **Khuyến nghị** — không cần mua máy Mac |
| **B. Máy Mac thật** (MacBook/Mac mini) | Tiền mua máy | Làm iOS lâu dài, cần debug thiết bị thật |
| **C. Thuê Mac từ xa** (MacinCloud, MacStadium) | ~20–30 USD/tháng | Dùng ngắn hạn, thỉnh thoảng build |

**Bắt buộc phải có (cả 3 cách):** tài khoản **Apple Developer Program — 99 USD/năm**.
Không có tài khoản này thì không phát hành được cho nhân viên cài.

### Cách A — Codemagic (khuyến nghị, không cần Mac)

> File cấu hình **`codemagic.yaml`** đã được tạo sẵn ở thư mục gốc repo.
> Codemagic tự đọc file này, bạn không phải cấu hình gì thêm trên giao diện.

Trong file có sẵn **2 workflow**:

| Workflow | Cần tài khoản Apple? | Dùng để làm gì |
|---|---|---|
| `ios-unsigned` | **Không** | Build thử xem code có lỗi không (file tạo ra không cài lên máy được) |
| `ios-testflight` | Có | Build `.ipa` thật + tự đẩy lên TestFlight cho nhân viên cài |

**Bước 1 — Build thử (làm ngay được, miễn phí, không cần Apple):**
1. Đẩy code lên GitHub: `git push` (repo `MobileApp`).
2. Vào https://codemagic.io → **Sign up with GitHub** → chọn repo **MobileApp**.
3. Codemagic tự nhận `codemagic.yaml` → chọn workflow **`ios-unsigned`** → **Start new build**.
4. Chờ ~10–15 phút. Nếu build xanh ✅ nghĩa là **code iOS hoàn toàn ổn**, chỉ còn thiếu tài khoản Apple.

**Bước 2 — Build thật để cài lên iPhone (cần Apple Developer 99 USD/năm):**
1. Đăng ký [Apple Developer Program](https://developer.apple.com/programs/).
2. Tạo **App Store Connect API key**: App Store Connect → *Users and Access* → *Integrations* → *App Store Connect API* → tạo key (quyền **App Manager**), tải file `.p8`.
3. Trong Codemagic: *Teams* → *Integrations* → **App Store Connect** → dán Issuer ID, Key ID và file `.p8`.
4. Tạo **App ID** trên Apple Developer với Bundle ID **`vn.trilongland.kpi`**, rồi tạo app tương ứng trong App Store Connect.
5. Chạy workflow **`ios-testflight`** → xong sẽ tự đẩy lên TestFlight.
6. Vào TestFlight mời nhân viên qua email → họ cài app **TestFlight** rồi cài app của công ty.

> Gói miễn phí Codemagic cho **500 phút build/tháng** — mỗi lần build iOS tốn ~10–15 phút,
> tức khoảng 30–40 lần build/tháng. Quá đủ cho nhu cầu nội bộ.

---

## 2. CÁCH PHÁT HÀNH CHO NHÂN VIÊN CÀI ĐẶT

| Cách | Ưu | Nhược |
|---|---|---|
| **TestFlight** ⭐ | Dễ nhất, tối đa 10.000 người, tự động cập nhật, không cần lên App Store công khai | Bản build hết hạn sau 90 ngày, phải build lại |
| **Apple Business Manager** (phân phối nội bộ) | Không hết hạn, đúng chuẩn nội bộ doanh nghiệp | Thủ tục đăng ký phức tạp hơn |
| **App Store công khai** | Ai cũng tải được | Phải qua kiểm duyệt của Apple, app nội bộ thường bị từ chối |

→ **Khuyến nghị: TestFlight.** Nhân viên chỉ cần cài app TestFlight rồi nhận lời mời qua email/link.

---

## 3. NHỮNG GÌ ĐÃ ĐƯỢC CHUẨN BỊ SẴN (đã sửa xong)

### 3.1. Sửa lỗi nghiêm trọng: thiếu quyền Thư viện ảnh
Code dùng `ImageSource.gallery` ở 3 màn hình (Bài đăng, Thực chiến, Đào tạo 1-1),
nhưng `Info.plist` **thiếu `NSPhotoLibraryUsageDescription`** → **app sẽ CRASH ngay khi bấm chọn ảnh**
(Apple bắt buộc phải khai báo). Đã bổ sung đầy đủ:

- `NSPhotoLibraryUsageDescription` — chọn ảnh từ thư viện *(sửa lỗi crash)*
- `NSPhotoLibraryAddUsageDescription` — lưu ảnh vào thư viện
- `NSMicrophoneUsageDescription` — camera plugin yêu cầu
- `NSLocationAlwaysAndWhenInUseUsageDescription` — bổ sung cho đủ bộ quyền vị trí
- Mở rộng `NSCameraUsageDescription` (nêu rõ: chụp ảnh, quét QR, xác thực khuôn mặt)

### 3.2. Bundle ID (BẮT BUỘC cho App Store)
Trước: `com.example.kpiMobile` → **Apple TỪ CHỐI mọi ID bắt đầu bằng `com.example`**.
Đã đổi thành: **`vn.trilongland.kpi`**

> 📌 Nếu công ty muốn ID khác, sửa trong `ios/Runner.xcodeproj/project.pbxproj`
> (thay toàn bộ `vn.trilongland.kpi`) — làm TRƯỚC khi tạo App ID trên Apple Developer.

### 3.3. Phiên bản iOS tối thiểu
Trước: Runner để `13.0` nhưng Podfile yêu cầu `15.5` → **lệch nhau, dễ lỗi khi build**.
Các plugin `google_mlkit_face_detection` và `mobile_scanner 7.x` đều cần iOS 15.5+.
Đã đồng bộ tất cả về **15.5**.

### 3.4. Tên hiển thị app
Trước: iOS hiện "Kpi Mobile", Android hiện "Trí Long Land" → không khớp.
Đã sửa iOS thành **"Trí Long Land"**.

### 3.5. Hỗ trợ link video Facebook (theo yêu cầu mới)
Trước, màn Kho đào tạo **ép mọi link qua scheme `youtube://`** → dán link Facebook sẽ
**mở nhầm app YouTube** và báo lỗi. Đã sửa:

- Chỉ dùng deep-link YouTube khi link **đúng là** YouTube.
- Link Facebook (và link khác) mở thẳng bằng app ngoài → tự nhảy sang **app Facebook** nếu đã cài,
  không thì mở trình duyệt.
- Nhãn & màu thích ứng: link FB hiện **"Facebook" màu xanh**, link YouTube hiện **"YouTube" màu đỏ**.
- Ô nhập link cho admin đã ghi rõ hỗ trợ cả hai, kèm lưu ý về nhóm riêng tư.

⚠️ **Lưu ý quan trọng về video trong nhóm Facebook riêng tư:**
Người xem **phải đăng nhập Facebook VÀ đã là thành viên nhóm** thì mới xem được.
Sale mới chưa được thêm vào nhóm sẽ thấy "nội dung không khả dụng".
→ Cần có quy trình: **có sale mới là thêm ngay vào nhóm Facebook**.

---

## 4. CHECKLIST TRƯỚC KHI BUILD iOS

- [ ] Có tài khoản **Apple Developer Program** (99 USD/năm)
- [ ] Tạo **App ID** trên Apple Developer với Bundle ID `vn.trilongland.kpi`
- [ ] Chuẩn bị môi trường build: Codemagic / máy Mac / thuê Mac
- [ ] Trên máy Mac (nếu dùng cách B/C), chạy lần lượt:
      `flutter pub get` → `cd ios && pod install` → `flutter build ipa`
- [ ] Kiểm tra file `.env.production` trỏ đúng backend
      (hiện tại: `https://kpi-backend-4xex.onrender.com/api/v1`)
- [ ] Tạo icon iOS nếu đổi logo: `flutter pub run flutter_launcher_icons`
- [ ] Upload lên **TestFlight** rồi mời nhân viên cài

---

## 5. KIỂM THỬ SAU KHI CÀI (quan trọng — các chỗ dễ lỗi trên iOS)

Test kỹ những chức năng dùng quyền hệ thống, vì iOS khắt khe hơn Android:

- [ ] **Chọn ảnh từ Thư viện** (Bài đăng / Thực chiến / Đào tạo 1-1) — *chỗ trước đây gây crash*
- [ ] **Chụp ảnh bằng Camera** + chấm công có ảnh
- [ ] **Chấm công GPS** — kiểm tra hỏi quyền vị trí và lấy đúng toạ độ
- [ ] **Quét QR điểm danh** đào tạo
- [ ] **Xác thực khuôn mặt** (MLKit)
- [ ] **Mở video đào tạo** — thử cả link Facebook lẫn YouTube
- [ ] **Thông báo realtime** (WebSocket/STOMP)
- [ ] Đăng nhập / đăng xuất / lưu phiên đăng nhập

---

## 6. TÓM LẠI PHẦN VIỆC CÒN LẠI CỦA BẠN

Phần **mã nguồn và cấu hình iOS đã sẵn sàng** — không cần lập trình thêm gì cho iOS.
Việc còn lại thuần về **tài khoản và hạ tầng build**:

1. Mua tài khoản Apple Developer (99 USD/năm).
2. Chọn nơi build (khuyến nghị **Codemagic** — khỏi mua Mac).
3. Build ra `.ipa` → đẩy lên **TestFlight** → mời nhân viên cài.

*Cập nhật lần cuối: 2026-08-10*
