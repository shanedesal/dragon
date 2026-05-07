// ignore_for_file: depend_on_referenced_packages
import 'package:dragon/firebase_options.dart';
import 'package:dragon/features/auth/screens/login_screen.dart';
import 'package:dragon/shell/main_shell.dart';
import 'package:dragon/features/auth/screens/register_screen.dart';
import 'package:dragon/features/auth/screens/splash_screen.dart';
import 'package:dragon/theme/app_theme.dart';
import 'package:dragon/shared/utils/app_logger.dart';
import 'package:dragon/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:dragon/features/walk/viewmodels/walk_viewmodel.dart';
import 'package:dragon/features/food/viewmodels/food_viewmodel.dart';
import 'package:dragon/shell/navigation_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  AppLogger.d('App', 'Bootstrapping');
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.d('App', 'Firebase initialize start');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: '.env');
  AppLogger.d('App', 'Firebase initialize done');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
        ChangeNotifierProvider(create: (_) => WalkViewModel()),
        ChangeNotifierProvider(create: (_) => FoodViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

// Notifier that triggers GoRouter to re-evaluate its redirect
// whenever the Firebase auth state changes.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      AppLogger.d(
        'Auth',
        'Auth state changed: uid=${user?.uid ?? 'null'} '
            'email=${user?.email ?? 'null'}',
      );
      notifyListeners();
    });
  }
}

final _authNotifier = _AuthNotifier();

final _router = GoRouter(
  initialLocation: '/splash',
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
    final path = state.matchedLocation;
    final onSplash = path == '/splash';
    final onAuthRoute = path == '/login' || path == '/register';

    AppLogger.d(
      'Router',
      'Redirect check: path=$path authed=$isAuthenticated '
          'onSplash=$onSplash onAuth=$onAuthRoute',
    );

    if (onSplash) return null;
    if (isAuthenticated && onAuthRoute) return '/home';
    if (!isAuthenticated && !onAuthRoute) return '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (_, _) => const MainShell()),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dragon',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
