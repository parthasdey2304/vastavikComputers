import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app/app.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:no_screenshot/no_screenshot.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Block screenshots and screen recording on mobile platforms
  if (!kIsWeb) {
    try {
      await NoScreenshot.instance.screenshotOff();
    } catch (e) {
      debugPrint('Screenshot blocking not supported on this platform: $e');
    }
  }
  
  runApp(const ProviderScope(child: VastavikApp()));
}
