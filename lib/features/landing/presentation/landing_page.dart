import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_routes.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1EDE6),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Menu Terbaik',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D2E0B),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildMenuGrid(context),
                    const SizedBox(height: 40),
                    _buildWhySection(context),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(color: const Color(0xFFE9E0D3)),
          Positioned(
            bottom: -2,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(375, 140),
              painter: HeaderCurvePainter(),
            ),
          ),
          Positioned(
            right: 0,
            bottom: -48,
            child: Image.asset(
              'assets/foto katalog/hidangan.png',
              height: 310,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 60, 30, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildSignInButton(context),
                ),
                const SizedBox(height: 35),
                const Text(
                  '100% Tasty',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D2D2D),
                    letterSpacing: -0.8,
                  ),
                ),
                const Text(
                  'Rasa Juara, Pesan Cuma Pakai Klik!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 45),
                Image.asset(
                  'assets/foto katalog/logobaru.png',
                  width: 270,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9E0D3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.login),
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Text(
              'SIGN IN',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 18,
      crossAxisSpacing: 18,
      childAspectRatio: 0.65,
      children: [
        _menuCard(
          'Gudeg Juara',
          'Manis-gurih autentik khas nusantara.',
          'assets/foto katalog/Gudeg.jpg',
        ),
        _menuCard(
          'Ayam Bakar',
          'Ayam ungkep bumbu tradisional.',
          'assets/foto katalog/ayam bakar.jpg',
        ),
        _menuCard(
          'Ayam Geprek',
          'Ayam crispy sambal ulek segar.',
          'assets/foto katalog/ayam geprek.jpg',
        ),
        _buildOthersCard(context),
      ],
    );
  }

  Widget _menuCard(String title, String sub, String imagePath) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.fastfood, color: Colors.grey, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF2D2D2D),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 9,
              height: 1.4,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 35,
            child: OutlinedButton(
              onPressed: () => {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2D2D2D), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Pesan',
                style: TextStyle(
                  color: Color(0xFF2D2D2D),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOthersCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFC06014),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Lainnya',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.menu),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Lihat menu →',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              children: [
                TextSpan(text: 'Mengapa '),
                TextSpan(
                  text: 'KedaiKlik',
                  style: TextStyle(color: Color(0xFFC06014)),
                ),
                TextSpan(text: '?'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nikmati kenyamanan memesan masakan tradisional favorit Anda dalam satu aplikasi.',
            style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.6),
          ),
          const SizedBox(height: 20),
          _whyItem(context, Icons.restaurant, 'Makan ditempat', AppRoutes.menu),
          const SizedBox(height: 12),
          _whyItem(context, Icons.store, 'Ambil ke resto', AppRoutes.menu),
        ],
      ),
    );
  }

  Widget _whyItem(
    BuildContext context,
    IconData icon,
    String text,
    String route,
  ) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EDE6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFC06014), size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF2D2D2D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintSecondary = Paint()..color = const Color(0xFFA0522D);
    final paintPrimary = Paint()..color = const Color(0xFF8B4513);

    final pathSecondary = Path();
    pathSecondary.moveTo(-size.width * 0.4, size.height * 1.1);
    pathSecondary.quadraticBezierTo(
      size.width * 0.5,
      -size.height * 0.6,
      size.width * 1.4,
      size.height * 1.1,
    );
    canvas.drawPath(pathSecondary, paintSecondary);

    final pathPrimary = Path();
    pathPrimary.moveTo(-size.width * 0.1, size.height);
    pathPrimary.quadraticBezierTo(
      size.width * 0.5,
      -size.height * 0.4,
      size.width * 1.2,
      size.height,
    );
    canvas.drawPath(pathPrimary, paintPrimary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
