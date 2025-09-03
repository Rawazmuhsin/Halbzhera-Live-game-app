import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

// Database service provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});
