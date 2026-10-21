# Hồ sơ đưa app lên App Store (dạng Unlisted)

App "Trí Long Land" lên App Store dưới dạng **Unlisted**: không ai tìm thấy khi tìm kiếm, chỉ người có link mới cài được. App tự cập nhật như mọi app App Store, không hết hạn sau 90 ngày như bản TestFlight.

Apple ghi rõ ứng viên phù hợp với Unlisted gồm "employee resources" (công cụ cho nhân viên) và máy cá nhân của nhân viên. Trang chính thức: https://developer.apple.com/support/unlisted-app-distribution/

**Thứ tự bắt buộc:** gửi Apple duyệt trước, ghi trong Review Notes rằng app dành cho Unlisted, **rồi** mới nộp đơn xin Unlisted. Apple từ chối đơn nếu app chưa được gửi duyệt hoặc còn là bản thử nghiệm.

---

## Bước 1 — Build bản mới

Bản build này có hai thay đổi cho App Store:
- Câu xin quyền camera, vị trí, ảnh viết lại đúng với việc app làm. Bản cũ ghi "xác thực khuôn mặt", dễ bị Apple hỏi về dữ liệu khuôn mặt.
- App chỉ chạy trên iPhone. Không phải nộp ảnh iPad, Apple không duyệt trên iPad.

Chạy workflow **ios-testflight** trên Codemagic. Khoảng 20–30 phút sau bản mới hiện trong TestFlight. Tên phiên bản vẫn là **1.2.0**.

## Bước 2 — Tạo tài khoản demo cho Apple

Apple bắt buộc có tài khoản để đăng nhập thử. Tạo trên Web Admin:
- Họ tên: `Apple Review` · Vai trò: **SALE**. Nên để trong một phòng riêng, ví dụ "Kiểm thử", cho dễ lọc khỏi báo cáo.
- Số điện thoại: một số không trùng ai, ví dụ `0900000099`.
- Mật khẩu: tự đặt, đủ mạnh. Nhập vào App Store Connect ở Bước 3, **không** gửi qua chat hay email.
- **Giữ tài khoản này hoạt động lâu dài.** Mỗi lần cập nhật app lên App Store, Apple lại đăng nhập để duyệt.

## Bước 3 — Điền App Store Connect

Vào appstoreconnect.apple.com → **Apps** → **Trí Long Land** → **Distribution**.

### 3.1 Phiên bản và bản build
- Bấm vào phiên bản đang ghi **1.0**, đổi số phiên bản thành **1.2.0** cho khớp bản build. Chỉ đổi trên App Store Connect, không đổi gì trong app.
- Kéo xuống mục **Build**, bấm **+**, chọn bản build mới nhất từ Bước 1.

### 3.2 Thông tin trang app (tiếng Việt)

| Ô | Nội dung |
|---|---|
| Subtitle (≤ 30 ký tự) | `Chấm công & KPI nội bộ` |
| Promotional Text (≤ 170) | `Ứng dụng nội bộ dành riêng cho nhân viên Trí Long Land: chấm công có ảnh và vị trí, báo cáo gặp khách, đào tạo và theo dõi điểm KPI mỗi tuần.` |
| Keywords (≤ 100) | `chấm công,KPI,Trí Long,nhân viên,bất động sản,sale,điểm danh,đào tạo` |
| Support URL | `https://herom04.github.io/kpi-trilong-app/` |
| Marketing URL | để trống |
| Copyright | `2026 Công ty TNHH Bất động sản Trí Long` |

**Description:**

```
Trí Long Land là ứng dụng nội bộ của Công ty TNHH Bất động sản Trí Long, chỉ dành cho nhân viên được công ty cấp tài khoản.

Tính năng chính:
• Chấm công vào / ra có ảnh chụp, thời gian và vị trí. Xin vắng. Xem lịch sử chấm công theo ngày, theo tháng.
• Báo cáo thực chiến: gặp khách, hỗ trợ khách, kèm ảnh tại thực địa.
• Bài đăng, video xây kênh: gửi ảnh chụp màn hình để quản lý duyệt.
• Đào tạo: quét mã QR điểm danh, gửi báo cáo đào tạo 1-1.
• Theo dõi điểm KPI theo tuần, theo tháng, nhận thông báo mỗi khi có điểm mới.
• Gửi góp ý tới ban quản lý.

Ứng dụng không cho tự đăng ký. Tài khoản do bộ phận Hành chính – Nhân sự của công ty cấp.
```

### 3.3 Ảnh chụp màn hình

- Chụp **3–5 ảnh trên iPhone màn hình lớn** (Pro Max hoặc Plus): trang chủ có điểm KPI, chấm công, thực chiến, bài đăng, lịch sử chấm công.
- **Đăng nhập bằng tài khoản demo** khi chụp. Không để lộ tên, số điện thoại, ảnh của nhân viên thật.
- Kéo vào ô **iPhone 6.9" Display**. Nếu App Store Connect báo sai kích thước, gửi ảnh cho Claude để chỉnh lại.

