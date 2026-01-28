import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';
import 'package:laundriin/features/auth/login_screen.dart';
import 'package:laundriin/features/settings/pricing_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final TextEditingController _shopNameC =
      TextEditingController(text: "LAUNDRIIN");
  String _appVersion = "1.0.0";

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _logout() async {
    // Show modern confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
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
              // Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                "Logout?",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),

              // Message
              Text(
                "Apakah Anda yakin ingin keluar dari akun ini?",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  // Cancel Button
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
                      child: const Text(
                        "Batal",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Logout Button
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
                        Navigator.pop(context);
                        try {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: ${e.toString()}")),
                          );
                        }
                      },
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                "Settings",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 14),

              // ===== Shop Information Section =====
              _buildCardSection(
                icon: Icons.store_rounded,
                title: "Shop Information",
                onTap: () {
                  // TODO: navigate to shop info detail
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    const Text(
                      "Shop Name",
                      style: xsRegular,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _shopNameC,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: bgInput,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: borderFocus, width: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: borderLight, // bg grey untuk bungkus
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // ===== Menu Cards =====
                    _buildMenuCard(
                      icon: Icons.attach_money,
                      title: "Pricing Settings",
                      subtitle: "Edit harga kiloan & non-kiloan",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PricingScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildMenuCard(
                      icon: Icons.chat_bubble_outline_outlined,
                      title: "Whatsapp Message Template",
                      subtitle: "Atur template pesan WhatsApp",
                      onTap: () {},
                    ),
                    // const SizedBox(height: 10),

                    // _buildMenuCard(
                    //   icon: Icons.receipt_long_rounded,
                    //   title: "Receipt & Printer",
                    //   subtitle: "Nota, format struk, printer",
                    //   onTap: () {},
                    // ),
                    // const SizedBox(height: 10),

                    // _buildMenuCard(
                    //   icon: Icons.security_rounded,
                    //   title: "Security",
                    //   subtitle: "Ubah password & logout",
                    //   onTap: () {},
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ===== Logout Button =====
              _buildLogoutButton(
                onTap: _logout,
              ),

              const SizedBox(height: 20),

              // ===== Version Info =====
              Center(
                child: Text(
                  "LAUNDRIIN v$_appVersion",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "© 2026 LAUNDRIIN. All Rights Reserved.",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFD1D5DB),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shopNameC.dispose();
    super.dispose();
  }

  // =========================
  // Card Section Builder
  // =========================
  Widget _buildCardSection({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: blue50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: blue600, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  // =========================
  // Menu Card Builder
  // =========================
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: green100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: green600, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: gray400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // Logout Button Builder
  // =========================
  Widget _buildLogoutButton({
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: const Color(0xFFEF4444).withOpacity(0.3),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              "Logout",
              style: xsBold.copyWith(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
