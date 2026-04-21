import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TwoFAService extends GetxService {
  static TwoFAService get to => Get.find();

  // ── Mock TOTP secret ──────────────────────────────────────────────────────
  static const String _secret = 'UBAY GUIN 2024 SECU RITÉ';
  static const String _issuer = 'uBAY Guinée';

  // ── Observable state ──────────────────────────────────────────────────────
  final RxBool is2FAEnabled = false.obs;
  final RxString currentCode = '000000'.obs;
  final RxInt secondsLeft = 30.obs;
  Timer? _timer;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<TwoFAService> init() async {
    final prefs = await SharedPreferences.getInstance();
    is2FAEnabled.value = prefs.getBool('2fa_enabled') ?? false;
    if (is2FAEnabled.value) _startTimer();
    return this;
  }

  // ── TOTP generation ───────────────────────────────────────────────────────
  /// Simple mock TOTP: 6-digit code derived from 30-second UTC window.
  String _generateCode([int? windowOverride]) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final window = windowOverride ?? (now ~/ 30);
    // Deterministic pseudo-random from window + secret hash
    var hash = 0x811C9DC5;
    final key = '$window$_secret';
    for (final char in key.codeUnits) {
      hash ^= char;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    final code = (hash & 0x7FFFFFFF) % 1000000;
    return code.toString().padLeft(6, '0');
  }

  void _startTimer() {
    _timer?.cancel();
    _refreshCode();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final utcSec = DateTime.now().toUtc().second +
          DateTime.now().toUtc().minute * 60;
      final secs = utcSec % 30;
      secondsLeft.value = 30 - secs;
      if (secs == 0) _refreshCode();
    });
  }

  void _refreshCode() {
    currentCode.value = _generateCode();
  }

  // ── Verify ────────────────────────────────────────────────────────────────
  /// Accepts current window and ±1 window (clock skew tolerance)
  bool verifyCode(String input) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final window = now ~/ 30;
    return input == _generateCode(window - 1) ||
        input == _generateCode(window) ||
        input == _generateCode(window + 1);
  }

  // ── Enable / Disable ──────────────────────────────────────────────────────
  Future<void> enable() async {
    is2FAEnabled.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('2fa_enabled', true);
    _startTimer();
  }

  Future<void> disable() async {
    is2FAEnabled.value = false;
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('2fa_enabled', false);
  }

  // ── QR / secret helpers ───────────────────────────────────────────────────
  String get displaySecret => _secret;

  String get secretFormatted {
    // Display in 4-char groups
    final clean = _secret.replaceAll(' ', '');
    final groups = <String>[];
    for (var i = 0; i < clean.length; i += 4) {
      groups.add(clean.substring(
          i, min(i + 4, clean.length)));
    }
    return groups.join(' ');
  }

  String get otpAuthUri =>
      'otpauth://totp/$_issuer?secret=${_secret.replaceAll(' ', '')}&issuer=$_issuer&algorithm=SHA1&digits=6&period=30';

  String get issuer => _issuer;

  double get codeProgress => (30 - secondsLeft.value) / 30.0;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
