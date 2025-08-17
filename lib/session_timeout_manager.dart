// lib/session_timeout_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionTimeoutManager extends StatefulWidget {
  final Widget child;
  final Duration timeoutDuration;
  // Kunci Global untuk mengakses Navigator dari mana saja
  final GlobalKey<NavigatorState> navigatorKey;

  const SessionTimeoutManager({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.timeoutDuration = const Duration(minutes: 15),
  });

  @override
  State<SessionTimeoutManager> createState() => _SessionTimeoutManagerState();
}

class _SessionTimeoutManagerState extends State<SessionTimeoutManager> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Memulai timer baru. Jika selesai, panggil _logout.
  void _startTimer() {
    _timer = Timer(widget.timeoutDuration, _logout);
  }

  /// Me-reset timer. Dipanggil setiap kali ada interaksi pengguna.
  void _resetTimer() {
    _timer?.cancel(); // Batalkan timer yang sedang berjalan
    _startTimer(); // Mulai timer baru
  }

  /// Fungsi untuk melakukan logout
  Future<void> _logout() async {
    // 1. Hapus data sesi/login dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('companyId');
    await prefs.remove('loggedInUsername');
    // Anda bisa menambahkan key lain yang perlu dihapus

    // 2. Arahkan ke halaman login dan hapus semua halaman sebelumnya
    // Gunakan navigatorKey agar bisa navigasi tanpa BuildContext
    final navigator = widget.navigatorKey.currentState;
    if (navigator != null && navigator.mounted) {
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);

      // 3. Tampilkan pesan bahwa sesi telah berakhir
      ScaffoldMessenger.of(navigator.context).showSnackBar(
        const SnackBar(
          content: Text("Sesi Anda telah berakhir karena tidak ada aktivitas."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listener akan mendeteksi semua interaksi pointer (tap, drag, dll)
    // di dalam widget `child`-nya (yaitu seluruh aplikasi Anda).
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerUp: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
