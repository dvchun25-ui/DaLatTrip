# Supabase Storage cho DALATTRIP

Project dùng Firebase Authentication làm danh tính chính và chỉ dùng Supabase
cho Storage. Không tạo bảng ứng dụng, không dùng Supabase Database/Realtime.

Thiết lập một lần trong Supabase Dashboard:

1. Vào Authentication > Third-Party Auth, thêm Firebase project
   `dalattrip-8c1d2`.
2. Chạy `storage_setup.sql` trong SQL Editor để tạo bốn bucket và policy chỉ cho
   user đã xác thực đọc metadata, ghi và xóa trong thư mục mang đúng Firebase
   UID của mình. Quyền đọc metadata là bắt buộc để ghi đè avatar bằng `upsert`.

Policy chấp nhận database role `anon` lẫn `authenticated` vì Firebase ID token
mặc định chưa có custom claim `role`. Truy cập ẩn danh thực sự vẫn bị từ chối:
JWT bắt buộc phải có issuer, audience và subject đúng project Firebase
`dalattrip-8c1d2`, đồng thời thư mục đầu tiên phải trùng subject/UID.

Ứng dụng tự chuyển Firebase ID token cho Supabase. Publishable key có thể nằm ở
client; tuyệt đối không đưa service-role key vào Flutter.

Có thể thay cấu hình mặc định khi build:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://smyvqoudgbfqxdnwcxer.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your_publishable_key
```
