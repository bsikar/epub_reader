import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

QueryExecutor openWebConnection() {
  // This should never be called on non-web platforms
  throw UnsupportedError('Web database not supported on this platform');
}