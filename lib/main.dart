import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:laundriin/ui/theme.dart';
import 'firebase_options.dart';
import 'package:laundriin/features/auth/login_screen.dart';
import 'package:laundriin/ui/shared_widget/main_navigation.dart';
import 'package:laundriin/config/shop_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize date formatting untuk locale Indonesia
  await initializeDateFormatting('id_ID');

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Laundriin',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        theme: AppTheme.light,
        home: _initialScreen(),
      ),
    );
  }

  Widget _initialScreen() {
    // Cek apakah user sudah login di Firebase
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User sudah login, load data toko dulu baru ke dashboard
      return FutureBuilder(
        future: Future.wait([
          ShopSettings.loadFromFirestore(user.uid),
          DeliveryConfig.loadFromDatabase(user.uid),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Gagal memuat data toko'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Force rebuild
                        (context as Element).markNeedsBuild();
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const MainNavigation();
        },
      );
    } else {
      // User belum login, ke login screen
      return const LoginScreen();
    }
  }
}
