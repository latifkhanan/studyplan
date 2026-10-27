import 'package:flutter/material.dart';
import '../models/jadwal.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/jadwal_card.dart';
import '../widgets/delete_confirmation_dialog.dart';
import 'form_jadwal_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Jadwal> _schedules = [];
  bool _isLoading = true;

  final List<String> _dayNames = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  final List<String> _months = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  Future<void> _loadJadwal() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final todayName = _dayNames[now.weekday - 1];
    final formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    var data = await DatabaseService.instance.getJadwalByTanggal(formattedDate);
    if (data.isEmpty) {
      data = await DatabaseService.instance.getJadwalByHari(todayName);
    }

    setState(() {
      _schedules = data;
      _isLoading = false;
    });
  }

  Future<void> _openFormPage({Jadwal? item}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormJadwalPage(jadwal: item),
      ),
    );

    if (result == true) {
      _loadJadwal();
    }
  }

  Future<void> _deleteJadwal(Jadwal item) async {
    final confirm = await showDeleteConfirmationDialog(context, item);

    if (confirm == true && item.id != null) {
      await DatabaseService.instance.deleteJadwal(item.id!, docId: item.docId);
      await NotificationService.instance.cancelJadwalAlarm(item.id!);
      _loadJadwal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildGreeting(),
          const SizedBox(height: 20),
          _buildSummaryCard(),
          const SizedBox(height: 24),
          _buildSectionHeader(),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _buildScheduleList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF3563E9),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'StudyPlan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final todayName = _dayNames[now.weekday - 1];
    final monthName = _months[now.month];
    final formattedDateText = '$todayName, ${now.day} $monthName ${now.year}';

    final user = AuthService().currentUser;
    final displayName = user?.displayName;
    final name = (displayName != null && displayName.isNotEmpty) ? displayName : 'Mahasiswa';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, $name!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formattedDateText,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = _schedules.length;
    String timeRange = '08.00–14.40';
    if (_schedules.isNotEmpty) {
      timeRange = '${_schedules.first.jamMulai}–${_schedules.last.jamSelesai}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFDBE0FE),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_outlined,
              color: Color(0xFF3563E9),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count kelas hari ini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$timeRange · Semangat belajar!',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Jadwal Hari Ini',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        Material(
          color: const Color(0xFF3563E9),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openFormPage(),
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_schedules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'Belum ada jadwal untuk hari ini.',
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
      itemCount: _schedules.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = _schedules[index];
        return JadwalCard(
          jadwal: item,
          onEdit: () => _openFormPage(item: item),
          onDelete: () => _deleteJadwal(item),
        );
      },
    );
  }
}
