// ignore_for_file: depend_on_referenced_packages
// Dart driver entry point for Flutter integration tests.
// This file is executed by FlutterDriver during integration testing.
// To run integration tests: flutter drive --target=lib/main_driver.dart

import 'package:flutter_driver/driver_extension.dart';
import 'package:libri_flow/main.dart' as app;

void main() {
  enableFlutterDriverExtension();
  app.main();
}
