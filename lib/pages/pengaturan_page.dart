import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/logout_confirmation_dialog.dart';

enum AppThemeMode { terang, gelap, sistem }

class PengaturanPage extends StatefulWidget {
  final AppThemeMode currentTheme;
  final ValueChanged<AppThemeMode> onThemeChanged;
  final VoidCallback? onLogout;

  const PengaturanPage({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    this.onLogout,
  });

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  late AppThemeMode _selectedTheme;

  // Profil Pengguna Data
  String _userName = 'Pengguna StudyPlan';
  String _userEmail = '-';
  String _userNim = '-';
  String _userProdi = '-';

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final currentUser = AuthService().currentUser;
    if (currentUser != null) {
      if (mounted) {
        setState(() {
          if (currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
            _userName = currentUser.displayName!;
          }
          if (currentUser.email != null && currentUser.email!.isNotEmpty) {
            _userEmail = currentUser.email!;
          }
        });
      }

      final profileData = await AuthService().getUserProfile();
      if (profileData != null && mounted) {
        setState(() {
          _userName = profileData['nama'] ?? _userName;
          _userEmail = profileData['email'] ?? _userEmail;
          _userNim = profileData['nim'] ?? _userNim;
          _userProdi = profileData['prodi'] ?? _userProdi;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final sectionHeaderColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengaturan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: titleColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

          // 1. Profil Pengguna Section
          Text(
            'Profil Pengguna',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: sectionHeaderColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildProfileCard(),
          const SizedBox(height: 24),

          // 2. Branding Card
          _buildBrandingCard(),
          const SizedBox(height: 24),

          // 3. Tampilan Section
          Text(
            'Tampilan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: sectionHeaderColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildThemeCard(),
          const SizedBox(height: 24),

          // 4. Tentang Aplikasi Section
          Text(
            'Tentang aplikasi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: sectionHeaderColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildAboutCard(),
          const SizedBox(height: 24),

          // 5. Logout Action
          if (widget.onLogout != null) _buildLogoutCard(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF3563E9),
                    child: Text(
                      _getInitials(_userName),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).cardColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Detail Profile Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIM: $_userNim • $_userProdi',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: Color(0xFF3563E9),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _userEmail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF3563E9),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            height: 1,
          ),
          const SizedBox(height: 12),
          // Edit Profil Button
          InkWell(
            onTap: _showEditProfileModal,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Color(0xFF3563E9),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Edit Profil',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3563E9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _showEditProfileModal() {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);
    final nimController = TextEditingController(text: _userNim);
    final prodiController = TextEditingController(text: _userProdi);
    final formKey = GlobalKey<FormState>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Edit Profil Pengguna',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nama Lengkap
                  _buildModalFieldLabel('Nama Lengkap', titleColor),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameController,
                    style: TextStyle(color: titleColor, fontSize: 14),
                    validator: (val) => val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
                    decoration: _modalInputDecoration('Contoh: Budi Santoso', Icons.person_outline, borderColor),
                  ),
                  const SizedBox(height: 14),

                  // Email
                  _buildModalFieldLabel('Email Mahasiswa', titleColor),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: emailController,
                    style: TextStyle(color: titleColor, fontSize: 14),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val == null || val.isEmpty ? 'Email tidak boleh kosong' : null,
                    decoration: _modalInputDecoration('nama@mahasiswa.ac.id', Icons.email_outlined, borderColor),
                  ),
                  const SizedBox(height: 14),

                  // NIM
                  _buildModalFieldLabel('NIM', titleColor),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nimController,
                    style: TextStyle(color: titleColor, fontSize: 14),
                    validator: (val) => val == null || val.isEmpty ? 'NIM tidak boleh kosong' : null,
                    decoration: _modalInputDecoration('Contoh: 220101001', Icons.badge_outlined, borderColor),
                  ),
                  const SizedBox(height: 14),

                  // Program Studi
                  _buildModalFieldLabel('Program Studi', titleColor),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: prodiController,
                    style: TextStyle(color: titleColor, fontSize: 14),
                    validator: (val) => val == null || val.isEmpty ? 'Program Studi tidak boleh kosong' : null,
                    decoration: _modalInputDecoration('Contoh: Teknik Informatika', Icons.school_outlined, borderColor),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
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
                          setState(() {
                            _userName = nameController.text.trim();
                            _userEmail = emailController.text.trim();
                            _userNim = nimController.text.trim();
                            _userProdi = prodiController.text.trim();
                          });

                          try {
                            await AuthService().updateUserProfile(
                              nama: _userName,
                              nim: _userNim,
                              prodi: _userProdi,
                            );
                          } catch (_) {}

                          if (mounted && context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
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
  }

  Widget _buildModalFieldLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  InputDecoration _modalInputDecoration(String hint, IconData icon, Color borderColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
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

  Widget _buildBrandingCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF3563E9),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'StudyPlan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Jadwal kuliah lebih rapi,\nbelajar jadi lebih tenang.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.wb_sunny_outlined,
                color: Color(0xFF3563E9),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Tema aplikasi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(child: _buildSegmentOption(AppThemeMode.terang, 'Terang')),
                Expanded(child: _buildSegmentOption(AppThemeMode.gelap, 'Gelap')),
                Expanded(child: _buildSegmentOption(AppThemeMode.sistem, 'Sistem')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentOption(AppThemeMode mode, String label) {
    final isSelected = _selectedTheme == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = mode;
        });
        widget.onThemeChanged(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: const Color(0xFF3563E9), width: 1.5)
              : Border.all(color: Colors.transparent),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color.fromRGBO(0, 0, 0, 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: Color(0xFF3563E9),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF3563E9)
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF3563E9),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Versi aplikasi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Text(
            '1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () async {
        final confirm = await showLogoutConfirmationDialog(
          context,
          userName: _userName,
          userEmail: _userEmail,
        );
        if (confirm == true && widget.onLogout != null) {
          widget.onLogout!();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFECDD3),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: Color(0xFFDC2626),
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Keluar dari Akun',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
