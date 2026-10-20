import 'package:flutter/material.dart';
import '../models/jadwal.dart';

Future<bool?> showDeleteConfirmationDialog(BuildContext context, Jadwal item) {
  final List<String> months = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  String formattedDateText = '${item.hari}, 20 Oktober 2026';
  if (item.tanggal.isNotEmpty) {
    final parts = item.tanggal.split('-');
    if (parts.length == 3) {
      final year = parts[0];
      final month = int.tryParse(parts[1]) ?? 10;
      final day = int.tryParse(parts[2]) ?? 20;
      formattedDateText = '${item.hari}, $day ${months[month]} $year';
    }
  }

  return showDialog<bool>(
    context: context,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
      final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Theme.of(context).cardColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badge ikon tempat sampah merah
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),

              // Judul Dialog
              Text(
                'Hapus jadwal?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle Peringatan
              Text(
                'Jadwal kuliah ini akan dihapus. Tindakan ini tidak dapat dibatalkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: subtitleColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Card Detail Mata Kuliah yang akan dihapus
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.mataKuliah,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDateText,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.jamMulai}–${item.jamSelesai} · ${item.ruangan}',
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Utama: Hapus Jadwal
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Hapus Jadwal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tombol Sekunder: Batal
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
