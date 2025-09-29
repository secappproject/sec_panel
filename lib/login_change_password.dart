import 'package:flutter/material.dart';
import 'package:secpanel/helpers/db_helper.dart';
import 'package:secpanel/login.dart';
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

  // [PERUBAHAN] Widget build() diubah total untuk meniru struktur LoginPage
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Lapisan 1: Video background, akan tertutup warna putih di mobile
          const VideoBackground(),

          // Lapisan 2: Konten form
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 768) {
                  return _buildWebAppLayout();
                }
                return _buildMobileLayout();
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // [PERUBAHAN] Layout Web diubah agar sama persis dengan LoginPage
  Widget _buildWebAppLayout() {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height, 
      ),
      alignment: Alignment.centerLeft,
      width: 400,
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
          _buildChangePasswordForm(),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  // [PERUBAHAN] Layout Mobile diubah untuk bekerja di dalam Stack
  Widget _buildMobileLayout() {
    return Container(
      color: Colors.white, // Menutupi video background di layar kecil
      child: Column(
        children: [
          // AppBar kustom agar bisa ada di dalam body Stack
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildChangePasswordForm(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [PERUBAHAN] Form dibuat menjadi satu widget reusable
  Widget _buildChangePasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset('assets/images/logo.jpeg', height: 120),
        const SizedBox(height: 24),
        const Text(
          'Ubah Password Anda',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w400,
            fontSize: 24,
            color: AppColors.black,
          ),
        ),
        const Text(
          'Gunakan password lama untuk mengganti ke password baru.',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w300,
            fontSize: 14,
            color: AppColors.gray,
          ),
        ),
        const SizedBox(height: 40),
        _buildUsernameField(),
        const SizedBox(height: 16),
        _buildCurrentPasswordField(),
        const SizedBox(height: 16),
        _buildNewPasswordField(),
      ],
    );
  }

  // [PERUBAHAN] Tombol dibuat lebih konsisten, mirip _buildActionButtons di LoginPage
  Widget _buildActionButtons() {
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
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shadowColor: Colors.transparent,
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.schneiderGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.schneiderGreen.withOpacity(0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                    'Simpan',
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

  // Sisa kode di bawah ini (fields, snackbars) tidak ada perubahan signifikan
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
          (context, fieldTextEditingController, fieldFocusNode, onFieldSubmitted) {
        if (_usernameController.text != fieldTextEditingController.text) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _usernameController.text = fieldTextEditingController.text;
          });
        }
        
        return TextField(
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w300,
            fontSize: 14,
            color: Colors.black, // warna teks yg diketik
          ),
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          decoration: _buildInputDecoration('Username'),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final field = context.findRenderObject() as RenderBox;
        final size = field.size;
        return Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: size.width,
            margin: const EdgeInsets.only(top: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grayNeutral.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
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
      style: const TextStyle(
        fontFamily: 'Lexend',
        fontWeight: FontWeight.w300,
        fontSize: 14,
        color: Colors.black, // warna teks yg diketik
      ),
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
      style: const TextStyle(
        fontFamily: 'Lexend',
        fontWeight: FontWeight.w300,
        fontSize: 14,
        color: Colors.black, // warna teks yg diketik
      ),
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