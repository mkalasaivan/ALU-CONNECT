import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/startup_repository.dart';
import 'data/repositories/opportunity_repository.dart';
import 'data/repositories/application_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/startup/startup_cubit.dart';
import 'presentation/blocs/opportunity/opportunity_cubit.dart';
import 'presentation/blocs/application/application_cubit.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'presentation/blocs/chat/chat_cubit.dart';
import 'presentation/blocs/notification/notification_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(const ALUConnectApp());
}

class ALUConnectApp extends StatelessWidget {
  const ALUConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize repositories
    final authRepository = AuthRepository();
    final startupRepository = StartupRepository();
    final opportunityRepository = OpportunityRepository();
    final applicationRepository = ApplicationRepository();
    final chatRepository = ChatRepository();
    final notificationRepository = NotificationRepository();

    // Create auth bloc
    final authBloc = AuthBloc(authRepository: authRepository)
      ..add(const AuthStarted());

    // Create router
    final appRouter = AppRouter(authBloc: authBloc);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<StartupRepository>.value(value: startupRepository),
        RepositoryProvider<OpportunityRepository>.value(
            value: opportunityRepository),
        RepositoryProvider<ApplicationRepository>.value(
            value: applicationRepository),
        RepositoryProvider<ChatRepository>.value(value: chatRepository),
        RepositoryProvider<NotificationRepository>.value(value: notificationRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<StartupCubit>(
            create: (context) => StartupCubit(repository: startupRepository),
          ),
          BlocProvider<OpportunityCubit>(
            create: (context) =>
                OpportunityCubit(repository: opportunityRepository),
          ),
          BlocProvider<ApplicationCubit>(
            create: (context) => ApplicationCubit(
              applicationRepository: applicationRepository,
              opportunityRepository: opportunityRepository,
              notificationRepository: notificationRepository,
            ),
          ),
          BlocProvider<ChatCubit>(
            create: (context) => ChatCubit(repository: chatRepository),
          ),
          BlocProvider<NotificationCubit>(
            create: (context) => NotificationCubit(repository: notificationRepository),
          ),
        ],
        child: MaterialApp.router(
          title: 'ALU Connect',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: appRouter.router,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0), // Prevent text scaling issues
              ),
              child: child!,
            );
          },
        ),
      ),
    );
  }
}
