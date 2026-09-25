# Kiểm thử thủ công (gọi máy chủ thật)

Các tệp ở đây **không chạy** khi gõ `flutter test` — chúng gọi máy chủ thật qua
mạng và đăng nhập bằng tài khoản thật, nên:

- chạy trên máy ai không có mạng / máy chủ đang ngủ là hỏng, dù code không sai;
- chạy vào máy chủ chính thức là bắn đăng nhập thật vào hệ thống đang dùng;
- tài khoản mẫu `0900000003` đã bị xóa khi dựng lại DB trên Supabase (18/09/2026).

Kiểm thử tự động của app nằm ở `test/` và không cần mạng.

Muốn chạy tay (trỏ vào máy chủ thử nghiệm, KHÔNG phải máy chủ chính thức):

```
flutter test test_thu_cong/auth_integration_test.dart
dart run test_thu_cong/integration_run.dart
```
