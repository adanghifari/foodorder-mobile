import 'package:flutter/material.dart';
import '../../../app/app_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_notice.dart';
import '../data/auth_api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _authApiService = AuthApiService();
  bool _isSubmitting = false;

  static const Color primaryBrown = Color(0xFFA0522D);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  Future<void> _submitRequest() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AppNotice.show(context, 'Silakan masukkan email Anda.', type: AppNoticeType.error);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authApiService.requestOtp(email);
      if (mounted) {
        await AppNotice.confirm(
          context,
          message: 'Kode OTP berhasil dikirim ke email Anda.',
          type: AppNoticeType.success,
        );
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.otpVerification,
            arguments: {'email': email},
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
                    'Lupa Password',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masukkan alamat email Anda untuk menerima kode OTP 6-digit.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildLabel('Alamat Email'),
                  const SizedBox(height: 6),
                  _buildInput(
                    hint: 'email@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
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

  Widget _buildInput({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
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
        onPressed: _isSubmitting ? null : _submitRequest,
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
          _isSubmitting ? 'Mengirim...' : 'Kirim OTP',
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
