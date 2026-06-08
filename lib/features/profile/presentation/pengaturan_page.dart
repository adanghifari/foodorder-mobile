import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../auth/data/auth_session.dart';
import '../../landing/data/order_type_session.dart';
import '../../scan/data/table_session.dart';
import 'informasi_akun_page.dart';
import 'ganti_password_page.dart';

class PengaturanPage extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  const PengaturanPage({super.key, this.onProfileUpdated});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  bool _isNotificationOn = true; // Status awal untuk switch notifikasi

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Latar belakang putih #FFFFFF
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBackButton(
          color: Colors.black,
          size: 20,
        ),
        title: const Text(
          "Pengaturan",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // List Menu Pengaturan
          _buildMenuSetting("Informasi akun", isSwitch: false),
          _buildMenuSetting("Ganti Password", isSwitch: false),

          // Menu Notifikasi dengan Switch Oranye
          _buildMenuSetting(
            "Notifikasi",
            isSwitch: true,
            switchValue: _isNotificationOn,
            onSwitchChanged: (value) {
              setState(() {
                _isNotificationOn = value;
              });
            },
          ),

          const SizedBox(height: 40),

          // Tombol Keluar
          TextButton(
            onPressed: () async {
              await AuthSession.clear();
              await OrderTypeSession.clear();
              await TableSession.clear();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
            child: const Text(
              "Keluar",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Helper untuk Baris Pengaturan
  Widget _buildMenuSetting(
    String title, {
    required bool isSwitch,
    bool? switchValue,
    Function(bool)? onSwitchChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        trailing: isSwitch
            ? Switch(
                value: switchValue ?? false,
                onChanged: onSwitchChanged,
                activeColor: const Color(0xFFC6620C), // Warna oranye #C6620C
                activeTrackColor: const Color(0xFFC6620C).withOpacity(0.3),
              )
            : const Icon(
                Icons.arrow_forward_ios,
                color: Colors.black,
                size: 18,
              ),
        onTap: isSwitch
            ? null
            : () async {
                if (title == "Informasi akun") {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InformasiAkunPage(
                        onProfileUpdated: widget.onProfileUpdated,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    Navigator.pop(context, true);
                  }
                } else if (title == "Ganti Password") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GantiPasswordPage(),
                    ),
                  );
                }
              },
      ),
    );
  }
}
