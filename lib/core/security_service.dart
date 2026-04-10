import 'package:flutter/services.dart';
import 'dart:io';

class SecurityService {
  static const _channel = MethodChannel('com.unipast/security');

  /// Toggles screenshot and screen recording protection (Android only).
  static Future<void> enableScreenshotProtection(bool enable) async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('setSecure', {'secure': enable});
    } on PlatformException catch (e) {
      print('Failed to set secure flag: ${e.message}');
    }
  }
}
