import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/board/presentation/pages/board_page.dart';
import '../../features/project_detail/presentation/pages/project_detail_page.dart';
import '../../features/projects/presentation/pages/projects_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

/// Centralized GoRouter routing configuration.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String signIn = '/signin';
  static const String signUp = '/signup';
  static const String projects = '/projects';
  static const String projectDetail = '/projects/:id';
  static const String board = '/boards/:id';
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
    GoRoute(
      path: AppRoutes.projects,
      name: 'projects',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const CustomTransitionPage<void>(
          key: ValueKey('projects'),
          child: ProjectsPage(),
          transitionsBuilder: _fadeSlideTransition,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.projectDetail,
      name: 'projectDetail',
      pageBuilder: (BuildContext context, GoRouterState state) {
        final projectId = state.pathParameters['id'] ?? '';
        return CustomTransitionPage<void>(
          key: ValueKey('project-$projectId'),
          child: ProjectDetailPage(projectId: projectId),
          transitionsBuilder: _fadeSlideTransition,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.board,
      name: 'board',
      pageBuilder: (BuildContext context, GoRouterState state) {
        final boardId = state.pathParameters['id'] ?? '';
        return CustomTransitionPage<void>(
          key: ValueKey('board-$boardId'),
          child: BoardPage(boardId: boardId),
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
