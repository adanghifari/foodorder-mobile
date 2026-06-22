import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/app_routes.dart';
import '../../landing/data/order_type_session.dart';
import '../data/table_session.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, this.redirectToCart = false});

  final bool redirectToCart;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  _ScanPayload? _extractPayload(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return null;

    if (RegExp(r'^take[_\-\s]?away$', caseSensitive: false).hasMatch(raw)) {
      return const _ScanPayload.takeAway();
    }

    if (RegExp(r'^\d{1,3}$').hasMatch(raw)) {
      return _ScanPayload.dineIn(int.parse(raw));
    }

    try {
      final uri = Uri.parse(raw);
      final mode = (uri.queryParameters['mode'] ?? '').toLowerCase();
      final tableIdParam = (uri.queryParameters['tableId'] ?? '').toLowerCase();
      if (mode == 'take_away' || tableIdParam == 'take_away') {
        return const _ScanPayload.takeAway();
      }

      final fromParam = uri.queryParameters['tableId'];
      if (fromParam != null && RegExp(r'^\d{1,3}$').hasMatch(fromParam)) {
        return _ScanPayload.dineIn(int.parse(fromParam));
      }

      final path = uri.path.toLowerCase();
      if (path.endsWith('/menu/take_away')) {
        return const _ScanPayload.takeAway();
      }

      final matchMenuPath = RegExp(r'/menu/(\d{1,3})$').firstMatch(path);
      if (matchMenuPath != null) {
        return _ScanPayload.dineIn(int.parse(matchMenuPath.group(1)!));
      }
    } catch (_) {
      final matchPlain = RegExp(
        r'(?:tableId=|/menu/)(\d{1,3})',
        caseSensitive: false,
      ).firstMatch(raw);
      if (matchPlain != null) {
        return _ScanPayload.dineIn(int.parse(matchPlain.group(1)!));
      }
    }

    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final code = capture.barcodes.isNotEmpty
        ? (capture.barcodes.first.rawValue?.trim() ?? '')
        : '';
    if (code.isEmpty) return;
    final payload = _extractPayload(code);
    if (payload == null) {
      return;
    }

    _handled = true;
    if (payload.isTakeAway) {
      await OrderTypeSession.set(OrderType.takeAway);
      await TableSession.clear();
    } else {
      await OrderTypeSession.set(OrderType.onSpotDineIn);
      await TableSession.set(payload.tableId!);
    }

    if (!mounted) return;
    final targetRoute = widget.redirectToCart ? AppRoutes.cart : AppRoutes.menu;
    Navigator.pushNamed(context, targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Pindai QR'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Text(
              'Arahkan kamera ke kode QR',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanPayload {
  const _ScanPayload._({required this.isTakeAway, this.tableId});

  const _ScanPayload.takeAway() : this._(isTakeAway: true);

  const _ScanPayload.dineIn(int tableId)
    : this._(isTakeAway: false, tableId: tableId);

  final bool isTakeAway;
  final int? tableId;
}
