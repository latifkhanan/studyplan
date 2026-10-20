import 'package:flutter/material.dart';
import '../models/jadwal.dart';

class JadwalCard extends StatelessWidget {
  final Jadwal jadwal;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const JadwalCard({
    super.key,
    required this.jadwal,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final locationColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final lecturerColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : const Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  jadwal.mataKuliah,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ),
              Row(
                children: [
                  if (onEdit != null)
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF3563E9),
                          size: 20,
                        ),
                      ),
                    ),
                  if (onEdit != null && onDelete != null) const SizedBox(width: 8),
                  if (onDelete != null)
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Color(0xFF3563E9),
              ),
              const SizedBox(width: 6),
              Text(
                '${jadwal.jamMulai}–${jadwal.jamSelesai}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3563E9),
                ),
              ),
              Text(
                ' · ${jadwal.ruangan}',
                style: TextStyle(
                  fontSize: 13,
                  color: locationColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            jadwal.dosen,
            style: TextStyle(
              fontSize: 13,
              color: lecturerColor,
            ),
          ),
        ],
      ),
    );
  }
}
