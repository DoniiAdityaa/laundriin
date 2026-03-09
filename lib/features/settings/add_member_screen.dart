import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _adminPasswordC = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameC.dispose();
    _emailC.dispose();
    _passwordC.dispose();
    _adminPasswordC.dispose();
    super.dispose();
  }

  /// Tampilkan dialog minta password admin sebelum proses
  void _confirmAndSave() {
    final username = _usernameC.text.trim();
    final email = _emailC.text.trim();
    final password = _passwordC.text.trim();

    // Validasi
    if (username.isEmpty) {
      _showSnackBar('Username tidak boleh kosong', isError: true);
      return;
    }
    if (email.isEmpty) {
      _showSnackBar('Email tidak boleh kosong', isError: true);
      return;
    }
    if (password.isEmpty) {
      _showSnackBar('Password tidak boleh kosong', isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Password minimal 6 karakter', isError: true);
      return;
    }

    // Minta password admin untuk konfirmasi
    _adminPasswordC.clear();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Konfirmasi Password', style: smSemiBold),
              const SizedBox(height: 8),
              Text(
                'Masukkan password akun Anda untuk melanjutkan',
                style: xsRegular.copyWith(color: gray500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _adminPasswordC,
                obscureText: true,
                style: sRegular.copyWith(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Password Anda',
                  hintStyle: sRegular.copyWith(color: textMuted),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: sSemiBold.copyWith(
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue500,
                        elevation: 2,
                        shadowColor: blue500.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        if (_adminPasswordC.text.trim().isEmpty) return;
                        Navigator.pop(context);
                        _saveMember(_adminPasswordC.text.trim());
                      },
                      child: Text(
                        'Lanjutkan',
                        style: sSemiBold.copyWith(color: white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveMember(String adminPassword) async {
    final username = _usernameC.text.trim();
    final email = _emailC.text.trim();
    final password = _passwordC.text.trim();

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

    final adminEmail = currentUser.email!;
    final adminUid = currentUser.uid;

    // Helper: pastikan admin selalu login balik
    Future<void> ensureAdminLogin() async {
      if (FirebaseAuth.instance.currentUser?.uid != adminUid) {
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      }
    }

    try {
      // Bikin akun Firebase Auth baru untuk staff
      final staffCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final staffUid = staffCredential.user!.uid;

      final firestore = FirebaseFirestore.instance;

      // Staff di members/ subcollection admin
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

      // Login balik ke akun admin
      await ensureAdminLogin();

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('$username berhasil ditambahkan');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Re-aktivasi: login sebagai staff lama → tulis ulang doc
        try {
          await FirebaseAuth.instance.signOut();
          final staffCredential =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          final staffUid = staffCredential.user!.uid;

          final firestore = FirebaseFirestore.instance;
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

          await firestore.collection('userShopMapping').doc(staffUid).set({
            'shopOwnerId': adminUid,
            'role': 'staff',
          });

          await ensureAdminLogin();

          if (!mounted) return;
          setState(() => _isLoading = false);
          _showSnackBar('$username berhasil diaktifkan kembali');
          Navigator.pop(context);
          return;
        } catch (_) {
          // Gagal → pastikan admin login balik
          try {
            await ensureAdminLogin();
          } catch (_) {}

          if (!mounted) return;
          setState(() => _isLoading = false);
          _showSnackBar(
            'Email sudah terdaftar dan password tidak cocok. Gunakan email lain.',
            isError: true,
          );
          return;
        }
      }

      // Error lain → pastikan admin login balik
      try {
        await ensureAdminLogin();
      } catch (_) {}

      if (!mounted) return;
      setState(() => _isLoading = false);
      String message = 'Gagal menambahkan anggota';
      if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah';
      }
      _showSnackBar(message, isError: true);
    } catch (e) {
      // Error umum → pastikan admin login balik
      try {
        await ensureAdminLogin();
      } catch (_) {}

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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: blue500.withOpacity(0.3),
                  ),
                  onPressed: _isLoading ? null : _confirmAndSave,
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
                                color: white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Simpan Anggota',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
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
