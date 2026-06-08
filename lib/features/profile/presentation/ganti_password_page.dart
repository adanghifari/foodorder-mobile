import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../data/profile_api_service.dart';

class GantiPasswordPage extends StatefulWidget {
  const GantiPasswordPage({super.key});

  @override
  State<GantiPasswordPage> createState() => _GantiPasswordPageState();
}

class _GantiPasswordPageState extends State<GantiPasswordPage> {
  final ProfileApiService _profileApiService = ProfileApiService();

  bool _isSaving = false;
  bool _isCurrentObscure = true;
  bool _isNewObscure = true;
  bool _isConfirmObscure = true;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      AppNotice.show(
        context,
        'Semua field wajib diisi.',
        type: AppNoticeType.error,
      );
      return;
    }

    if (newPassword.length < 6) {
      AppNotice.show(
        context,
        'Password baru minimal harus 6 karakter.',
        type: AppNoticeType.error,
      );
      return;
    }

    if (newPassword == currentPassword) {
      AppNotice.show(
        context,
        'Password baru tidak boleh sama dengan password sekarang.',
        type: AppNoticeType.error,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      AppNotice.show(
        context,
        'Konfirmasi password baru tidak cocok.',
        type: AppNoticeType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _profileApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: confirmPassword,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      AppNotice.show(
        context,
        'Password berhasil diubah.',
        type: AppNoticeType.success,
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppNotice.show(
        context,
        AppNotice.humanizeMessage(e),
        type: AppNoticeType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBackButton(
          color: Colors.black,
          size: 20,
        ),
        title: const Text(
          "Ganti Password",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            _buildLabel('Password Sekarang'),
            const SizedBox(height: 6),
            _buildPasswordInput(
              hint: 'Masukkan password saat ini',
              controller: _currentPasswordController,
              isObscure: _isCurrentObscure,
              onToggleObscure: () => setState(() => _isCurrentObscure = !_isCurrentObscure),
            ),
            const SizedBox(height: 18),

            _buildLabel('Password Baru'),
            const SizedBox(height: 6),
            _buildPasswordInput(
              hint: 'Masukkan password baru',
              controller: _newPasswordController,
              isObscure: _isNewObscure,
              onToggleObscure: () => setState(() => _isNewObscure = !_isNewObscure),
            ),
            const SizedBox(height: 18),

            _buildLabel('Konfirmasi Password Baru'),
            const SizedBox(height: 6),
            _buildPasswordInput(
              hint: 'Masukkan kembali password baru',
              controller: _confirmPasswordController,
              isObscure: _isConfirmObscure,
              onToggleObscure: () => setState(() => _isConfirmObscure = !_isConfirmObscure),
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC6620C),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFFC6620C).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Simpan Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPasswordInput({
    required String hint,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onToggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: onToggleObscure,
          ),
        ),
      ),
    );
  }
}
