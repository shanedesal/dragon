// ignore_for_file: depend_on_referenced_packages
import 'package:dragon/firebase_options.dart';
import 'package:dragon/features/auth/screens/login_screen.dart';
import 'package:dragon/shell/main_shell.dart';
import 'package:dragon/features/auth/screens/register_screen.dart';
import 'package:dragon/features/auth/screens/splash_screen.dart';
import 'package:dragon/theme/app_theme.dart';
import 'package:dragon/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:dragon/shell/navigation_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

// Notifier that triggers GoRouter to re-evaluate its redirect
// whenever the Firebase auth state changes.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    FirebaseAuth.instance
        .authStateChanges()
        .listen((_) => notifyListeners());
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

    if (onSplash) return null;
    if (isAuthenticated && onAuthRoute) return '/home';
    if (!isAuthenticated && !onAuthRoute) return '/login';
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => const MainShell(),
    ),
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
