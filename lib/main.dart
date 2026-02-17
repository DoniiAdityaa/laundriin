import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:laundriin/ui/color.dart';
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

  //
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          useMaterial3: true,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          colorScheme: ColorScheme.fromSeed(
            seedColor: blue600, // warna brand kamu
          ),

          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: blue600,
          ),
          // This is the theme of your application.
          //
          // TRY THIS: Try running your application with "flutter run". You'll see
          // the application has a purple toolbar. Then, without quitting the app,
          // try changing the seedColor in the colorScheme below to Colors.green
          // and then invoke "hot reload" (save your changes or press the "hot
          // reload" button in a Flutter-supported IDE, or press "r" if you used
          // the command line to start the app).
          //
          // Notice that the counter didn't reset back to zero; the application
          // state is not lost during the reload. To reset the state, use hot
          // restart instead.
          //
          // This works for code too, not just values: Most code changes can be
          // tested with just a hot reload.
        ),
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
          return const MainNavigation();
        },
      );
    } else {
      // User belum login, ke login screen
      return const LoginScreen();
    }
  }
}
