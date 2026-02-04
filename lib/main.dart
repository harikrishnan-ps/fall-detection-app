import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/fall_detection_service.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/person_dashboard.dart';
import 'screens/caregiver_dashboard.dart';
import 'screens/add_person_screen.dart';
import 'screens/add_caregiver_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (optional - app will work without it)
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
    debugPrint('✓ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠ Firebase initialization failed: $e');
    debugPrint('⚠ App will run in offline mode. See FIREBASE_SETUP.md to configure Firebase');
  }

  // Initialize notification service (only if Firebase is available)
  if (firebaseInitialized) {
    try {
      await NotificationService().initialize();
      debugPrint('✓ Notification service initialized');
    } catch (e) {
      debugPrint('⚠ Notification service initialization failed: $e');
    }
  } else {
    debugPrint('⚠ Skipping notification service (Firebase not available)');
  }

  runApp(const FallDetectionApp());
}

class FallDetectionApp extends StatelessWidget {
  const FallDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FallDetectionService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          return MaterialApp(
            title: 'Fall Detection',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            
            // Initial route
            initialRoute: '/',
            
            // Routes
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/person-dashboard': (context) => const PersonDashboard(),
              '/caregiver-dashboard': (context) => const CaregiverDashboard(),
              '/add-person': (_) => const AddPersonScreen(),
              '/add-caregiver': (_) => const AddCaregiverScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
            
            // Handle unknown routes
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
