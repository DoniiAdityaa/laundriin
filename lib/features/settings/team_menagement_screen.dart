import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundriin/config/shop_config.dart';
import 'package:laundriin/features/settings/add_member_screen.dart';
import 'package:laundriin/features/settings/edit_member_screen.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';

class TeamMenagementScreen extends StatefulWidget {
  const TeamMenagementScreen({super.key});

  @override
  State<TeamMenagementScreen> createState() => _TeamMenagementScreenState();
}

class _TeamMenagementScreenState extends State<TeamMenagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final String _adminEmail = FirebaseAuth.instance.currentUser?.email ?? '';
  final TextEditingController _usernameC = TextEditingController();

  String _adminUsername = '';
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  @override
  void dispose() {
    _usernameC.dispose();
    super.dispose();
  }

  /// Load data admin username + staff dari Firestore
  Future<void> _loadTeamData() async {
    try {
      final userDoc = await _firestore.collection('users').doc(_userId).get();

      // Admin username: ambil dari users/{uid}/username
      // Kalau belum ada, pakai ownerName sebagai default dan simpan
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        if (data['username'] != null &&
            data['username'].toString().isNotEmpty) {
          _adminUsername = data['username'];
        } else {
          _adminUsername = ShopSettings.ownerName;
          // Auto-save username pertama kali
          await _firestore.collection('users').doc(_userId).set(
            {'username': _adminUsername},
            SetOptions(merge: true),
          );
        }
      } else {
        _adminUsername = ShopSettings.ownerName;
      }

      // Load staff dari members/ subcollection
      final staffSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('members')
          .where('role', isEqualTo: 'staff')
          .get();

      final staffList = staffSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'username': data['username'] ?? '',
          'email': data['email'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _members = staffList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[ERROR] Load team data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                title: 'Kelola Tim',
                subtitle: 'Kelola anggota tim toko Anda',
              ),
              const SizedBox(height: 24),

              // ===== Loading atau Content =====
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // ===== Card Akun Saya =====
                _buildMyAccountCard(),
                const SizedBox(height: 16),

                // ===== Card Anggota Tim =====
                _buildTeamMembersCard(),
                const SizedBox(height: 24),

                // ===== Tombol Tambah Anggota =====
                _buildAddMemberButton(),
              ],
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
  // Card: Akun Saya (Admin)
  // =========================
  Widget _buildMyAccountCard() {
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
                  Icons.person_rounded,
                  size: 22,
                  color: blue600,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Akun Saya', style: smSemiBold),
                    const SizedBox(height: 4),
                    Text(
                      'Informasi akun Anda',
                      style: xsRegular.copyWith(color: gray500),
                    ),
                  ],
                ),
              ),
              // Badge Admin
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: blue50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Admin',
                  style: xsSemiBold.copyWith(color: blue600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: borderLight, height: 1),
          const SizedBox(height: 16),

          // Username row (editable)
          _buildInfoRow(
            label: 'Username',
            value: _adminUsername,
            trailing: InkWell(
              onTap: _showEditUsernameDialog,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset(
                  'assets/svg/mingcute_pencil-line.svg',
                  width: 16,
                  height: 16,
                  color: blue500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Email row (read-only)
          _buildInfoRow(
            label: 'Email',
            value: _adminEmail,
          ),
        ],
      ),
    );
  }

  // =========================
  // Info Row (label + value)
  // =========================
  Widget _buildInfoRow({
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: xsRegular.copyWith(color: gray500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: sSemiBold.copyWith(color: textPrimary),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  // =========================
  // Dialog Edit Username
  // =========================
  void _showEditUsernameDialog() {
    _usernameC.text = _adminUsername;

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
              Text('Edit Username', style: smSemiBold),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameC,
                textCapitalization: TextCapitalization.words,
                style: sRegular.copyWith(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Masukkan username',
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
                      onPressed: () async {
                        final newName = _usernameC.text.trim();
                        if (newName.isNotEmpty) {
                          // Simpan ke Firestore users/{uid}/username
                          await _firestore.collection('users').doc(_userId).set(
                            {'username': newName},
                            SetOptions(merge: true),
                          );

                          setState(() {
                            _adminUsername = newName;
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        'Simpan',
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

  // =========================
  // Card: Anggota Tim
  // =========================
  Widget _buildTeamMembersCard() {
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
          // Header row
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
                  Icons.people_rounded,
                  size: 22,
                  color: blue600,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Anggota Tim', style: smSemiBold),
                    const SizedBox(height: 4),
                    Text(
                      'Daftar staf yang terdaftar',
                      style: xsRegular.copyWith(color: gray500),
                    ),
                  ],
                ),
              ),
              // Jumlah anggota
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_members.length} orang',
                  style: xsSemiBold.copyWith(color: gray500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: borderLight, height: 1),
          const SizedBox(height: 12),

          // List anggota atau empty state
          if (_members.isEmpty)
            _buildEmptyState()
          else
            ..._members.asMap().entries.map((entry) {
              final index = entry.key;
              final member = entry.value;
              return Column(
                children: [
                  _buildMemberTile(
                    username: member['username'] ?? '',
                    email: member['email'] ?? '',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditMemberScreen(
                            memberUid: member['uid'] ?? '',
                            username: member['username'] ?? '',
                            email: member['email'] ?? '',
                          ),
                        ),
                      );
                      if (result == true) _loadTeamData();
                    },
                    onDelete: () => _showDeleteMemberDialog(index),
                  ),
                  if (index < _members.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: borderLight, height: 1),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  // =========================
  // Empty State (belum ada anggota)
  // =========================
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 48,
            color: gray300,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada anggota tim',
            style: sSemiBold.copyWith(color: gray400),
          ),
          const SizedBox(height: 4),
          Text(
            'Tambahkan anggota untuk mulai mengelola tim',
            style: xsRegular.copyWith(color: gray400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // =========================
  // Member Tile
  // =========================
  Widget _buildMemberTile({
    required String username,
    required String email,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: smSemiBold.copyWith(color: gray500),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: sSemiBold.copyWith(color: textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: xsRegular.copyWith(color: gray500),
                ),
              ],
            ),
          ),
          // Badge Staff
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Staff',
              style: xsSemiBold.copyWith(
                color: const Color(0xFF16A34A),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                'assets/svg/delete.svg',
                width: 16,
                height: 16,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Dialog Hapus Anggota
  // =========================
  void _showDeleteMemberDialog(int index) {
    final member = _members[index];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_remove_rounded,
                  color: Color(0xFFEF4444),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Hapus Anggota?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Apakah Anda yakin ingin menghapus ${member['username']} dari tim?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 28),
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
                        backgroundColor: const Color(0xFFEF4444),
                        elevation: 2,
                        shadowColor: const Color(0xFFEF4444).withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        try {
                          // Hapus dari Firestore members/
                          await _firestore
                              .collection('users')
                              .doc(_userId)
                              .collection('members')
                              .doc(member['uid'])
                              .delete();

                          // Hapus userShopMapping
                          await _firestore
                              .collection('userShopMapping')
                              .doc(member['uid'])
                              .delete();

                          setState(() {
                            _members.removeAt(index);
                          });
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${member['username']} dihapus dari tim'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Gagal menghapus: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Hapus',
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

  // =========================
  // Tombol Tambah Anggota
  // =========================
  Widget _buildAddMemberButton() {
    return SizedBox(
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMemberScreen(),
            ),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_rounded, color: white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Tambah Anggota',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
