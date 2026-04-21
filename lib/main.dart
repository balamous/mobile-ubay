import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/app_controller.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';
import 'services/api_service.dart';
import 'services/biometric_service.dart';
import 'services/twofa_service.dart';
import 'services/transaction_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for French locale
  await initializeDateFormatting('fr_FR', null);

  // await SharedPreferences.getInstance().then((prefs) {
  //   prefs.clear();
  // });

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Init services ──────────────────────────────────────────────────────────
  await Get.put(ApiService());
  await Get.put(DatabaseService());
  await Get.put(AuthService());
  await Get.put(DashboardService());
  await Get.put(TransactionService());
  await Get.put(AppController());
  await Get.putAsync(() async => await BiometricService().init());
  await Get.putAsync(() async => await TwoFAService().init());

  runApp(const UBayApp());
}

class UBayApp extends StatefulWidget {
  const UBayApp({super.key});

  @override
  State<UBayApp> createState() => _UBayAppState();
}

class _UBayAppState extends State<UBayApp> with WidgetsBindingObserver {
  final AppController _appCtrl = Get.put(AppController());
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bio = BiometricService.to;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _wasInBackground = true;
        if (bio.isEnabled.value) bio.lock();
        break;

      case AppLifecycleState.resumed:
        if (_wasInBackground && bio.isLocked.value) {
          _wasInBackground = false;
          // Navigate to biometric lock screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.toNamed(AppRoutes.biometricLock);
          });
        } else {
          _wasInBackground = false;
        }
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => GetMaterialApp(
          title: 'uBAY',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode:
              _appCtrl.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
          initialRoute: AppRoutes.splash,
          getPages: AppRoutes.pages,
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 300),
        ));
  }
}
