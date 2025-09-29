import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:secpanel/login_change_password.dart';
import 'package:secpanel/login_custom_page_route.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/company.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPageLoading = true;
  bool _isPasswordVisible = false;
  bool _showForm = false; // 👈 tambahan untuk kontrol kapan form muncul

  @override
  void initState() {
    super.initState();
    _usernameController.clear();
    _passwordController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleStartupChecks();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

// GANTI FUNGSI INI
  Future<void> _handleStartupChecks() async {
    const mobilePlatforms = [TargetPlatform.android, TargetPlatform.iOS];
    if (mobilePlatforms.contains(defaultTargetPlatform)) {
      await _requestNotificationPermission();
      await _requestBatteryOptimizationExemption();
    }

    // Delay ini bisa dipertahankan untuk memberikan efek loading di web
    if (kIsWeb) await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      // Hilangkan skeleton dan langsung tampilkan form di mobile
      setState(() {
        _isPageLoading = false;
        if (!kIsWeb) { // Jika bukan web (artinya mobile)
          _showForm = true; // Langsung tampilkan form
        }
      });

      // Untuk web, tetap berikan delay agar ada efek animasi fade-in
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          setState(() {
            _showForm = true;
          });
        }
      }
    }
  }

  Future<void> _login() async {
    if (_isLoading || _isPageLoading) return;
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      if (username.isEmpty || password.isEmpty) {
        _showErrorSnackBar('Username dan password tidak boleh kosong.');
        setState(() => _isLoading = false);
        return;
      }

      final Company? company = await DatabaseHelper.instance.login(
        username,
        password,
      );

      if (mounted) {
        if (company != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('loggedInUsername', username);
          await prefs.setString('companyId', company.id);
          await prefs.setString('companyRole', company.role.name);
          
          // ▼▼▼ PENAMBAHAN LOGIKA PUSH NOTIFICATION DI SINI ▼▼▼
          try {
            String? token = await FirebaseMessaging.instance.getToken();
            if (token != null) {
              await DatabaseHelper.instance.registerDeviceToken(
                username: username,
                token: token,
              );
            }
          } catch (e) {
            // Abaikan error jika token gagal didapat/dikirim agar tidak
            // mengganggu proses login utama. Cukup print di console.
            print('Error saat mendaftarkan token perangkat: $e');
          }
          _showSuccessSnackBar('Login berhasil! Mengalihkan...');
          await prefs.setString('loggedInUsername', username);
          await prefs.setString('companyId', company.id);
          await prefs.setString('companyRole', company.role.name);
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          _showErrorSnackBar('Username atau password salah.');
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Terjadi kesalahan: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPageLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 768) {
                return _buildWebAppSkeletonLayout();
              }
              return _buildLoginSkeleton();
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.centerLeft,
        children: [
          const VideoBackground(),
          AnimatedOpacity(
            opacity: _showForm ? 1.0 : 0.0, // 👈 fade in
            duration: const Duration(milliseconds: 800),
            child: _showForm
                ? SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 768) {
                          return _buildWebAppLayout();
                        }
                        return _buildMobileLayout();
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
Widget _buildWebAppLayout() {
  // Ganti Center dengan Align
  return SingleChildScrollView(
    child: Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height, 
      ),
      width: 400,
      alignment: Alignment.centerLeft, 
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFormFields(),
          const SizedBox(height: 32),
          _buildActionButtons(isWebLayout: true),
        ],
      ),
    ),
  );
}
  Widget _buildMobileLayout() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: SingleChildScrollView(child: _buildFormFields())),
            _buildActionButtons(isWebLayout: false),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 50),
        Image.asset('assets/images/logo.jpeg', height: 120),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Masuk dengan Akun Anda',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w400,
                fontSize: 24,
                color: AppColors.black,
              ),
            ),
            Text(
              'Hubungi admin jika ada kendala akun.',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w300,
                fontSize: 14,
                color: AppColors.gray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        _buildUsernameField(),
        const SizedBox(height: 16),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildActionButtons({bool isWebLayout = false}) {
    final areButtonsDisabled = _isLoading || _isPageLoading;

    if (isWebLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shadowColor: Colors.transparent,
              backgroundColor: AppColors.schneiderGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.schneiderGreen.withOpacity(0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: areButtonsDisabled ? null : _login,
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Text(
                    'Masuk',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: areButtonsDisabled
                ? null
                : () => Navigator.of(context).push(
                      FadeThroughPageRoute(page: const LoginChangePasswordPage()),
                    ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Pertama Kali Masuk Akun? ',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w300,
                    fontSize: 12,
                    color: AppColors.gray,
                  ),
                ),
                Text(
                  ' Ganti Password',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: AppColors.schneiderGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              side: const BorderSide(color: AppColors.schneiderGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: areButtonsDisabled
                ? null
                : () => Navigator.of(context).push(
                      FadeThroughPageRoute(page: const LoginChangePasswordPage()),
                    ),
            child: const Text(
              'Ubah Password',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: AppColors.schneiderGreen,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 52),
              shadowColor: Colors.transparent,
              backgroundColor: AppColors.schneiderGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.schneiderGreen.withOpacity(0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: areButtonsDisabled ? null : _login,
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Text(
                    'Masuk',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebAppSkeletonLayout() {
    return Row(
      children: [
        Expanded(flex: 1, child: _buildLoginSkeleton()),
        Expanded(
          flex: 1,
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            _buildSkeletonBox(height: 44, width: 120),
            const SizedBox(height: 24),
            _buildSkeletonBox(height: 32, width: 200),
            const SizedBox(height: 40),
            _buildSkeletonBox(height: 52),
            const SizedBox(height: 16),
            _buildSkeletonBox(height: 52),
            const SizedBox(height: 32),
            _buildSkeletonBox(height: 52),
            const SizedBox(height: 16),
            _buildSkeletonBox(height: 20, width: 250),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBox({required double height, double? width}) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextField(
      style: const TextStyle(
        fontFamily: 'Lexend',
        fontWeight: FontWeight.w300,
        fontSize: 14,
        color: Colors.black, // warna teks yg diketik
      ),
      controller: _usernameController,
      decoration: _inputDecoration('Username'),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      style: const TextStyle(
        fontFamily: 'Lexend',
        fontWeight: FontWeight.w300,
        fontSize: 14,
        color: Colors.black, // warna teks yg diketik
      ),
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: _inputDecoration('Password').copyWith(
        suffixIcon: 
        IconButton(
          // icon: Icon(
          //   _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          //   color: AppColors.gray,
          // ),
          icon: _isPasswordVisible ? Image.asset("assets/images/eye-open.png", height: 24,) : Image.asset("assets/images/eye-close.png", height: 24,),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'Lexend',
        fontWeight: FontWeight.w300,
        fontSize: 12,
        color: Colors.black87,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.schneiderGreen, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.grayNeutral, width: 1),
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      _showSettingsDialog(
        title: 'Izin Notifikasi Dibutuhkan',
        content:
            'Aplikasi ini butuh izin notifikasi untuk update penting. Silakan aktifkan di pengaturan aplikasi.',
      );
    }
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      if ((await Permission.ignoreBatteryOptimizations.status).isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 12),
        ),
        backgroundColor: const Color.fromARGB(255, 39, 40, 39),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showSettingsDialog({
    required String title,
    required String content,
  }) async {
    if (mounted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Buka Pengaturan'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }
}
class VideoBackground extends StatefulWidget {
  const VideoBackground({super.key});

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  // Timer untuk animasi teks slogan
  Timer? _textAnimationTimer;
  int _currentTextIndex = 0;
  double _textOpacity = 0.0;
  final List<String> _sloganTexts = [
    'Trisutorpro',
    'Lacak panel yang perlu diselesaikan segera',
    'Pastikan pengiriman panel tepat waktu.',
    'Catat dan selesaikan setiap kendala dengan mudah.',
  ];

  // ===== PERUBAHAN DIMULAI DI SINI =====

  // Timer untuk animasi background slide
  Timer? _imageSliderTimer;
  int _currentImageIndex = 0;
  final int _totalImages = 12; // Jumlah total gambar background

  @override
  void initState() {
    super.initState();
    _startTextAnimation();
    _startImageSlider(); // Memulai slideshow background
  }

  void _startImageSlider() {
    // Timer periodik untuk mengganti gambar setiap 5 detik
    _imageSliderTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          // Ganti ke gambar berikutnya, kembali ke 0 jika sudah di akhir
          _currentImageIndex = (_currentImageIndex + 1) % _totalImages;
        });
      }
    });
  }
  
  // ===== AKHIR DARI PERUBAHAN LOGIKA =====


  void _startTextAnimation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _textOpacity = 1.0);
    });

    _textAnimationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() => _textOpacity = 0.0);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _currentTextIndex = (_currentTextIndex + 1) % _sloganTexts.length;
              _textOpacity = 1.0;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _textAnimationTimer?.cancel();
    _imageSliderTimer?.cancel(); // Pastikan timer gambar juga dihentikan
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.centerRight,
      children: [
        // ===== PERUBAHAN PADA TAMPILAN =====
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 1500), // Durasi fade
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Image.asset(
            // Menggunakan path dinamis sesuai indeks gambar saat ini
            'assets/images/bg-${_currentImageIndex + 1}.png',
            // Key penting agar AnimatedSwitcher mendeteksi perubahan widget
            key: ValueKey<int>(_currentImageIndex),
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
            alignment: Alignment.center,
          ),
        ),
        // ===== AKHIR DARI PERUBAHAN TAMPILAN =====
        
        Container(
          color: AppColors.schneiderGreen.withOpacity(0.3),
        ),
        Positioned(
          bottom: 40,
          left: 440,
          right: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedOpacity(
                opacity: _textOpacity,
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _sloganTexts[_currentTextIndex],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black54,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: _sloganTexts.asMap().entries.map((entry) {
                  int index = entry.key;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: index == _currentTextIndex ? 30.0 : 10.0,
                    height: 5.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      color: index == _currentTextIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}