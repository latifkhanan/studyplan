# Laporan Pengujian Maestro – StudyPlan

## Informasi Pengujian

- Flow: `flows/schedule-crud.yaml`
- Aplikasi: `com.example.studyplan`
- Perangkat: Tecno CM5, Android 16
- Maestro CLI: 2.12.1
- Akun: akun testing Firebase melalui environment variable; kredensial tidak disimpan di repository

## Perubahan Flow

- Login menggunakan email saja.
- Field email dan password diisi melalui `${TEST_EMAIL}` dan `${TEST_PASSWORD}`.
- Selector login menggunakan koordinat kontrol yang diambil dari hierarchy perangkat karena selector semantic pada perangkat Tecno tidak stabil.
- `launchApp` dihapus dari flow CRUD. Aplikasi dibersihkan dan dijalankan melalui ADB sebelum test karena `launchApp` menyebabkan koneksi Maestro menggantung pada perangkat ini.

## Hasil

| Skenario                              | Hasil                          |
| ------------------------------------- | ------------------------------ |
| Smoke test: field Email terlihat      | PASS                           |
| Smoke test: field Kata Sandi terlihat | PASS                           |
| Smoke test: tombol Masuk terlihat     | PASS                           |
| Login akun testing                    | Belum dapat diverifikasi penuh |
| CRUD jadwal lengkap                   | BLOCKED oleh koneksi Maestro   |

## Kendala

Pengujian CRUD berhenti sebelum langkah login selesai karena Maestro melaporkan `DeviceServerDiedException` dengan status `UNAVAILABLE`; port server ADB ditutup oleh perangkat. ADB masih mendeteksi HP, tetapi layanan server Maestro tidak bertahan. Karena itu belum ada bukti valid bahwa create, read, update, dan delete jadwal berhasil seluruhnya.

## Perintah Pengujian

```powershell
$env:TEST_EMAIL = "<email-testing>"
$env:TEST_PASSWORD = "<password-testing>"
$env:TEST_RUN_ID = "maestro_unique_id"
maestro --udid 145912555D001036 test .maestro\flows\schedule-crud.yaml
```

Password tidak dicantumkan dalam laporan dan tidak ditulis ke flow.
