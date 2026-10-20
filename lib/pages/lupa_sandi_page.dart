import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LupaSandiPage extends StatefulWidget {
  final String initialEmail;

  const LupaSandiPage({super.key, this.initialEmail = ''});

  @override
  State<LupaSandiPage> createState() => _LupaSandiPageState();
}

class _LupaSandiPageState extends State<LupaSandiPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await AuthService().sendPasswordResetEmail(
          _emailController.text.trim(),
        );

        if (mounted) {
          _emailController.text = _emailController.text.trim();
          setState(() {
            _isSent = true;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

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
          child: _isSent
              ? _buildSuccessView(titleColor, subtitleColor)
              : _buildFormView(titleColor, subtitleColor, borderColor),
        ),
      ),
    );
  }

  Widget _buildFormView(
    Color titleColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Icon Header
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3563E9).withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF3563E9),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Header Title
          Center(
            child: Text(
              'Lupa Kata Sandi?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: titleColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Masukkan email mahasiswa yang terdaftar pada akun StudyPlan Anda. Kami akan mengirimkan instruksi untuk mengatur ulang kata sandi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: subtitleColor, height: 1.5),
            ),
          ),
          const SizedBox(height: 36),

          // Label Email Input
          Text(
            'Email Mahasiswa',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: titleColor, fontSize: 14),
            validator: (val) {
              final email = val?.trim() ?? '';
              if (email.isEmpty) return 'Masukkan email Anda';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                return 'Format email tidak valid';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'nama@mahasiswa.ac.id',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF3563E9),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Tombol Kirim Reset
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
              onPressed: _isLoading ? null : _handleResetPassword,
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
                      'Kirim Link Reset Kata Sandi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Link Kembali ke Login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sudah ingat kata sandi? ',
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
        ],
      ),
    );
  }

  Widget _buildSuccessView(Color titleColor, Color subtitleColor) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: Color(0xFF16A34A),
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Email Berhasil Dikirim!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Instruksi reset kata sandi telah dikirim ke:\n${_emailController.text}\n\nSilakan periksa kotak masuk atau folder spam email Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: subtitleColor, height: 1.5),
        ),
        const SizedBox(height: 36),

        // Tombol Kembali ke Login
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
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Kembali ke Halaman Masuk',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
