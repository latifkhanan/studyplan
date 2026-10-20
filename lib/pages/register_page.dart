import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback onRegisterSuccess;

  const RegisterPage({super.key, required this.onRegisterSuccess});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nimController = TextEditingController();
  final _prodiController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    _prodiController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreeTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan setujui Syarat & Ketentuan terlebih dahulu.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        await AuthService().register(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          nama: _fullNameController.text.trim(),
          nim: _nimController.text.trim(),
          prodi: _prodiController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi berhasil! Akun Anda telah dibuat.'),
              backgroundColor: Color(0xFF3563E9),
            ),
          );
          Navigator.pop(context);
          widget.onRegisterSuccess();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: titleColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title
                Text(
                  'Buat Akun Baru',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mulai atur jadwal perkuliahanmu dengan mendaftar di StudyPlan.',
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 28),

                // 1. Nama Lengkap
                _buildLabel('Nama Lengkap', titleColor),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _fullNameController,
                  hint: 'Contoh: Budi Santoso',
                  icon: Icons.person_outline,
                  titleColor: titleColor,
                  borderColor: borderColor,
                  validator: (val) => val == null || val.isEmpty ? 'Masukkan nama lengkap Anda' : null,
                ),
                const SizedBox(height: 16),

                // 2. Email Mahasiswa
                _buildLabel('Email Mahasiswa', titleColor),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _emailController,
                  hint: 'nama@mahasiswa.ac.id',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  titleColor: titleColor,
                  borderColor: borderColor,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Masukkan email mahasiswa Anda';
                    if (!val.contains('@')) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 3. NIM
                _buildLabel('NIM (Nomor Induk Mahasiswa)', titleColor),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _nimController,
                  hint: 'Contoh: 220101001',
                  icon: Icons.badge_outlined,
                  titleColor: titleColor,
                  borderColor: borderColor,
                  validator: (val) => val == null || val.isEmpty ? 'Masukkan NIM Anda' : null,
                ),
                const SizedBox(height: 16),

                // 4. Program Studi
                _buildLabel('Program Studi', titleColor),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _prodiController,
                  hint: 'Contoh: Sistem Informasi',
                  icon: Icons.school_outlined,
                  titleColor: titleColor,
                  borderColor: borderColor,
                  validator: (val) => val == null || val.isEmpty ? 'Masukkan Program Studi Anda' : null,
                ),
                const SizedBox(height: 16),

                // 4. Kata Sandi
                _buildLabel('Kata Sandi', titleColor),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: TextStyle(color: titleColor, fontSize: 14),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Masukkan kata sandi';
                    if (val.length < 6) return 'Kata sandi minimal 6 karakter';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Minimal 6 karakter',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
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
                ),
                const SizedBox(height: 16),

                // 5. Konfirmasi Kata Sandi
                _buildLabel('Konfirmasi Kata Sandi', titleColor),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  style: TextStyle(color: titleColor, fontSize: 14),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Ulangi kata sandi Anda';
                    if (val != _passwordController.text) return 'Kata sandi tidak cocok';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Ulangi kata sandi',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
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
                ),
                const SizedBox(height: 16),

                // Checkbox Terms
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeTerms,
                        activeColor: const Color(0xFF3563E9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() {
                            _agreeTerms = val ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Saya menyetujui Syarat & Ketentuan StudyPlan.',
                        style: TextStyle(fontSize: 13, color: subtitleColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Tombol Daftar
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
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Daftar Sekarang',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bottom Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sudah punya akun? ',
                      style: TextStyle(fontSize: 14, color: subtitleColor),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3563E9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color titleColor,
    required Color borderColor,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: titleColor, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
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
