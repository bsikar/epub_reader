import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:drift/web.dart';

QueryExecutor openWebConnection() {
  // Use default web database with simple localStorage
  return WebDatabase('epub_reader_db');
}