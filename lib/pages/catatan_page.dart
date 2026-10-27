import 'package:flutter/material.dart';

import '../models/catatan.dart';
import '../models/jadwal.dart';
import '../services/database_service.dart';

class CatatanPage extends StatefulWidget {
  final bool isActive;

  const CatatanPage({super.key, this.isActive = false});

  @override
  State<CatatanPage> createState() => _CatatanPageState();
}

class _CatatanPageState extends State<CatatanPage> {
  List<Catatan> _allNotes = [];
  List<Catatan> _filteredNotes = [];
  List<Jadwal> _allJadwal = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant CatatanPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    final notes = await DatabaseService.instance.getAllCatatan();
    final schedules = await DatabaseService.instance.getAllJadwal();

    if (!mounted) return;
    setState(() {
      _allNotes = notes;
      _allJadwal = schedules;
      _isLoading = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    List<Catatan> list = List.from(_allNotes);

    if (_selectedFilter == 'Catatan') {
      list = list.where((n) => n.tipe != 'tugas').toList();
    } else if (_selectedFilter == 'Tugas') {
      list = list.where((n) => n.tipe == 'tugas').toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      list = list.where((n) {
        return n.mataKuliah.toLowerCase().contains(query) ||
            n.judul.toLowerCase().contains(query) ||
            n.isi.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredNotes = list;
    });
  }

  Future<void> _deleteNote(Catatan note) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus ${note.tipe == "tugas" ? "Tugas" : "Catatan"}?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Item "${note.judul}" akan dihapus permanen.',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && note.id != null) {
      await DatabaseService.instance.deleteCatatan(note.id!, docId: note.docId);
      _loadData();
    }
  }

