import 'package:flutter/material.dart';
import '../models/jadwal.dart';
import '../models/catatan.dart';
import '../services/database_service.dart';

class CatatanDialog extends StatefulWidget {
  final Jadwal jadwal;

  const CatatanDialog({super.key, required this.jadwal});

  static Future<void> show(BuildContext context, Jadwal jadwal) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CatatanDialog(jadwal: jadwal),
    );
  }

  @override
  State<CatatanDialog> createState() => _CatatanDialogState();
}

class _CatatanDialogState extends State<CatatanDialog> {
  List<Catatan> _existingNotes = [];
  bool _isLoading = true;
  bool _isCreatingNew = false;
  Catatan? _editingCatatan;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _isiController;
  String _selectedTipe = 'catatan';
  int _selectedMingguKe = 1;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController();
    _isiController = TextEditingController();
    _loadNotes();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await DatabaseService.instance.getCatatanByMataKuliah(widget.jadwal.mataKuliah);
    setState(() {
      _existingNotes = notes;
      _isLoading = false;
    });
  }

  void _startCreating() {
    setState(() {
      _isCreatingNew = true;
      _editingCatatan = null;
      _selectedMingguKe = 1;
      _selectedTipe = 'catatan';
      _judulController.text = 'Catatan - ${widget.jadwal.mataKuliah}';
      _isiController.clear();
    });
  }

  void _startEditing(Catatan note) {
    setState(() {
      _isCreatingNew = true;
      _editingCatatan = note;
      _selectedMingguKe = note.mingguKe;
      _selectedTipe = (note.tipe == 'tugas') ? 'tugas' : 'catatan';
      _judulController.text = note.judul;
      _isiController.text = note.isi;
    });
  }

  Future<void> _saveNote() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final timeStr = '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';

      if (_editingCatatan == null) {
        final newNote = Catatan(
          jadwalId: widget.jadwal.docId ?? widget.jadwal.id?.toString(),
          mataKuliah: widget.jadwal.mataKuliah,
          mingguKe: _selectedMingguKe,
          judul: _judulController.text.trim(),
          isi: _isiController.text.trim(),
          tanggal: dateStr,
          waktu: timeStr,
          tipe: _selectedTipe,
          createdAt: now.toIso8601String(),
        );
        await DatabaseService.instance.insertCatatan(newNote);
      } else {
        final updated = _editingCatatan!.copyWith(
          mingguKe: _selectedMingguKe,
          judul: _judulController.text.trim(),
          isi: _isiController.text.trim(),
          tipe: _selectedTipe,
        );
        await DatabaseService.instance.updateCatatan(updated);
      }

      setState(() {
        _isCreatingNew = false;
        _editingCatatan = null;
      });
      _loadNotes();
    }
  }

  Future<void> _deleteNote(Catatan note) async {
    if (note.id != null) {
      await DatabaseService.instance.deleteCatatan(note.id!, docId: note.docId);
      _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3563E9).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.note_alt_rounded,
                    color: Color(0xFF3563E9),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan & Tugas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        widget.jadwal.mataKuliah,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: subtitleColor,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _isCreatingNew ? _buildNoteForm(isDark) : _buildNotesList(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final Map<int, List<Catatan>> grouped = {};
    for (var note in _existingNotes) {
      grouped.putIfAbsent(note.mingguKe, () => []).add(note);
    }
    final sortedWeeks = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_existingNotes.length} Catatan / Tugas',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: subtitleColor,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3563E9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                elevation: 0,
              ),
              onPressed: _startCreating,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Tambah',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_existingNotes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.note_add_outlined, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                Text(
                  'Belum ada catatan atau tugas.',
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Klik tombol Tambah untuk membuat catatan atau tugas baru!',
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedWeeks.length,
            itemBuilder: (context, index) {
              final weekNum = sortedWeeks[index];
              final weekNotes = grouped[weekNum]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_special_rounded, color: Color(0xFF3563E9), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Minggu Ke-$weekNum',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3563E9).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${weekNotes.length} item',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3563E9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...weekNotes.map((note) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: _buildNoteCard(note, isDark),
                      )),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildNoteCard(Catatan note, bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  Text(
                    '${note.tanggal} • ${note.waktu}',
                    style: TextStyle(fontSize: 11, color: subtitleColor),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _startEditing(note),
                    child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF3563E9)),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _deleteNote(note),
                    child: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note.judul,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note.isi,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteForm(bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _editingCatatan == null ? 'Tambah Baru' : 'Edit Item',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isCreatingNew = false;
                    _editingCatatan = null;
                  });
                },
                child: const Text('Batal'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pertemuan / Minggu Ke Dropdown
          Text('Minggu / Pertemuan Ke-', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: labelColor)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _selectedMingguKe,
            dropdownColor: Theme.of(context).cardColor,
            style: TextStyle(color: titleColor, fontSize: 14),
            decoration: _inputDecoration('', borderColor),
            items: List.generate(16, (i) => i + 1)
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text('Minggu Ke-$m / Pertemuan $m'),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedMingguKe = val;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Kategori: Catatan / Tugas
          Text('Kategori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: labelColor)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTipeOption('catatan', 'Catatan', Icons.description_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTipeOption('tugas', 'Tugas', Icons.assignment_outlined),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Judul
          Text('Judul', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: labelColor)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _judulController,
            style: TextStyle(color: titleColor, fontSize: 14),
            validator: (val) => val == null || val.isEmpty ? 'Judul tidak boleh kosong' : null,
            decoration: _inputDecoration('Contoh: Catatan Dosen Bab 3 / Tugas ERD', borderColor),
          ),
          const SizedBox(height: 16),

          // Isi
          Text('Isi Detail', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: labelColor)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _isiController,
            maxLines: 5,
            style: TextStyle(color: titleColor, fontSize: 14),
            validator: (val) => val == null || val.isEmpty ? 'Isi tidak boleh kosong' : null,
            decoration: _inputDecoration('Tuliskan ringkasan materi atau detail tugas...', borderColor),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3563E9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _saveNote,
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipeOption(String tipe, String label, IconData icon) {
    final isSelected = _selectedTipe == tipe;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTipe = tipe;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3563E9) : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3563E9) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF3563E9),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color borderColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3563E9), width: 1.5),
      ),
    );
  }
}
