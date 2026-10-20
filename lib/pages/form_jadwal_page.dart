import 'package:flutter/material.dart';
import '../models/jadwal.dart';
import '../services/database_service.dart';

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

  final List<String> _months = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  final List<String> _dayNames = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
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
        mataKuliah: _mataKuliahController.text.trim(),
        dosen: _dosenController.text.trim(),
        ruangan: _ruanganController.text.trim(),
        jamMulai: _jamMulaiController.text.trim().isEmpty ? '08.00' : _jamMulaiController.text.trim(),
        jamSelesai: _jamSelesaiController.text.trim().isEmpty ? '09.40' : _jamSelesaiController.text.trim(),
        hari: dayName,
        tanggal: _formatDateKey(_currentDate),
      );

      if (widget.jadwal == null) {
        await DatabaseService.instance.insertJadwal(newJadwal);
      } else {
        await DatabaseService.instance.updateJadwal(newJadwal);
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
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

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
                style: TextStyle(
                  fontSize: 13,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 24),

              // 1. Nama mata kuliah
              _buildLabel('Nama mata kuliah', labelColor),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _mataKuliahController,
                hint: 'Contoh: Basis Data',
                validator: (val) => val == null || val.isEmpty ? 'Mata kuliah tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // 2. Dosen pengampu
              _buildLabel('Dosen pengampu', labelColor),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _dosenController,
                hint: 'Masukkan nama dosen',
                validator: (val) => val == null || val.isEmpty ? 'Nama dosen tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // 3. Ruang kuliah
              _buildLabel('Ruang kuliah', labelColor),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _ruanganController,
                hint: 'Contoh: Ruang G.203',
                validator: (val) => val == null || val.isEmpty ? 'Ruang kuliah tidak boleh kosong' : null,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _jamMulaiController.text.isEmpty ? 'Pilih waktu' : _jamMulaiController.text,
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _jamSelesaiController.text.isEmpty ? 'Pilih waktu' : _jamSelesaiController.text,
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
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
