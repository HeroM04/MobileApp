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

---

## 7. ĐƯA LÊN APP STORE (làm sau khi TestFlight đã chạy ổn)

### 7.1. Chọn hình thức phát hành trước khi nộp

| Hình thức | Ai thấy được | Hết hạn? | Apple duyệt? |
|---|---|---|---|
| TestFlight (đang dùng) | Người có link | **Bản build hết hạn sau 90 ngày** | Beta review nhẹ |
| **App Store — Unlisted (không niêm yết)** ⭐ | Chỉ ai có link trực tiếp; không tìm thấy khi search, không hiện ở bảng xếp hạng | Không | Duyệt đầy đủ như app thường |
| App Store công khai | Tất cả mọi người | Không | Duyệt đầy đủ; **app chỉ dành cho nhân viên một công ty thường bị từ chối** với lý do "không phù hợp App Store, hãy dùng Apple Business Manager" |

→ **Khuyến nghị: nộp duyệt như bình thường, đồng thời xin Unlisted.** Cùng một lần
duyệt, nhưng khi được chấp thuận thì nhân viên cài từ link App Store (tự cập nhật,
không hết hạn), người ngoài không tìm thấy, và Apple không vướng lý do "app nội bộ".

Xin Unlisted tại: https://developer.apple.com/contact/request/unlisted-app/
(điền tên app, Bundle ID `vn.trilongland.kpi`, mô tả "internal app for employees of
Tri Long Real Estate Co., Ltd — attendance, KPI tracking"). Apple trả lời trong vài
ngày; sau khi được duyệt, vào App Store Connect → app → *Pricing and Availability* →
*App Distribution Method* → chọn **Unlisted**.

### 7.2. Bản build: KHÔNG cần build lại

Bản `.ipa` đang nằm trên TestFlight dùng được luôn cho App Store — cùng một file.
Trong App Store Connect → tab *App Store* → mục *Build* → bấm **+** → chọn đúng bản
đang chạy TestFlight. Muốn bản mới hơn thì chạy `ios-testflight` như thường rồi chọn
bản đó. `submit_to_app_store: false` trong `codemagic.yaml` cứ giữ nguyên — lần đầu
nộp tay trên App Store Connect cho chắc.

### 7.3. Việc phải làm trên App Store Connect (mục nào thiếu là không nộp được)

**App Information**
- Name: `Trí Long Land` (tối đa 30 ký tự; đổi thành `Trí Long Land KPI` nếu bị trùng)
- Subtitle: `Chấm công & KPI nội bộ`
- Primary language: Vietnamese · Category: **Business**
- Content Rights: không dùng nội dung bên thứ ba
- Age Rating: trả lời "No" tất cả → **4+**

**Privacy Policy URL — BẮT BUỘC.** Tạo một trang trên trilongland.vn (gợi ý
`https://trilongland.vn/chinh-sach-bao-mat-ung-dung/`) với nội dung ở mục 7.5.

**Pricing and Availability**: Free · chỉ cần chọn Việt Nam (thêm nước khác nếu có nhân
viên ở nước ngoài).

**Version Information (tab App Store)**
- Screenshots: bắt buộc bộ **iPhone 6.9"** (1320×2868) *hoặc* 6.7" (1290×2796) — 3 đến
  10 ảnh. Chụp trên iPhone thật rồi tải lên là được, không cần thiết kế. Gợi ý 5 ảnh:
  Đăng nhập → Trang chủ → Chấm công → Lịch sử chấm công → Bảng KPI cá nhân.
- Nếu app còn khai báo hỗ trợ iPad (hiện tại đang khai báo, xem 7.6) thì phải có thêm bộ
  **iPad 13"** (2064×2752) và Apple sẽ test trên iPad.
- Description, Keywords, Support URL (`https://trilongland.vn`): dùng mẫu ở 7.4.
- Copyright: `2026 Công ty TNHH Bất động sản Trí Long`

**App Privacy** (khai báo dữ liệu thu thập — Apple đối chiếu với thực tế app):

| Loại dữ liệu | Có thu | Gắn với danh tính | Mục đích |
|---|---|---|---|
| Name | ✔ | ✔ | App Functionality |
| Phone Number | ✔ | ✔ | App Functionality |
| Precise Location | ✔ | ✔ | App Functionality (chấm công GPS) |
| Photos or Videos | ✔ | ✔ | App Functionality (ảnh chấm công, thực chiến, bài đăng) |
| User ID | ✔ | ✔ | App Functionality |
| Device ID (token thông báo đẩy) | ✔ | ✔ | App Functionality |
| Used for tracking | **Không** | | |

**App Review Information — điền tài khoản demo** (đã có từ lần Beta review, dùng lại).
Sign-in required: bật. Ghi chú cho người duyệt viết **bằng tiếng Anh**, mẫu ở 7.4.

### 7.4. Nội dung điền sẵn

**Description (tiếng Việt, storefront Việt Nam)**

> Ứng dụng nội bộ dành cho nhân viên Công ty TNHH Bất động sản Trí Long.
>
> • Chấm công bằng GPS và ảnh chụp tại văn phòng hoặc điểm thực địa
> • Theo dõi điểm KPI cá nhân theo tuần, tháng: chuyên cần, thực chiến, lan tỏa, chốt căn
> • Gửi đơn xin nghỉ, xem lịch sử chấm công
> • Điểm danh buổi đào tạo bằng mã QR, xem kho video đào tạo
> • Nhận thông báo từ công ty
>
> Tài khoản do bộ phận nhân sự cấp. Ứng dụng không hỗ trợ tự đăng ký.

**Keywords** (tối đa 100 ký tự): `trí long,tri long land,chấm công,kpi,bất động sản,nội bộ`

**Notes for App Review (tiếng Anh — người duyệt không đọc tiếng Việt)**

> This is an internal app for employees of Tri Long Real Estate Co., Ltd (Hanoi, Vietnam).
> Accounts are created by HR; there is no self sign-up, so no account deletion flow is needed
> in-app (employees contact HR). We have also requested Unlisted distribution.
>
> Demo account: phone `<số>` / password `<mật khẩu>`.
>
> Notes on testing:
> 1. Check-in requires a selfie and GPS. The demo office is in Hanoi; from your location the app
>    will report "outside office range" and ask for a reason — this is expected. The check-in is
>    then submitted for manager approval.
> 2. Check-in selfies are compared against the employee photo registered by HR (face
>    verification). With the demo account the photo on file is a placeholder, so a check-in by a
>    different person is rejected by design. [Sửa dòng này nếu áp dụng cách ở 7.6.]
> 3. Push notifications require Firebase; the app works normally without them.

### 7.5. Chính sách quyền riêng tư — nội dung trang web (chỉnh lại theo thực tế rồi đăng)

> **Chính sách quyền riêng tư — Ứng dụng Trí Long Land**
> Cập nhật: 19/09/2026
>
> Ứng dụng Trí Long Land (sau đây gọi là "Ứng dụng") do Công ty TNHH Bất động sản Trí Long
> ("Công ty") phát triển, dành riêng cho nhân viên và cộng sự của Công ty để chấm công và
> theo dõi chỉ tiêu công việc (KPI). Ứng dụng không dành cho khách hàng hay công chúng.
>
> **1. Dữ liệu thu thập**
> - Thông tin tài khoản: họ tên, số điện thoại, phòng ban, vai trò — do bộ phận nhân sự
>   tạo, không thu thập qua đăng ký công khai.
> - Vị trí GPS: chỉ lấy tại thời điểm bạn bấm chấm công, để xác định bạn đang ở văn phòng
>   hay điểm thực địa. Ứng dụng không theo dõi vị trí khi bạn không chấm công.
> - Ảnh: ảnh chụp khi chấm công, ảnh báo cáo thực chiến, ảnh bài đăng do bạn chủ động chụp
>   hoặc chọn. Ảnh chấm công được so khớp tự động với ảnh nhân sự đã đăng ký để xác nhận
>   đúng người.
> - Mã thiết bị nhận thông báo đẩy (push token).
>
> **2. Mục đích sử dụng**: chấm công, tính điểm KPI, quản lý đào tạo và thông báo nội bộ.
> Không dùng để quảng cáo, không bán hay chia sẻ cho bên thứ ba vì mục đích thương mại.
>
> **3. Lưu trữ và bảo mật**: dữ liệu lưu trên máy chủ của Công ty thuê tại các nhà cung cấp
> hạ tầng đám mây (khu vực Singapore); ảnh lưu tại dịch vụ lưu trữ ảnh đám mây. Kết nối
> được mã hóa HTTPS. Chỉ quản trị viên và cấp quản lý được phân quyền mới xem dữ liệu.
>
> **4. Thời gian lưu**: trong thời gian bạn làm việc tại Công ty và theo quy định lưu hồ sơ
> nhân sự. Khi nghỉ việc, tài khoản bị khóa; bạn có thể yêu cầu xóa dữ liệu qua bộ phận
> nhân sự.
>
> **5. Quyền của bạn**: xem, sửa thông tin cá nhân qua bộ phận nhân sự; rút quyền vị trí
> hoặc camera trong Cài đặt iOS (khi đó không chấm công được).
>
> **6. Liên hệ**: Công ty TNHH Bất động sản Trí Long — [địa chỉ] — [email] — [điện thoại].

### 7.6. Những chỗ dễ bị từ chối và cách xử lý

| Rủi ro | Vì sao | Cách xử lý |
|---|---|---|
| "App dành cho nhân viên một tổ chức, không phù hợp App Store" | Apple hướng app nội bộ sang Business Manager | Xin **Unlisted** (7.1) ngay từ đầu; nếu vẫn bị từ chối thì trả lời trong Resolution Center là đã có yêu cầu Unlisted |
| Người duyệt không chấm công được vì **xác thực khuôn mặt** | Backend đang bật `app.rekognition.enabled: true`; ảnh của người duyệt không khớp avatar tài khoản demo | Hoặc giải thích trong Notes (7.4), hoặc thêm cờ "bỏ xác thực khuôn mặt" cho riêng tài khoản demo trên backend (chưa làm — cần quyết) |
| Đòi **xóa tài khoản trong app** (Guideline 5.1.1(v)) | Chỉ áp dụng cho app có tự đăng ký | Đã ghi trong Notes: tài khoản do HR cấp, không có đăng ký |
| **iPad**: app khai báo chạy trên iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) nhưng giao diện chỉ thiết kế cho điện thoại | Apple test trên iPad, đòi ảnh iPad | Nếu không nhân viên nào dùng iPad: đổi sang chỉ iPhone (`= "1"`) rồi build lại — bỏ được cả ảnh iPad lẫn rủi ro |
| Quyền vị trí "Always" | `Info.plist` có khai `NSLocationAlwaysUsageDescription` dù app chỉ dùng khi mở | Không sao nếu app không xin quyền Always lúc chạy (hiện không xin) |
| Thiếu Privacy Policy URL / App Privacy sai | Bắt buộc | Mục 7.3, 7.5 |

### 7.7. Sau khi được duyệt

- Chọn **Manually release** khi nộp, để tự quyết ngày phát hành sau khi Apple duyệt.
- Gửi link App Store cho nhân viên thay link TestFlight; app TestFlight có thể gỡ.
- Bản sau: chạy `ios-testflight` như cũ → trên App Store Connect tạo version mới → chọn
  build → nộp. Hoặc đổi `submit_to_app_store: true` trong `codemagic.yaml` để tự nộp.

*Cập nhật lần cuối: 2026-09-19*
