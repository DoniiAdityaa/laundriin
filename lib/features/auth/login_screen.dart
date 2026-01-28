import 'package:flutter/material.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      // Simulasi login
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                decoration: BoxDecoration(
                  color: bgCard, // bungkus putih
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo (sementara L)
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset("assets/images/logo.png",
                              fit: BoxFit.cover),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        "LAUNDRIIN",
                        style: xsBold.copyWith(
                          fontSize: 30,
                          color: textPrimary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Laundry Shop Management",
                        style: xsRegular.copyWith(
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Email label
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Email",
                          style: xsBold.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: xsRegular.copyWith(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: "your email adderess",
                          hintStyle: xsRegular.copyWith(color: textMuted),
                          filled: true,
                          fillColor: bgInput,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: borderLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: borderFocus, width: 1.3),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Email wajib diisi";
                          }
                          if (!value.contains("@")) {
                            return "Format email tidak valid";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Password label
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Password",
                          style: xsBold.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: xsBold.copyWith(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: "your password",
                          hintStyle: xsRegular.copyWith(color: textMuted),
                          filled: true,
                          fillColor: bgInput,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: borderLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: borderFocus, width: 1.3),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() {
                              _obscurePassword = !_obscurePassword;
                            }),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: textMuted,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password wajib diisi";
                          }
                          if (value.length < 6) {
                            return "Minimal 6 karakter";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 22),

                      // Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: borderFocus.withOpacity(0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: blue500,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _login,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.login_rounded, color: white),
                                const SizedBox(width: 10),
                                Text(
                                  "Login",
                                  style: xsBold.copyWith(
                                    color: white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        "Secure access for shop owners only",
                        style: xsRegular.copyWith(
                          color: textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
