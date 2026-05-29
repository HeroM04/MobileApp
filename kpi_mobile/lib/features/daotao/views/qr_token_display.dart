import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Widget hiển thị mã QR xoay mỗi 10 giây — đồng bộ với Web Admin.
/// Thuật toán sinh token: (floor(epochMs / 10000) * 31337) % 999999
/// Giống hệt hàm generateQRToken() trong ManageTraining.jsx của Web Admin.
class QrTokenDisplay extends StatefulWidget {
  final String roomCode;
  final String roomTitle;

  const QrTokenDisplay({
    super.key,
    required this.roomCode,
    required this.roomTitle,
  });

  @override
  State<QrTokenDisplay> createState() => _QrTokenDisplayState();
}

class _QrTokenDisplayState extends State<QrTokenDisplay> {
  late String _currentToken;
  late int _secondsLeft;
  Timer? _timer;

  /// Sinh token theo đúng công thức của Web Admin:
  /// const now = Math.floor(Date.now() / 10000);
  /// return (now * 31337 % 999999).toString().padStart(6, '0');
  String _generateToken() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 10000;
    final token = (now * 31337) % 999999;
    return token.toString().padLeft(6, '0');
  }

  /// Tính số giây còn lại trong window 10s hiện tại
  int _calcSecondsLeft() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final elapsed = (ms % 10000) ~/ 1000; // số giây đã trôi qua trong window này
    return 10 - elapsed;
  }

  @override
  void initState() {
    super.initState();
    _currentToken = _generateToken();
    _secondsLeft = _calcSecondsLeft();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final newToken = _generateToken();
      final newLeft = _calcSecondsLeft();
      setState(() {
        _currentToken = newToken;
        _secondsLeft = newLeft;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// QR data = "roomCode:token" để backend có thể verify cả phòng + token
  String get _qrData => '${widget.roomCode}:$_currentToken';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.roomTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2C59),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Chiếu mã QR để học viên quét điểm danh",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        // QR Code
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: QrImageView(
            data: _qrData,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF0F2C59),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF0F2C59),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Token display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2C59).withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "TOKEN: $_currentToken",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: Color(0xFF0F2C59),
              fontFamily: 'Courier',
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Countdown bar
        _CountdownBar(secondsLeft: _secondsLeft),
        const SizedBox(height: 4),
        Text(
          "Mã QR thay đổi sau ${_secondsLeft}s",
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.info_outline, size: 12, color: Colors.green),
            SizedBox(width: 4),
            Text(
              "Học viên quét để điểm danh (+5 KPI)",
              style: TextStyle(fontSize: 11, color: Colors.green),
            ),
          ],
        ),
      ],
    );
  }
}

class _CountdownBar extends StatelessWidget {
  final int secondsLeft;
  const _CountdownBar({required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    final fraction = secondsLeft / 10.0;
    final color = secondsLeft <= 3 ? Colors.red : const Color(0xFF10B981);
    return SizedBox(
      width: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: 6,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