  void _showAddNoteDialog({Catatan? editNote}) {
    final formKey = GlobalKey<FormState>();
    final judulController = TextEditingController(text: editNote?.judul ?? '');
    final isiController = TextEditingController(text: editNote?.isi ?? '');

    String selectedMataKuliah =
        editNote?.mataKuliah ??
        (_allJadwal.isNotEmpty
            ? _allJadwal.first.mataKuliah
            : 'Mata Kuliah Umum');
    String selectedTipe = (editNote?.tipe == 'tugas') ? 'tugas' : 'catatan';
    int selectedMingguKe = editNote?.mingguKe ?? 1;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        editNote == null
                            ? 'Tambah Catatan / Tugas'
                            : 'Edit Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mata Kuliah Dropdown
                      Text(
                        'Mata Kuliah',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_allJadwal.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue:
                              _allJadwal.any(
                                (j) => j.mataKuliah == selectedMataKuliah,
                              )
                              ? selectedMataKuliah
                              : _allJadwal.first.mataKuliah,
                          dropdownColor: Theme.of(context).cardColor,
                          style: TextStyle(color: titleColor, fontSize: 14),
                          decoration: _inputDecoration('', borderColor),
                          items: _allJadwal
                              .map((j) => j.mataKuliah)
                              .toSet()
                              .map(
                                (mk) => DropdownMenuItem(
                                  value: mk,
                                  child: Text(mk),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setModalState(() => selectedMataKuliah = val);
                          },
                        )
                      else
                        TextFormField(
                          initialValue: selectedMataKuliah,
                          style: TextStyle(color: titleColor, fontSize: 14),
                          decoration: _inputDecoration(
                            'Contoh: Pemrograman Mobile',
                            borderColor,
                          ),
                          onChanged: (val) => selectedMataKuliah = val,
                        ),
                      const SizedBox(height: 14),

                      // Minggu Ke Dropdown
                      Text(
                        'Minggu / Pertemuan Ke-',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: selectedMingguKe,
                        dropdownColor: Theme.of(context).cardColor,
                        style: TextStyle(color: titleColor, fontSize: 14),
                        decoration: _inputDecoration('', borderColor),
                        items: List.generate(16, (i) => i + 1)
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text('Minggu Ke-$m / Pertemuan $m'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null)
                            setModalState(() => selectedMingguKe = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Kategori: Catatan / Tugas
                      Text(
                        'Kategori',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Catatan',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              selected: selectedTipe == 'catatan',
                              selectedColor: const Color(0xFF3563E9),
                              labelStyle: TextStyle(
                                color: selectedTipe == 'catatan'
                                    ? Colors.white
                                    : titleColor,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (_) =>
                                  setModalState(() => selectedTipe = 'catatan'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Tugas',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              selected: selectedTipe == 'tugas',
                              selectedColor: const Color(0xFFEF4444),
                              labelStyle: TextStyle(
                                color: selectedTipe == 'tugas'
                                    ? Colors.white
                                    : titleColor,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (_) =>
                                  setModalState(() => selectedTipe = 'tugas'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Judul
                      Text(
                        'Judul',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: judulController,
                        style: TextStyle(color: titleColor, fontSize: 14),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Judul wajib diisi'
                            : null,
                        decoration: _inputDecoration(
                          'Contoh: Catatan Bab 3 / Tugas ERD',
                          borderColor,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Isi
                      Text(
                        'Isi Detail',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: isiController,
                        maxLines: 4,
                        style: TextStyle(color: titleColor, fontSize: 14),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Isi wajib diisi'
                            : null,
                        decoration: _inputDecoration(
                          'Tuliskan ringkasan materi atau instruksi tugas...',
                          borderColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Simpan Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3563E9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final now = DateTime.now();
                              final dateStr =
                                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                              final timeStr =
                                  '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';

                              if (editNote == null) {
                                final newNote = Catatan(
                                  mataKuliah: selectedMataKuliah,
                                  mingguKe: selectedMingguKe,
                                  judul: judulController.text.trim(),
                                  isi: isiController.text.trim(),
                                  tanggal: dateStr,
                                  waktu: timeStr,
                                  tipe: selectedTipe,
                                  createdAt: now.toIso8601String(),
                                );
                                await DatabaseService.instance.insertCatatan(
                                  newNote,
                                );
                              } else {
                                final updated = editNote.copyWith(
                                  mataKuliah: selectedMataKuliah,
                                  mingguKe: selectedMingguKe,
                                  judul: judulController.text.trim(),
                                  isi: isiController.text.trim(),
                                  tipe: selectedTipe,
                                );
                                await DatabaseService.instance.updateCatatan(
                                  updated,
                                );
                              }

                              if (mounted && context.mounted) {
                                Navigator.pop(context);
                                _loadData();
                              }
                            }
                          },
                          child: const Text(
                            'Simpan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint, Color borderColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3563E9), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    // Grouping: Mata Kuliah -> Minggu Ke -> List<Catatan>
    final Map<String, Map<int, List<Catatan>>> structuredMap = {};
    for (var note in _filteredNotes) {
      structuredMap.putIfAbsent(note.mataKuliah, () => {});
      structuredMap[note.mataKuliah]!
          .putIfAbsent(note.mingguKe, () => [])
          .add(note);
    }

    final courseKeys = structuredMap.keys.toList()..sort();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catatan & Tugas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  letterSpacing: -0.5,
                ),
              ),
              Material(
                color: const Color(0xFF3563E9),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showAddNoteDialog(),
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
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            controller: _searchController,
            style: TextStyle(color: titleColor, fontSize: 14),
            onChanged: (val) {
              _searchQuery = val;
              _applyFilter();
            },
            decoration: InputDecoration(
              hintText: 'Cari catatan, tugas, atau isi...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF94A3B8),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _searchQuery = '';
                        _applyFilter();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                borderSide: const BorderSide(
                  color: Color(0xFF3563E9),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Filter Chips (Semua, Catatan, Tugas)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Semua', 'Catatan', 'Tugas']
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: _selectedFilter == f,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilter = f);
                            _applyFilter();
                          }
                        },
                        showCheckmark: false,
                        selectedColor: const Color(0xFF3563E9),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedFilter == f
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedFilter == f
                              ? Colors.white
                              : subtitleColor,
                        ),
                        backgroundColor: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedFilter == f
                                ? const Color(0xFF3563E9)
                                : borderColor,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Structured Notes List Grouped by Course and Week
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _filteredNotes.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(36),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 52,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada catatan atau tugas.',
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tekan tombol + di atas untuk menambah item baru.',
                        style: TextStyle(fontSize: 12, color: subtitleColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: courseKeys.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final courseName = courseKeys[index];
                    final weekMap = structuredMap[courseName]!;
                    final sortedWeeks = weekMap.keys.toList()..sort();

                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
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
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3563E9)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Color(0xFF3563E9),
                              size: 22,
                            ),
                          ),
                          title: Text(
                            courseName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          subtitle: Text(
                            '${weekMap.values.fold(0, (sum, list) => sum + list.length)} Item • ${sortedWeeks.length} Pertemuan',
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: sortedWeeks.map((weekNum) {
                                  final weekNotes = weekMap[weekNum]!;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3563E9)
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.calendar_view_week_rounded,
                                              size: 14,
                                              color: Color(0xFF3563E9),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Minggu Ke-$weekNum / Pertemuan $weekNum',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF3563E9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ...weekNotes.map(
                                        (note) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10.0,
                                          ),
                                          child: _buildNoteItemCard(
                                            note,
                                            isDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildNoteItemCard(Catatan note, bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    final isTugas = note.tipe == 'tugas';
    final tagBg = isTugas ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF);
    final tagText = isTugas ? const Color(0xFFDC2626) : const Color(0xFF2563EB);
    final tagLabel = isTugas ? 'Tugas' : 'Catatan';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tagLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tagText,
                  ),
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => _showAddNoteDialog(editNote: note),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF3563E9),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _deleteNote(note),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note.judul,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note.isi,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.access_time_rounded, size: 13, color: subtitleColor),
              const SizedBox(width: 4),
              Text(
                '${note.tanggal} • ${note.waktu}',
                style: TextStyle(fontSize: 11, color: subtitleColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
