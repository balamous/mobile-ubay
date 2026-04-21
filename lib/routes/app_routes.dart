import 'package:get/get.dart';
import '../modules/splash/splash_screen.dart';
import '../modules/auth/login/login_screen.dart';
import '../modules/auth/register/register_screen.dart';
import '../modules/auth/forgot_password/forgot_password_screen.dart';
import '../modules/dashboard/dashboard_screen.dart';
import '../modules/deposit/deposit_screen.dart';
import '../modules/withdrawal/withdrawal_screen.dart';
import '../modules/transfer/transfer_screen.dart';
import '../modules/payment/payment_screen.dart';
import '../modules/topup/topup_screen.dart';
import '../modules/airtime/airtime_screen.dart';
import '../modules/services/services_screen.dart';
import '../modules/history/history_screen.dart';
import '../modules/card/card_screen.dart';
import '../modules/notifications/notifications_screen.dart';
import '../modules/profile/profile_screen.dart';
import '../modules/onboarding/onboarding_screen.dart';
import '../modules/auth/otp/otp_screen.dart';
import '../modules/auth/biometric/biometric_lock_screen.dart';
import '../modules/auth/twofa/twofa_setup_screen.dart';
import '../modules/auth/twofa/twofa_verify_screen.dart';
import '../modules/card/create_card_screen.dart';
import '../modules/profile/personal_info_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String otp = '/otp';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String deposit = '/deposit';
  static const String withdrawal = '/withdrawal';
  static const String transfer = '/transfer';
  static const String payment = '/payment';
  static const String topup = '/topup';
  static const String airtime = '/airtime';
  static const String services = '/services';
  static const String history = '/history';
  static const String card = '/card';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String createCard = '/create-card';
  static const String biometricLock = '/biometric-lock';
  static const String twoFASetup = '/2fa-setup';
  static const String twoFAVerify = '/2fa-verify';
  static const String personalInfo = '/personal-info';

  static final List<GetPage> pages = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: otp,
      page: () => const OtpScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: register, page: () => const RegisterScreen()),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordScreen()),
    GetPage(
      name: dashboard,
      page: () => const DashboardScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(name: deposit, page: () => const DepositScreen(), transition: Transition.downToUp),
    GetPage(name: withdrawal, page: () => const WithdrawalScreen(), transition: Transition.downToUp),
    GetPage(name: transfer, page: () => const TransferScreen(), transition: Transition.downToUp),
    GetPage(name: payment, page: () => const PaymentScreen(), transition: Transition.downToUp),
    GetPage(name: topup, page: () => const TopupScreen(), transition: Transition.downToUp),
    GetPage(name: airtime, page: () => const AirtimeScreen(), transition: Transition.downToUp),
    GetPage(name: services, page: () => const ServicesScreen(), transition: Transition.rightToLeft),
    GetPage(name: history, page: () => const HistoryScreen(), transition: Transition.rightToLeft),
    GetPage(name: card, page: () => const CardScreen(), transition: Transition.rightToLeft),
    GetPage(name: notifications, page: () => const NotificationsScreen(), transition: Transition.rightToLeft),
    GetPage(name: profile, page: () => const ProfileScreen(), transition: Transition.rightToLeft),
    GetPage(name: createCard, page: () => const CreateCardScreen(), transition: Transition.downToUp),
    GetPage(name: biometricLock, page: () => const BiometricLockScreen(), transition: Transition.fadeIn),
    GetPage(name: twoFASetup, page: () => const TwoFASetupScreen(), transition: Transition.rightToLeft),
    GetPage(name: twoFAVerify, page: () => const TwoFAVerifyScreen(), transition: Transition.rightToLeft),
    GetPage(name: personalInfo, page: () => const PersonalInfoScreen(), transition: Transition.rightToLeft),
  ];
}
