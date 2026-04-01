import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _usernameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  final _confirmPasswordC = TextEditingController();
  final _adminPasswordC = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _usernameC.addListener(() => setState(() {}));
    _emailC.addListener(() => setState(() {}));
    _passwordC.addListener(() => setState(() {}));
    _confirmPasswordC.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _usernameC.dispose();
    _emailC.dispose();
    _passwordC.dispose();
    _confirmPasswordC.dispose();
    _adminPasswordC.dispose();
    super.dispose();
  }

  bool get _isFormFilled {
    return _usernameC.text.trim().isNotEmpty &&
        _emailC.text.trim().isNotEmpty &&
        _passwordC.text.trim().isNotEmpty &&
        _confirmPasswordC.text.trim().isNotEmpty;
  }

  void _saveMember() async {
    final username = _usernameC.text.trim();
    final email = _emailC.text.trim();
    final password = _passwordC.text.trim();
    final confirmPassword = _confirmPasswordC.text.trim();

    // Validasi tambahan
    if (!_isFormFilled) return;

    if (password != confirmPassword) {
      _showSnackBar('Konfirmasi password tidak cocok', isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Password minimal 6 karakter', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // Pastikan admin masih login
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      _showSnackBar(
        'Sesi login terputus. Silakan logout dan login ulang.',
        isError: true,
      );
      return;
    }

    final adminUid = currentUser.uid;

    try {
      // Gunakan instance Firebase terpisah agar tidak melogout admin
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TempAuthApp',
        options: Firebase.app().options,
      );

      final staffCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final staffUid = staffCredential.user!.uid;

      // Hapus app sekunder
      await tempApp.delete();

      final firestore = FirebaseFirestore.instance;

      // Staff di members/ subcollection admin (menggunakan default app yang aktif)
      await firestore
          .collection('users')
          .doc(adminUid)
          .collection('members')
          .doc(staffUid)
          .set({
        'username': username,
        'email': email,
        'role': 'staff',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Mapping supaya staff tahu nyambung ke toko mana
      await firestore.collection('userShopMapping').doc(staffUid).set({
        'shopOwnerId': adminUid,
        'role': 'staff',
      });

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('$username berhasil ditambahkan');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (e.code == 'email-already-in-use') {
        _showSnackBar('Email sudah terdaftar. Gunakan email lain.', isError: true);
        return;
      }

      String message = 'Gagal menambahkan anggota';
      if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah';
      }
      _showSnackBar(message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Header =====
              _buildHeader(
                title: 'Tambah Anggota',
                subtitle: 'Daftarkan anggota baru ke tim',
              ),
              const SizedBox(height: 24),

              // ===== Form Card =====
              _buildFormCard(),
              const SizedBox(height: 32),

              // ===== Save Button =====
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue500,
                    disabledBackgroundColor: const Color(0xFFE5E7EB), // abu-abu muda saat disabled
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _isFormFilled ? 4 : 0,
                    shadowColor: blue500.withOpacity(0.3),
                  ),
                  onPressed: (_isLoading || !_isFormFilled) ? null : _saveMember,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_rounded,
                                color: _isFormFilled ? Colors.white : const Color(0xFF9CA3AF), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Simpan Anggota',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _isFormFilled ? Colors.white : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // Custom Header
  // =========================
  Widget _buildHeader({required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: mBold),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: sRegular.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // Form Card
  // =========================
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon + title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: blue100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  size: 22,
                  color: blue600,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data Anggota', style: smSemiBold),
                    const SizedBox(height: 4),
                    Text(
                      'Isi informasi akun anggota baru',
                      style: xsRegular.copyWith(color: gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: borderLight, height: 1),
          const SizedBox(height: 16),

          // ===== Username =====
          Text('Username', style: smBold),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameC,
            textCapitalization: TextCapitalization.words,
            style: sRegular.copyWith(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. Budi',
              hintStyle: sRegular.copyWith(color: textMuted),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(Icons.person_outline_rounded,
                    size: 20, color: gray400),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: bgInput,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderFocus, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ===== Email =====
          Text('Email', style: smBold),
          const SizedBox(height: 8),
          TextField(
            controller: _emailC,
            keyboardType: TextInputType.emailAddress,
            style: sRegular.copyWith(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. budi@mail.com',
              hintStyle: sRegular.copyWith(color: textMuted),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(Icons.email_outlined, size: 20, color: gray400),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: bgInput,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderFocus, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ===== Password =====
          Text('Password', style: smBold),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordC,
            obscureText: _obscurePassword,
            style: sRegular.copyWith(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Minimal 6 karakter',
              hintStyle: sRegular.copyWith(color: textMuted),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child:
                    Icon(Icons.lock_outline_rounded, size: 20, color: gray400),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: gray400,
                  ),
                ),
              ),
              filled: true,
              fillColor: bgInput,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderFocus, width: 1.2),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ===== Konfirmasi Password =====
          Text('Konfirmasi Password', style: smBold),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPasswordC,
            obscureText: _obscureConfirmPassword,
            style: sRegular.copyWith(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Masukkan ulang password',
              hintStyle: sRegular.copyWith(color: textMuted),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child:
                    Icon(Icons.lock_outline_rounded, size: 20, color: gray400),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: gray400,
                  ),
                ),
              ),
              filled: true,
              fillColor: bgInput,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderFocus, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ===== Info hint =====
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: blue50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: blue500),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Anggota akan login menggunakan email dan password ini. Pastikan informasi sudah benar.',
                    style: xsRegular.copyWith(color: blue600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
