import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../shared/widgets/app_notice.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../data/auth_api_service.dart';
import '../data/auth_session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isObscure = true;
  bool remember = false;
  bool _isSubmitting = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService();

  static const Color primaryBrown = Color(0xFFA0522D);

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                  _buildLabel('Username'),
                  const SizedBox(height: 6),
                  _buildInput(
                    hint: 'username',
                    controller: _usernameController,
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('Password'),
                  const SizedBox(height: 6),
                  _buildPasswordInput(controller: _passwordController),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: remember,
                          activeColor: primaryBrown,
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                          onChanged: (val) =>
                              setState(() => remember = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember me',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const Spacer(),
                      const Text(
                        'Forgot Password ?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildRegisterPrompt(context),
                  const SizedBox(height: 12),
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
    return SizedBox(
      height: 220,
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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Image.asset(
                  'assets/logo.png',
                  width: screenWidth * 0.80,
                ),
              ),
            ),
          ),
          Positioned(
            top: 36,
            left: 12,
            child: const AppBackButton(
              icon: Icons.arrow_back,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterPrompt(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Belum punya akun? ',
          style: TextStyle(color: Colors.grey),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.register),
          child: const Text(
            'Daftar',
            style: TextStyle(
              color: primaryBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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

  Widget _buildPasswordInput({required TextEditingController controller}) {
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
              isObscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: () => setState(() => isObscure = !isObscure),
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
        onPressed: _isSubmitting ? null : _submitLogin,
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
          _isSubmitting ? 'Loading...' : 'Log In',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Future<void> _submitLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      AppNotice.show(
        context,
        'Username dan password wajib diisi.',
        type: AppNoticeType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final token = await _authApiService.login(
        username: username,
        password: password,
      );
      await AuthSession.setToken(token);
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      final fromGuardedFlow = args is Map && (args['returnToPrevious'] == true);

      if (fromGuardedFlow && Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.landing);
      }
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(context, 'Login gagal: $e', type: AppNoticeType.error);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
