import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/app_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_notice.dart';
import '../data/auth_api_service.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  const OtpVerificationPage({super.key, required this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  final _authApiService = AuthApiService();
  
  bool _isSubmitting = false;
  bool _canResend = false;
  int _countdown = 60;
  Timer? _timer;

  static const Color primaryBrown = Color(0xFFA0522D);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _countdown = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authApiService.requestOtp(widget.email);
      _startTimer();
      if (mounted) {
        AppNotice.show(context, 'Kode OTP baru berhasil dikirim.', type: AppNoticeType.success);
      }
    } catch (e) {
      if (mounted) {
        AppNotice.show(context, AppNotice.humanizeMessage(e), type: AppNoticeType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitOtp() async {
    String otp = _otpController.text;
    if (otp.length < 6) {
      AppNotice.show(context, 'Silakan isi seluruh 6 digit kode OTP.', type: AppNoticeType.error);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await _authApiService.verifyOtp(widget.email, otp);
      if (mounted) {
        await AppNotice.confirm(
          context,
          message: 'OTP berhasil diverifikasi.',
          type: AppNoticeType.success,
        );
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.resetPassword,
            arguments: {
              'email': widget.email,
              'token': token,
            },
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
                    'Verifikasi OTP',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan 6-digit kode OTP yang telah dikirim ke email:\n${widget.email}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 35),
                  _buildOtpInputRow(),
                  const SizedBox(height: 25),
                  _buildResendRow(),
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

  Widget _buildOtpInputRow() {
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          // Single hidden TextField to manage focus and keyboard
          TextField(
            controller: _otpController,
            focusNode: _otpFocusNode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            showCursor: false,
            style: const TextStyle(color: Colors.transparent),
            decoration: const InputDecoration(
              counterText: "",
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              setState(() {});
              if (value.length == 6) {
                _otpFocusNode.unfocus();
                _submitOtp();
              }
            },
          ),
          // Visual overlay of 6 styled boxes
          IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                String char = "";
                if (_otpController.text.length > index) {
                  char = _otpController.text[index];
                }

                // Highlight box if focused and active
                bool isFocused = _otpFocusNode.hasFocus &&
                    (_otpController.text.length == index ||
                     (_otpController.text.length == 6 && index == 5));

                return SizedBox(
                  width: 46,
                  height: 52,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isFocused ? primaryBrown : Colors.grey.shade400,
                        width: isFocused ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      char,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBrown,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Tidak menerima kode? ',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        _canResend
            ? GestureDetector(
                onTap: _resendOtp,
                child: const Text(
                  'Kirim Ulang',
                  style: TextStyle(
                    color: primaryBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              )
            : Text(
                'Kirim Ulang (${_countdown}s)',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
      ],
    );
  }

  Widget _buildButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitOtp,
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
          _isSubmitting ? 'Memverifikasi...' : 'Verifikasi OTP',
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
