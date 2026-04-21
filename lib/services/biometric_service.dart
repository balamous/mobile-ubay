import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';

enum BiometricKind { none, fingerprint, face, multiple }

class BiometricService extends GetxService {
  static BiometricService get to => Get.find();

  final LocalAuthentication _auth = LocalAuthentication();

  // ── Observable state ──────────────────────────────────────────────────────
  final RxBool isAvailable = false.obs;
  final RxBool isEnabled = false.obs;
  final Rx<BiometricKind> kind = BiometricKind.none.obs;
  final RxBool isLocked = false.obs;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<BiometricService> init() async {
    await _checkHardware();
    await _loadPrefs();
    return this;
  }

  Future<void> _checkHardware() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      isAvailable.value = canCheck || isDeviceSupported;

      if (isAvailable.value) {
        final available = await _auth.getAvailableBiometrics();
        if (available.isEmpty) {
          kind.value = BiometricKind.none;
        } else if (available.contains(BiometricType.face)) {
          kind.value = available.contains(BiometricType.fingerprint)
              ? BiometricKind.multiple
              : BiometricKind.face;
        } else {
          kind.value = BiometricKind.fingerprint;
        }
      }
    } on PlatformException {
      isAvailable.value = false;
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    isEnabled.value = prefs.getBool('biometric_enabled') ?? false;
    // Only keep enabled if hardware is still available
    if (!isAvailable.value) isEnabled.value = false;
  }

  // ── Authenticate ──────────────────────────────────────────────────────────
  Future<BiometricResult> authenticate({
    String? reason,
    bool biometricOnly = false,
  }) async {
    if (!isAvailable.value) {
      return BiometricResult.unavailable;
    }
    try {
      final success = await _auth.authenticate(
        localizedReason: reason ?? 'Déverrouillez uBAY avec votre biométrie',
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      return success ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) return BiometricResult.unavailable;
      if (e.code == auth_error.notEnrolled) return BiometricResult.notEnrolled;
      if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        return BiometricResult.lockedOut;
      }
      if (e.code == auth_error.passcodeNotSet) {
        return BiometricResult.passcodeNotSet;
      }
      return BiometricResult.failed;
    }
  }

  // ── Enable / Disable ──────────────────────────────────────────────────────
  Future<bool> enableBiometric() async {
    final result = await authenticate(
      reason: 'Confirmez votre identité pour activer la connexion biométrique',
    );
    if (result == BiometricResult.success) {
      isEnabled.value = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', true);
      return true;
    }
    return false;
  }

  Future<void> disableBiometric() async {
    isEnabled.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', false);
  }

  // ── Lock / Unlock ─────────────────────────────────────────────────────────
  void lock() {
    if (isEnabled.value) isLocked.value = true;
  }

  void unlock() => isLocked.value = false;

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get kindLabel {
    if (Platform.isIOS) {
      return kind.value == BiometricKind.face ? 'Face ID' : 'Touch ID';
    }
    return kind.value == BiometricKind.face
        ? 'Reconnaissance faciale'
        : 'Empreinte digitale';
  }

  String get kindIcon {
    return kind.value == BiometricKind.face ? '👤' : '👆';
  }

  bool get isFace =>
      kind.value == BiometricKind.face ||
      kind.value == BiometricKind.multiple;
}

enum BiometricResult {
  success,
  failed,
  unavailable,
  notEnrolled,
  lockedOut,
  passcodeNotSet,
}