### 3.4 App Review Information
- **Sign-in required:** bật. Điền số điện thoại và mật khẩu của tài khoản demo ở Bước 2.
- **Contact information:** họ tên, số điện thoại, email người phụ trách (bạn).
- **Notes:** dán nguyên đoạn tiếng Anh dưới đây.

```
This app is intended for unlisted distribution.

It is an internal tool for employees of Tri Long Real Estate Co., Ltd. (Hanoi, Vietnam). Accounts are created by the company's HR / IT department; there is no public sign-up, so the app has no in-app account creation. Employees can ask HR to delete their data (see the privacy policy). The app is in Vietnamese.

The demo account (Sales role) is in Sign-In Information. Log in with the phone number and password.

How to review:
1. Attendance ("Chấm công"): tap CHẤM CÔNG VÀO, take a photo, confirm. On-site check-in requires being within 300 m of our office in Hanoi. From anywhere else the app asks for a reason and sends the check-in to the admin for approval. This is expected behaviour.
2. Field report ("Thực chiến"): choose a type, write a short note, attach a photo, submit.
3. Posts ("Bài đăng"): attach a screenshot and submit.
4. Training ("Đào tạo"): QR attendance only works during an in-person session in our office. A 1-on-1 training report can be submitted with a photo.
5. KPI points and notifications are on the home screen and under the bell icon.

Location is requested "While Using the App" and used only when the user taps check-in or submits a field report; there is no background tracking. The camera and photo library are used only for attendance photos, report photos and QR scanning. There is no face recognition.
```

### 3.5 App Privacy (mục bên trái → App Privacy)

- **Privacy Policy URL:** `https://herom04.github.io/kpi-trilong-app/chinh-sach-bao-mat.html`
- "Do you or your third-party partners collect data from this app?" → **Yes**.
- Chọn đúng các loại dưới đây. Với **mọi** loại: Purpose = **App Functionality**, Linked to the user = **Yes**, Used for tracking = **No**.

| Nhóm | Loại dữ liệu | Trong app là |
|---|---|---|
| Contact Info | Name | Họ tên nhân viên |
| Contact Info | Phone Number | Số điện thoại đăng nhập |
| Location | Precise Location | Vị trí lúc chấm công, gửi báo cáo |
| User Content | Photos or Videos | Ảnh chấm công, ảnh báo cáo, ảnh bài đăng, ảnh góp ý |
| User Content | Other User Content | Nội dung báo cáo, góp ý, lý do xin vắng |
| Identifiers | User ID | Mã tài khoản nhân viên |
| Identifiers | Device ID | Mã nhận thông báo đẩy |

Các nhóm khác (Health, Financial, Contacts, Browsing, Search, Purchases, Usage Data, Diagnostics…) → **không** chọn.

### 3.6 Các mục khác
- **App Information → Category:** Primary **Business**, Secondary **Productivity**.
- **Age Rating:** trả lời **None / No** cho mọi câu → 4+.
- **Content Rights:** không chứa nội dung của bên thứ ba → **No**.
- **Pricing and Availability:** Price **Free (0)**. Availability: chỉ chọn **Vietnam**.
- **Export compliance:** app đã khai `ITSAppUsesNonExemptEncryption = NO`, Apple sẽ không hỏi.

### 3.7 Cách phát hành — QUAN TRỌNG
Ở mục **App Store Version Release**, chọn **"Manually release this version"**. Nếu để tự phát hành mà Apple duyệt xong trước khi đơn Unlisted được chấp thuận, app sẽ hiện công khai trên App Store.

## Bước 4 — Gửi duyệt rồi xin Unlisted

1. Bấm **Add for Review**, rồi **Submit for Review**. Trạng thái chuyển sang *Waiting for Review*.
2. Nộp đơn xin Unlisted tại https://developer.apple.com/contact/request/unlisted-app/ (đăng nhập Apple ID của tài khoản Developer). Điền tên app, Apple ID của app (số trong App Information) và lý do: *internal app for our employees on their personal devices*.
3. Chờ Apple trả lời cả hai việc. Thường vài ngày. Bật thông báo trong app **App Store Connect** trên iPhone để biết ngay.
4. Khi cả hai được chấp thuận: mục **Pricing and Availability** sẽ ghi phân phối **Unlisted App**, kèm link cài. Bấm **Release This Version**.
5. Gửi link đó cho nhân viên. Ai đang dùng TestFlight thì cài bản App Store, xong có thể xóa bản TestFlight.

## Nếu bị từ chối

Mở mục **App Review** trong App Store Connect, chụp nội dung Apple ghi (có số điều khoản, ví dụ "Guideline 2.1") gửi cho Claude để xử lý. Trong lúc chờ, mọi người vẫn dùng TestFlight bình thường.
