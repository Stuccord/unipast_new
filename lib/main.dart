import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:unipast/core/startup_widget.dart';

void main() {
  // MUST be in the root zone before runZonedGuarded.
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors (render, layout, etc.)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('❌ Flutter Error: ${details.exception}');
  };

  // Catch async/platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('❌ Platform Error: $error');
    return true; // Returning true prevents crash on Android
  };

  // Run the app. Zone errors are caught and logged — never re-run the app.
  runZonedGuarded(
    () => runApp(const AppStartupWidget()),
    (error, stack) {
      debugPrint('❌ Zone Error: $error');
      debugPrint(stack.toString());
    },
  );
}
