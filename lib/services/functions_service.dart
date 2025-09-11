// File to initialize Firebase Functions

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FunctionsService {
  static FirebaseFunctions? _functions;

  static FirebaseFunctions get functions {
    if (_functions == null) {
      throw Exception(
        'Firebase Functions not initialized. Call initialize() first.',
      );
    }
    return _functions!;
  }

  static Future<void> initialize() async {
    try {
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _functions = FirebaseFunctions.instance;

      // For local testing (uncomment if you're using a local emulator)
      // _functions.useFunctionsEmulator('localhost', 5001);

      debugPrint('✅ Firebase Functions initialized successfully!');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Functions: $e');
      rethrow;
    }
  }

  static bool isInitialized() {
    return _functions != null;
  }

  static Future<dynamic> callFunction(String name, dynamic data) async {
    try {
      debugPrint('📞 Calling Firebase Function: $name');

      // Make sure functions is initialized
      if (!isInitialized()) {
        await initialize();
      }

      final callable = functions.httpsCallable(name);
      final result = await callable.call(data);

      debugPrint('✅ Function call successful: $name');
      return result.data;
    } catch (e, stackTrace) {
      debugPrint('❌ Error calling Firebase Function $name: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }
}
