import 'package:flutter/material.dart';
import 'theme/theme_manager.dart';
import 'widgets/app_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize theme manager
    debugPrint('🚀 Initializing BunkMate app...');
    await ThemeManager().initialize();
    debugPrint('✅ Theme manager initialized successfully');
    
    runApp(const BunkMateApp());
  } catch (e) {
    debugPrint('❌ Error during app initialization: $e');
    // Still run the app with fallback theme
    runApp(const BunkMateApp());
  }
}
