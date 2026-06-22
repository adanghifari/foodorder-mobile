import 'package:flutter/material.dart';
import '../../../app/app_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_notice.dart';
import '../data/auth_api_service.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String token;
  const ResetPasswordPage({super.key, required this.email, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authApiService = AuthApiService();
  
  bool _isSubmitting = false;
  bool _isObscurePassword = true;
  bool _isObscureConfirm = true;

  static const Color primaryBrown = Color(0xFFA0522D);

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  Future<void> _submitReset() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty || confirm.isEmpty) {
      AppNotice.show(context, 'Silakan isi kedua kolom password.', type: AppNoticeType.error);
      return;
    }

    if (password.length < 6) {
      AppNotice.show(context, 'Password minimal terdiri dari 6 karakter.', type: AppNoticeType.error);
      return;
    }

    if (password != confirm) {
      AppNotice.show(context, 'Konfirmasi password tidak cocok.', type: AppNoticeType.error);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authApiService.resetPassword(
        email: widget.email,
        token: widget.token,
        password: password,
      );
      if (mounted) {
        await AppNotice.confirm(
          context,
          message: 'Password Anda berhasil diubah. Silakan masuk dengan password baru Anda.',
          type: AppNoticeType.success,
        );
        if (mounted) {
          // Arahkan ke login page dan bersihkan tumpukan navigasi
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppNotice.show(
          context,
          AppNotice.humanizeMessage(e),
          type: AppNoticeType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masukkan password baru Anda di bawah ini.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildLabel('Password Baru'),
                  const SizedBox(height: 6),
                  _buildPasswordInput(
                    controller: _passwordController,
                    isObscure: _isObscurePassword,
                    onToggle: () => setState(() => _isObscurePassword = !_isObscurePassword),
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('Konfirmasi Password Baru'),
                  const SizedBox(height: 6),
                  _buildPasswordInput(
                    controller: _confirmPasswordController,
                    isObscure: _isObscureConfirm,
                    onToggle: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                  ),
                  const SizedBox(height: 35),
                  _buildButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final headerHeight = statusBarHeight + 200;

    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD9A066), Color(0xFFF4F4F4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: statusBarHeight + 10,
                bottom: 15,
              ),
              child: Center(
                child: Image.asset(
                  'assets/logo.png',
                  width: screenWidth * 0.6,
                ),
              ),
            ),
          ),
          Positioned(
            top: statusBarHeight > 0 ? statusBarHeight + 8 : 20,
            left: 12,
            child: AppBackButton(
              icon: Icons.arrow_back,
              color: Colors.black87,
              onPressed: _handleBack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildPasswordInput({
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: '••••••••',
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
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReset,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrown,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryBrown.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          _isSubmitting ? 'Menyimpan...' : 'Ubah Password',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
