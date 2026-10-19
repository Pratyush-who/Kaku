import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

/// Centralized GoRouter routing configuration (Rule 4).
abstract final class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String signIn = '/signin';
  static const String signUp = '/signup';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const CustomTransitionPage<void>(
          key: ValueKey('splash'),
          child: SplashPage(),
          transitionsBuilder: _fadeTransition,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.auth,
      name: 'auth',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const CustomTransitionPage<void>(
          key: ValueKey('auth'),
          child: AuthPage(initialMode: AuthMode.signIn),
          transitionsBuilder: _fadeSlideTransition,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.signIn,
      name: 'signIn',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const CustomTransitionPage<void>(
          key: ValueKey('signIn'),
          child: AuthPage(initialMode: AuthMode.signIn),
          transitionsBuilder: _fadeSlideTransition,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.signUp,
      name: 'signUp',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const CustomTransitionPage<void>(
          key: ValueKey('signUp'),
          child: AuthPage(initialMode: AuthMode.signUp),
          transitionsBuilder: _fadeSlideTransition,
        );
      },
    ),
  ],
);

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _fadeSlideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final slideIn = Tween<Offset>(
    begin: const Offset(0.0, 0.04),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

  return SlideTransition(
    position: slideIn,
    child: FadeTransition(opacity: animation, child: child),
  );
}
