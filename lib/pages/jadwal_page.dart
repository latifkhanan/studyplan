import 'package:flutter/material.dart';
import '../models/jadwal.dart';
import '../services/database_service.dart';
import '../widgets/jadwal_card.dart';
import '../widgets/delete_confirmation_dialog.dart';
import 'form_jadwal_page.dart';

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  List<Jadwal> _daySchedules = [];
  List<String> _datesWithClasses = [];
  bool _isLoading = true;

  final List<String> _weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  final List<String> _months = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final formattedDate = _formatDateKey(_selectedDate);
    final dayData = await DatabaseService.instance.getJadwalByTanggal(formattedDate);
    final datesWithData = await DatabaseService.instance.getDatesWithJadwal();

    setState(() {
      _daySchedules = dayData;
      _datesWithClasses = datesWithData;
      _isLoading = false;
    });
  }

  String _formatDateKey(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatDateHeader(DateTime dt) {
    final dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final dayName = dayNames[dt.weekday - 1];
    final monthName = _months[dt.month];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }

  Future<void> _openForm({Jadwal? item}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormJadwalPage(
          jadwal: item,
          selectedDate: _selectedDate,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteItem(Jadwal item) async {
    final confirm = await showDeleteConfirmationDialog(context, item);

    if (confirm == true && item.id != null) {
      await DatabaseService.instance.deleteJadwal(item.id!, docId: item.docId);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jadwal Kuliah',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildCalendarCard(),
          const SizedBox(height: 24),
          _buildSectionHeader(),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _buildScheduleList(),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month Header: < Oktober 2026 >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left_rounded, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                  });
                },
              ),
              Text(
                '${_months[_currentMonth.month]} ${_currentMonth.year}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Weekday Headers: Sen, Sel, Rab, Kam, Jum, Sab, Min
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekdays
                .map(
                  (day) => SizedBox(
                    width: 32,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1 = Mon, 7 = Sun
    final offset = firstDayWeekday - 1; // Number of empty cells before 1st day

    final totalCells = offset + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalRows * 7,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - offset + 1;

        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
        final dateKey = _formatDateKey(cellDate);

        final isSelected = _selectedDate.year == cellDate.year &&
            _selectedDate.month == cellDate.month &&
            _selectedDate.day == cellDate.day;

        // Has dots if in datesWithClasses or defaults for demo
        final hasClass = _datesWithClasses.contains(dateKey) ||
            ([6, 7, 8, 13, 14, 15, 20, 21, 22, 27, 28, 29].contains(dayNumber) && _currentMonth.month == 10 && _currentMonth.year == 2026);

        final dayTextColor = isSelected
            ? Colors.white
            : (isDark ? Colors.white : const Color(0xFF1E293B));

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = cellDate;
            });
            _loadData();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3563E9) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: dayTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: hasClass && !isSelected ? const Color(0xFF3563E9) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jadwal Hari Ini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_formatDateHeader(_selectedDate)} · ${_daySchedules.length} kelas',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        Material(
          color: const Color(0xFF3563E9),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openForm(),
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_daySchedules.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'Tidak ada kelas pada tanggal ini.',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _daySchedules.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = _daySchedules[index];
        return JadwalCard(
          jadwal: item,
          onEdit: () => _openForm(item: item),
          onDelete: () => _deleteItem(item),
        );
      },
    );
  }
}
