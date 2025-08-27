import 'package:flutter/material.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/models/company.dart';
import 'package:secpanel/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginChangePasswordPage extends StatefulWidget {
  const LoginChangePasswordPage({super.key});

  @override
  State<LoginChangePasswordPage> createState() =>
      _LoginChangePasswordPageState();
}

class _LoginChangePasswordPageState extends State<LoginChangePasswordPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loginAndChangePassword() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      final newPassword = _newPasswordController.text.trim();

      if (username.isEmpty || password.isEmpty || newPassword.isEmpty) {
        _showErrorSnackBar('Semua kolom tidak boleh kosong.');
        setState(() => _isLoading = false);
        return;
      }
      if (newPassword == password) {
        _showErrorSnackBar(
          'Password baru tidak boleh sama dengan password saat ini.',
        );
        setState(() => _isLoading = false);
        return;
      }

      final Company? company = await DatabaseHelper.instance.login(
        username,
        password,
      );

      if (mounted) {
        if (company != null) {
          final updated = await DatabaseHelper.instance.updatePassword(
            username,
            newPassword,
          );
          if (updated) {
            _showSuccessSnackBar('Password berhasil diubah!');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('loggedInUsername', username);
            await prefs.setString('companyId', company.id);
            await prefs.setString('companyRole', company.role.name);
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            _showErrorSnackBar('Gagal mengubah password.');
            setState(() => _isLoading = false);
          }
        } else {
          _showErrorSnackBar('Username atau password saat ini salah.');
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
    final bool isMobileView = MediaQuery.of(context).size.width <= 768;

    return Scaffold(
      backgroundColor: Colors.white,
      // [PERBAIKAN 1] AppBar dengan judul yang benar untuk mobile
      appBar: isMobileView
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              title: const Text(
                'Masuk & Ubah Password',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
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

  // Layout untuk tampilan Web (layar lebar)
  Widget _buildWebAppLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildChangePasswordForm(isWeb: true),
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

  // Layout untuk tampilan Mobile (layar sempit)
  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/images/logo.jpeg', height: 44),
              const SizedBox(height: 24),
              // [PERBAIKAN 1] Judul besar untuk tampilan web
              Container(
                width: MediaQuery.of(context).size.width,
                child: const Text(
                  'Masuk & Ubah Password',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w400,
                    fontSize: 32,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: _buildChangePasswordForm(isWeb: false),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  // Widget yang berisi field-field form
  Widget _buildChangePasswordForm({required bool isWeb}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isWeb) ...[
          TextButton.icon(
            icon: const Icon(Icons.arrow_back, color: AppColors.schneiderGreen),
            label: const Text(
              'Kembali ke Login',
              style: TextStyle(
                color: AppColors.schneiderGreen,
                fontFamily: 'Lexend',
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: 24),
          Image.asset('assets/images/logo.jpeg', height: 44),
          const SizedBox(height: 24),
          // [PERBAIKAN 1] Judul besar untuk tampilan web
          const Text(
            'Lupa Password',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w400,
              fontSize: 32,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 40),
        ],
        if (!isWeb) const SizedBox(height: 24),
        _buildUsernameField(),
        const SizedBox(height: 16),
        _buildCurrentPasswordField(),
        const SizedBox(height: 16),
        _buildNewPasswordField(),
      ],
    );
  }

  // [PERBAIKAN 2] Widget tombol sekarang menggunakan Row
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              side: const BorderSide(color: AppColors.schneiderGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text(
              'Batal',
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
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.schneiderGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.schneiderGreen.withOpacity(
                0.7,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: _isLoading ? null : _loginAndChangePassword,
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
                    'Simpan & Masuk',
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

  // Sisa kode di bawah ini tidak ada perubahan
  Widget _buildUsernameField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return DatabaseHelper.instance.searchUsernames(textEditingValue.text);
      },
      onSelected: (String selection) => _usernameController.text = selection,
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
              decoration: _buildInputDecoration('Username'),
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

  Widget _buildCurrentPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: _buildInputDecoration(
        'Password Saat Ini',
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

  Widget _buildNewPasswordField() {
    return TextField(
      controller: _newPasswordController,
      obscureText: !_isNewPasswordVisible,
      decoration: _buildInputDecoration(
        'Password Baru',
        suffixIcon: IconButton(
          icon: Icon(
            _isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: AppColors.gray,
          ),
          onPressed: () =>
              setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String labelText, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
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
      suffixIcon: suffixIcon,
    );
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
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
