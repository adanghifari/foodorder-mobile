import 'dart:async';

import 'package:flutter/material.dart';

enum AppNoticeType { info, success, error }

class AppNotice {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context,
    String message, {
    AppNoticeType type = AppNoticeType.info,
  }) {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final title = switch (type) {
      AppNoticeType.success => 'Notifikasi Berhasil',
      AppNoticeType.error => 'Notifikasi Error',
      AppNoticeType.info => 'Notifikasi Struk',
    };

    final textColor = switch (type) {
      AppNoticeType.success => const Color(0xFF1F7A3D),
      AppNoticeType.error => const Color(0xFFB3261E),
      AppNoticeType.info => const Color(0xFFB45309),
    };

    final overlay = Overlay.of(context, rootOverlay: true);
    final topInset = MediaQuery.of(context).padding.top + 12;
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 14,
        right: 14,
        top: topInset,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F2E7),
              borderRadius: BorderRadius.circular(26),
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
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE8DF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '!',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _dismissTimer?.cancel();
                    _currentEntry?.remove();
                    _currentEntry = null;
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  icon: Icon(Icons.close, color: textColor, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    _currentEntry = entry;
    _dismissTimer = Timer(const Duration(seconds: 2), () {
      _currentEntry?.remove();
      _currentEntry = null;
    });
  }
}
