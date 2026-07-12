import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_state.dart';
import '../../presentation/screens/onboarding/splash_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/role_selection_screen.dart';
import '../../presentation/screens/home/home_shell.dart';
import '../../presentation/screens/home/discover_screen.dart';
import '../../presentation/screens/home/dashboard_screen.dart';
import '../../presentation/screens/opportunity/opportunity_detail_screen.dart';
import '../../presentation/screens/opportunity/post_opportunity_screen.dart';
import '../../presentation/screens/startup/startup_profile_screen.dart';
import '../../presentation/screens/startup/create_startup_screen.dart';
import '../../presentation/screens/startup/startup_detail_screen.dart';
import '../../presentation/screens/application/apply_screen.dart';
import '../../presentation/screens/application/applications_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/chat/chats_screen.dart';
import '../../presentation/screens/chat/chat_detail_screen.dart';
import '../../presentation/screens/notification/notifications_screen.dart';
import '../../data/models/chat_room_model.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.status == AuthStatus.unknown;

      final location = state.uri.toString();

      // Allow splash screen
      if (location == '/splash') return null;

      // Still loading auth state
      if (isLoading) return '/splash';

      // Auth pages shouldn't be accessible when authenticated
      final isAuthPage = location.startsWith('/login') ||
          location.startsWith('/register') ||
          location.startsWith('/onboarding') ||
          location.startsWith('/role-select');

      if (isAuthenticated && isAuthPage) return '/home';
      if (!isAuthenticated && !isAuthPage) return '/onboarding';

      return null;
    },
    refreshListenable: _AuthBlocListenable(authBloc),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/role-select',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final role = extra?['role'] as String? ?? 'student';
          return RegisterScreen(role: role);
        },
      ),

      // Shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/applications',
            builder: (context, state) => const ApplicationsScreen(),
          ),
          GoRoute(
            path: '/chats',
            builder: (context, state) => const ChatsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Messaging / Notifications routes
      GoRoute(
        path: '/chat/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final chatRoom = state.extra as ChatRoomModel;
          return ChatDetailScreen(chatRoom: chatRoom);
        },
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Opportunity routes
      GoRoute(
        path: '/opportunity/post',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PostOpportunityScreen(),
      ),
      GoRoute(
        path: '/opportunity/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => OpportunityDetailScreen(
          opportunityId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/opportunity/:id/apply',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ApplyScreen(
          opportunityId: state.pathParameters['id']!,
        ),
      ),

      // Startup routes
      GoRoute(
        path: '/startup/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateStartupScreen(),
      ),
      GoRoute(
        path: '/startup/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StartupProfileScreen(),
      ),
      GoRoute(
        path: '/startup/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StartupDetailScreen(
          startupId: state.pathParameters['id']!,
        ),
      ),

      // Profile routes
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  );
}

class _AuthBlocListenable extends ChangeNotifier {
  final AuthBloc _authBloc;
  late final _subscription;

  _AuthBlocListenable(this._authBloc) {
    _subscription = _authBloc.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
