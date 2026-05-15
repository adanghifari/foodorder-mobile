import 'package:flutter/material.dart';

enum AppNoticeType { info, success, error }

class AppNotice {
  static OverlayEntry? _topEntry;
  static bool _isConfirmShowing = false;

  static void show(
    BuildContext context,
    String message, {
    AppNoticeType type = AppNoticeType.info,
  }) {
    _topEntry?.remove();
    _topEntry = null;

    final textColor = switch (type) {
      AppNoticeType.success => const Color(0xFF1F7A3D),
      AppNoticeType.error => const Color(0xFFB3261E),
      AppNoticeType.info => const Color(0xFFB45309),
    };

    final title = switch (type) {
      AppNoticeType.success => 'BERHASIL',
      AppNoticeType.error => 'PERINGATAN',
      AppNoticeType.info => 'INFORMASI',
    };

    final overlay = Overlay.of(context, rootOverlay: true);
    final topInset = MediaQuery.of(context).padding.top + 28;

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 14,
        right: 14,
        top: topInset,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F2E7),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2A000000),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE8DF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '!',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFF2D3748),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    _topEntry = entry;
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (_topEntry == entry) {
        _topEntry?.remove();
        _topEntry = null;
      }
    });
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String message,
    String? bodyTitle,
    String confirmLabel = 'OK',
    AppNoticeType type = AppNoticeType.info,
  }) async {
    if (_isConfirmShowing) return false;
    _isConfirmShowing = true;

    final title = switch (type) {
      AppNoticeType.success => 'BERHASIL',
      AppNoticeType.error => 'GAGAL',
      AppNoticeType.info => 'INFORMASI',
    };

    final badgeColor = switch (type) {
      AppNoticeType.success => const Color(0xFFC8F0DF),
      AppNoticeType.error => const Color(0xFFF9D5D2),
      AppNoticeType.info => const Color(0xFFD1EFE3),
    };

    final accentColor = switch (type) {
      AppNoticeType.success => const Color(0xFF0F9D72),
      AppNoticeType.error => const Color(0xFFD64545),
      AppNoticeType.info => const Color(0xFF0F9D72),
    };

    final titleText = bodyTitle ??
        switch (type) {
          AppNoticeType.success => 'Aksi berhasil diproses',
          AppNoticeType.error => 'Terjadi kesalahan',
          AppNoticeType.info => 'Informasi untuk Anda',
        };

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 16,
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  titleText,
                  style: const TextStyle(
                    color: Color(0xFF1F2A44),
                    fontSize: 31,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF4A5568),
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(
                      confirmLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    _isConfirmShowing = false;
    return result == true;
  }
}
