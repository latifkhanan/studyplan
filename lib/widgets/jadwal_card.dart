import 'package:flutter/material.dart';

import '../models/jadwal.dart';
import 'catatan_dialog.dart';

class JadwalCard extends StatelessWidget {
  final Jadwal jadwal;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCatatan;

  const JadwalCard({
    super.key,
    required this.jadwal,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onCatatan,
  });

  Map<String, dynamic> _getClassStatus() {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (jadwal.tanggal != todayStr) {
      if (jadwal.tanggal.compareTo(todayStr) < 0) {
        return {
          'label': 'Telah Selesai',
          'color': const Color(0xFF64748B),
          'bg': const Color(0xFFF1F5F9),
        };
      } else {
        return {
          'label': 'Akan Datang',
          'color': const Color(0xFF3563E9),
          'bg': const Color(0xFFEFF4FF),
        };
      }
    }

    final startParts = jadwal.jamMulai.replaceAll('.', ':').split(':');
    final endParts = jadwal.jamSelesai.replaceAll('.', ':').split(':');

    if (startParts.length < 2 || endParts.length < 2) {
      return {
        'label': 'Hari Ini',
        'color': const Color(0xFF3563E9),
        'bg': const Color(0xFFEFF4FF),
      };
    }

    final startMin =
        (int.tryParse(startParts[0]) ?? 0) * 60 +
        (int.tryParse(startParts[1]) ?? 0);
    final endMin =
        (int.tryParse(endParts[0]) ?? 0) * 60 +
        (int.tryParse(endParts[1]) ?? 0);
    final currentMin = now.hour * 60 + now.minute;

    if (currentMin >= startMin && currentMin <= endMin) {
      return {
        'label': 'Berlangsung',
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFECFDF5),
      };
    } else if (currentMin > endMin) {
      return {
        'label': 'Selesai',
        'color': const Color(0xFF64748B),
        'bg': const Color(0xFFF1F5F9),
      };
    } else {
      return {
        'label': 'Hari Ini',
        'color': const Color(0xFF3563E9),
        'bg': const Color(0xFFEFF4FF),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final locationColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final lecturerColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF94A3B8);

    final status = _getClassStatus();

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
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Status badge & Actions (Catatan, Edit, Delete)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? (status['color'] as Color).withValues(alpha: 0.2)
                          : status['bg'],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status['label'] == 'Berlangsung')
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          status['label'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: status['color'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (jadwal.isAlarmActive)
                    Tooltip(
                      message:
                          'Alarm ${jadwal.alarmMinutesList.map((minutes) => '${minutes}m').join(', ')} sebelum kelas',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3563E9).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.alarm_on_rounded,
                              size: 13,
                              color: Color(0xFF3563E9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              jadwal.alarmMinutesList
                                  .map((minutes) => '${minutes}m')
                                  .join(', '),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3563E9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  // Catatan Button
                  InkWell(
                    onTap:
                        onCatatan ?? () => CatatanDialog.show(context, jadwal),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3563E9).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            color: Color(0xFF3563E9),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Catatan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3563E9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (onEdit != null) const SizedBox(width: 6),
                  if (onEdit != null)
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF3563E9),
                          size: 18,
                        ),
                      ),
                    ),
                  if (onDelete != null) const SizedBox(width: 4),
                  if (onDelete != null)
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Course Title
          Text(
            jadwal.mataKuliah,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),

          // Row 3: Time & Room
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
                style: TextStyle(fontSize: 13, color: locationColor),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Row 4: Lecturer
          Text(
            jadwal.dosen,
            style: TextStyle(fontSize: 13, color: lecturerColor),
          ),
        ],
      ),
    );
  }
}
