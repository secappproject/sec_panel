import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:secpanel/components/issue/panel_issue_screen.dart';
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

  @override
  void initState() {
    super.initState();
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

  Future<void> _handleStartupChecks() async {
    const mobilePlatforms = [TargetPlatform.android, TargetPlatform.iOS];
    if (mobilePlatforms.contains(defaultTargetPlatform)) {
      await _requestNotificationPermission();
      await _requestBatteryOptimizationExemption();
    }
    if (kIsWeb) await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _isPageLoading = false;
      });
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
          _showSuccessSnackBar('Login berhasil! Mengalihkan...');
          final prefs = await SharedPreferences.getInstance();
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 768) {
              return _buildWebAppLayout();
            }
            return _buildMobileLayout();
          },
        ),
      ),
    );
  }

  Widget _buildWebAppLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildFormFields(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Image.asset(
            'assets/images/factory-background.png',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade200,
              child: const Center(child: Text('Gagal memuat gambar.')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: SingleChildScrollView(child: _buildFormFields())),
          _buildActionButtons(),
        ],
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
        const Text(
          'Login',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w400,
            fontSize: 24,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 40),
        _buildUsernameField(),
        const SizedBox(height: 16),
        _buildPasswordField(),
      ],
    );
  }

  /// [PERUBAHAN UTAMA] Widget yang hanya berisi tombol-tombol aksi.
  /// Diubah dari Column menjadi Row untuk posisi kanan-kiri.
  Widget _buildActionButtons() {
    final areButtonsDisabled = _isLoading || _isPageLoading;
    // Menggunakan Row untuk menata tombol secara horizontal
    return Row(
      children: [
        // Tombol "Masuk & Ubah Password" di sisi kiri
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              side: const BorderSide(color: AppColors.schneiderGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: areButtonsDisabled
                ? null
                : () => Navigator.pushNamed(context, '/login-change-password'),
            // : () => Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (context) => PanelIssuesScreen(
            //         panelNoPp: 'F05_NO PP', // Ambil dari data panel
            //         panelVendor: 'ABACUS', // Ambil dari data panel
            //         busbarVendor: 'Presisi', // Ambil dari data panel
            //       ),
            //     ),
            //   ),
            child: const Text(
              'Ubah Password', // Disingkat agar muat
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: AppColors.schneiderGreen,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12), // Jarak antar tombol
        // Tombol "Masuk" di sisi kanan
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 52), // Lebar diatur oleh Expanded
              shadowColor: Colors.transparent,
              backgroundColor: AppColors.schneiderGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.schneiderGreen.withOpacity(
                0.7,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
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

  // --- SKELETON LAYOUTS & WIDGET HELPERS (Tidak ada perubahan) ---

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
            // Skeleton untuk tombol yang bersebelahan
            Row(
              children: [
                Expanded(child: _buildSkeletonBox(height: 52)),
                const SizedBox(width: 12),
                Expanded(child: _buildSkeletonBox(height: 52)),
              ],
            ),
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
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return DatabaseHelper.instance.searchUsernames(textEditingValue.text);
      },
      onSelected: (String selection) {
        _usernameController.text = selection;
      },
      fieldViewBuilder:
          (
            context,
            fieldTextEditingController,
            fieldFocusNode,
            onFieldSubmitted,
          ) {
            if (_usernameController.text != fieldTextEditingController.text) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _usernameController.text = fieldTextEditingController.text;
              });
            }
            return TextField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              decoration: _inputDecoration('Username'),
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(option),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: _inputDecoration('Password').copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: AppColors.gray,
          ),
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
      fillColor: AppColors.white,
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
