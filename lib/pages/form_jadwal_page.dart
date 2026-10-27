import 'package:flutter/material.dart';

import '../models/jadwal.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class FormJadwalPage extends StatefulWidget {
  final Jadwal? jadwal;
  final DateTime? selectedDate;

  const FormJadwalPage({super.key, this.jadwal, this.selectedDate});

  @override
  State<FormJadwalPage> createState() => _FormJadwalPageState();
}

class _FormJadwalPageState extends State<FormJadwalPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _mataKuliahController;
  late TextEditingController _dosenController;
  late TextEditingController _ruanganController;
  late TextEditingController _jamMulaiController;
  late TextEditingController _jamSelesaiController;

  late DateTime _currentDate;
  bool _isAlarmActive = true;
  final Set<int> _alarmMinutesList = {10};

  final List<String> _months = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  final List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.jadwal;

    _mataKuliahController = TextEditingController(text: item?.mataKuliah ?? '');
    _dosenController = TextEditingController(text: item?.dosen ?? '');
    _ruanganController = TextEditingController(text: item?.ruangan ?? '');
    _jamMulaiController = TextEditingController(text: item?.jamMulai ?? '');
    _jamSelesaiController = TextEditingController(text: item?.jamSelesai ?? '');

    _isAlarmActive = item?.isAlarmActive ?? true;
    _alarmMinutesList
      ..clear()
      ..addAll(item?.alarmMinutesList ?? [10]);
    if (_alarmMinutesList.isEmpty) _alarmMinutesList.add(10);

    if (item != null && item.tanggal.isNotEmpty) {
      final parts = item.tanggal.split('-');
      if (parts.length == 3) {
        _currentDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } else {
        _currentDate = widget.selectedDate ?? DateTime.now();
      }
    } else {
      _currentDate = widget.selectedDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _mataKuliahController.dispose();
    _dosenController.dispose();
    _ruanganController.dispose();
    _jamMulaiController.dispose();
    _jamSelesaiController.dispose();
    super.dispose();
  }

  String _formatDateString(DateTime dt) {
    final dayName = _dayNames[dt.weekday - 1];
    final monthName = _months[dt.month];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }

  String _formatDateKey(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF3563E9),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF3563E9),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _currentDate = picked;
      });
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF3563E9),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF3563E9),
                    onPrimary: Colors.white,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      setState(() {
        controller.text = '$hour.$minute';
      });
    }
  }

  Future<void> _saveJadwal() async {
    if (_formKey.currentState!.validate()) {
      final dayName = _dayNames[_currentDate.weekday - 1];

      final newJadwal = Jadwal(
        id: widget.jadwal?.id,
        docId: widget.jadwal?.docId,
        mataKuliah: _mataKuliahController.text.trim(),
        dosen: _dosenController.text.trim(),
        ruangan: _ruanganController.text.trim(),
        jamMulai: _jamMulaiController.text.trim().isEmpty
            ? '08.00'
            : _jamMulaiController.text.trim(),
        jamSelesai: _jamSelesaiController.text.trim().isEmpty
            ? '09.40'
            : _jamSelesaiController.text.trim(),
        hari: dayName,
        tanggal: _formatDateKey(_currentDate),
        isAlarmActive: _isAlarmActive,
        alarmMinutesList: _alarmMinutesList.toList()
          ..sort((a, b) => b.compareTo(a)),
      );

      int insertedOrUpdatedId;
      if (widget.jadwal == null) {
        insertedOrUpdatedId = await DatabaseService.instance.insertJadwal(
          newJadwal,
        );
      } else {
        insertedOrUpdatedId = await DatabaseService.instance.updateJadwal(
          newJadwal,
        );
      }

      // Sync Notification Alarm
      final finalJadwal = newJadwal.copyWith(
        id: newJadwal.id ?? insertedOrUpdatedId,
      );
      if (_isAlarmActive) {
        await NotificationService.instance.requestPermissions();
        await NotificationService.instance.scheduleWeeklyJadwalAlarm(
          finalJadwal,
        );
      } else if (finalJadwal.id != null) {
        await NotificationService.instance.cancelJadwalAlarm(finalJadwal.id!);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.jadwal != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: titleColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Jadwal' : 'Tambah Jadwal',
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detail perkuliahan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lengkapi jadwal kuliahmu di bawah ini. Semua kolom wajib diisi.',
                style: TextStyle(fontSize: 13, color: subtitleColor),
              ),
              const SizedBox(height: 24),

              // 1. Nama mata kuliah
              _buildLabel('Nama mata kuliah', labelColor),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _mataKuliahController,
                hint: 'Contoh: Basis Data',
                validator: (val) => val == null || val.isEmpty
                    ? 'Mata kuliah tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),

              // 2. Dosen pengampu
              _buildLabel('Dosen pengampu', labelColor),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _dosenController,
                hint: 'Masukkan nama dosen',
                validator: (val) => val == null || val.isEmpty
                    ? 'Nama dosen tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),

              // 3. Ruang kuliah
              _buildLabel('Ruang kuliah', labelColor),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _ruanganController,
                hint: 'Contoh: Ruang G.203',
                validator: (val) => val == null || val.isEmpty
                    ? 'Ruang kuliah tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),

              // 4. Hari / tanggal
              _buildLabel('Hari / tanggal', labelColor),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDateString(_currentDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: titleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Waktu mulai & Waktu selesai
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Waktu mulai', labelColor),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _pickTime(_jamMulaiController),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _jamMulaiController.text.isEmpty
                                      ? 'Pilih waktu'
                                      : _jamMulaiController.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _jamMulaiController.text.isEmpty
                                        ? const Color(0xFF94A3B8)
                                        : titleColor,
                                  ),
                                ),
                                const Icon(
                                  Icons.access_time_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Waktu selesai', labelColor),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _pickTime(_jamSelesaiController),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _jamSelesaiController.text.isEmpty
                                      ? 'Pilih waktu'
                                      : _jamSelesaiController.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _jamSelesaiController.text.isEmpty
                                        ? const Color(0xFF94A3B8)
                                        : titleColor,
                                  ),
                                ),
                                const Icon(
                                  Icons.access_time_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 6. Pengaturan Alarm Mingguan
              _buildAlarmSettingsCard(isDark, labelColor, borderColor),

              const SizedBox(height: 36),

              // Primary Action: Simpan Jadwal
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3563E9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _saveJadwal,
                  child: const Text(
                    'Simpan Jadwal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Action: Batal
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmSettingsCard(
    bool isDark,
    Color labelColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3563E9).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.alarm_rounded,
                  color: Color(0xFF3563E9),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alarm Pengingat Mingguan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Notifikasi berulang tiap jam perkuliahan',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isAlarmActive,
                activeThumbColor: const Color(0xFF3563E9),
                onChanged: (val) {
                  setState(() {
                    _isAlarmActive = val;
                  });
                },
              ),
            ],
          ),
          if (_isAlarmActive) ...[
            const SizedBox(height: 14),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 14),
            Text(
              'Bunyikan Alarm Sebelum Kelas:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [5, 10, 15, 30].map((mins) {
                final isSelected = _alarmMinutesList.contains(mins);
                return ChoiceChip(
                  label: Text('$mins Menit'),
                  selected: isSelected,
                  selectedColor: const Color(0xFF3563E9),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF3563E9) : borderColor,
                    ),
                  ),
                  onSelected: (selected) {
                    if (!selected && _alarmMinutesList.length == 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pilih minimal satu waktu pengingat.'),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      if (selected) {
                        _alarmMinutesList.add(mins);
                      } else {
                        _alarmMinutesList.remove(mins);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih satu atau beberapa waktu pengingat.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color textColor) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3563E9), width: 1.5),
        ),
      ),
    );
  }
}
