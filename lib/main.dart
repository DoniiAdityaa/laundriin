import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:laundriin/config/service_locator.dart';
import 'package:laundriin/features/orders/cubit/wablas_cubit.dart';
import 'package:laundriin/ui/theme.dart';
import 'firebase_options.dart';
import 'package:laundriin/features/auth/login_screen.dart';
import 'package:laundriin/ui/shared_widget/main_navigation.dart';
import 'package:laundriin/config/shop_config.dart';
import 'package:laundriin/utility/snackbar_helper.dart';
import 'package:laundriin/utility/network_banner.dart';
import 'package:laundriin/utility/offline_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:laundriin/features/tracking/tracking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setUpLocator();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize date formatting untuk locale Indonesia
  await initializeDateFormatting('id_ID');

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // batasi cache
  FirebaseFirestore.instance.settings = const Settings(
    cacheSizeBytes: 10 * 1024 * 1024, // 10MB
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Key _retryKey = UniqueKey();

  void _retry() {
    setState(() {
      _retryKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: BlocProvider<WablasCubit>(
        create: (context) => serviceLocator.get<WablasCubit>(),
        child: MaterialApp(
          scaffoldMessengerKey: SnackbarHelper.key,
          builder: (context, child) {
            return NetworkBanner(child: child!);
          },
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
          onGenerateRoute: (settings) {
            final uri = Uri.parse(settings.name ?? '/');

            if (uri.path.startsWith('/track')) {
              final orderId = uri.queryParameters['o'];
              final shopId = uri.queryParameters['s'];

              return MaterialPageRoute(
                builder: (context) => TrackingScreen(
                  initialOrderId: orderId,
                  initialShopId: shopId,
                ),
              );
            }

            if (uri.path == '/login') {
              return MaterialPageRoute(
                builder: (context) => _initialScreen(),
              );
            }

            return null; // Fallback to 'home'
          },
          home: kIsWeb ? const TrackingScreen() : _initialScreen(),
        ),
      ),
    );
  }

  Widget _initialScreen() {
    // Cek apakah user sudah login di Firebase
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User sudah login, cek apakah staff yang dihapus
      return FutureBuilder(
        key: _retryKey,
        future: _checkAndLoadUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) {
            return OfflineScreen(
              errorMessage: snapshot.error.toString(),
              onRetry: _retry,
            );
          }
          // Jika false = staff dihapus, arahkan ke login
          if (snapshot.data == false) {
            return const LoginScreen();
          }
          return const MainNavigation();
        },
      );
    } else {
      // User belum login, ke login screen
      return const LoginScreen();
    }
  }

  /// Cek apakah user masih valid (staff belum dihapus), lalu load data toko
  Future<bool> _checkAndLoadUser(String uid) async {
    final mappingDoc = await FirebaseFirestore.instance
        .collection('userShopMapping')
        .doc(uid)
        .get();

    if (mappingDoc.exists) {
      // User adalah staff
      final adminUid = mappingDoc.data()!['shopOwnerId'];
      final memberDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminUid)
          .collection('members')
          .doc(uid)
          .get();

      if (!memberDoc.exists) {
        // Staff sudah dihapus → sign out
        await FirebaseAuth.instance.signOut();
        return false;
      }

      // Staff valid, load data toko admin
      ShopSettings.shopOwnerId = adminUid;
      ShopSettings.currentUserDisplayName =
          memberDoc.data()?['username'] ?? 'Staff';
      await Future.wait([
        ShopSettings.loadFromFirestore(adminUid),
        DeliveryConfig.loadFromDatabase(adminUid),
      ]);
    } else {
      // Tidak ada mapping → cek apakah benar admin (punya doc users/{uid})
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        // Bukan admin, bukan staff aktif → akun orphan
        await FirebaseAuth.instance.signOut();
        return false;
      }

      // Admin valid, load data toko sendiri
      ShopSettings.shopOwnerId = uid;
      await Future.wait([
        ShopSettings.loadFromFirestore(uid),
        DeliveryConfig.loadFromDatabase(uid),
      ]);
      final adminUsername = userDoc.data()?['username'];
      ShopSettings.currentUserDisplayName =
          (adminUsername != null && adminUsername.toString().isNotEmpty)
              ? adminUsername
              : ShopSettings.ownerName;
    }

    return true;
  }
}
