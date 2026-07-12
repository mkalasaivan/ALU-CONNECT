import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/application/application_cubit.dart';
import '../../blocs/startup/startup_cubit.dart';
import '../../blocs/opportunity/opportunity_cubit.dart';
import '../../../data/models/startup_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    if (user.isStartup) {
      context.read<StartupCubit>().subscribeToUserStartup(user.uid);
      final startup = context.read<StartupCubit>().state.currentUserStartup;
      if (startup != null) {
        context.read<ApplicationCubit>().loadStats(startup.id);
        context.read<ApplicationCubit>().subscribeToReceivedApplications(startup.id);
      }
    } else {
      context.read<ApplicationCubit>().subscribeToMyApplications(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            _loadData();
          },
        ),
        BlocListener<StartupCubit, StartupState>(
          listener: (context, startupState) {
            final startup = startupState.currentUserStartup;
            if (startup != null) {
              context.read<ApplicationCubit>().loadStats(startup.id);
              context.read<ApplicationCubit>().subscribeToReceivedApplications(startup.id);
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState.user;
          if (user == null) return const SizedBox();

          return user.isStartup
              ? _StartupDashboard(user: user)
              : _StudentDashboard(user: user);
        },
      ),
    );
  }
}

class _StudentDashboard extends StatelessWidget {
  final dynamic user;

  const _StudentDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<ApplicationCubit, ApplicationState>(
        builder: (context, appState) {
          final apps = appState.myApplications;
          final pending = apps.where((a) => a.isPending).length;
          final shortlisted = apps.where((a) => a.isShortlisted).length;
          final accepted = apps.where((a) => a.isAccepted).length;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.background,
                title: Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                floating: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Applied',
                              value: apps.length.toString(),
                              icon: Icons.send_rounded,
                              color: AppColors.primary,
                            ).animate().fadeIn(delay: 100.ms),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Shortlisted',
                              value: shortlisted.toString(),
                              icon: Icons.star_rounded,
                              color: AppColors.warning,
                            ).animate().fadeIn(delay: 200.ms),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Accepted',
                              value: accepted.toString(),
                              icon: Icons.check_circle_rounded,
                              color: AppColors.success,
                            ).animate().fadeIn(delay: 300.ms),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Profile completeness
                      _ProfileCompleteness(user: user),
                      const SizedBox(height: 28),

                      // Quick Actions
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.explore_rounded,
                              label: 'Browse\nOpportunities',
                              color: AppColors.primary,
                              onTap: () => context.go('/home'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.bookmark_rounded,
                              label: 'Saved\nOpportunities',
                              color: AppColors.accent,
                              onTap: () => context.go('/applications'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.person_rounded,
                              label: 'Edit\nProfile',
                              color: AppColors.secondary,
                              onTap: () => context.push('/profile/edit'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Recent Applications
                      if (apps.isNotEmpty) ...[
                        Text(
                          'Recent Applications',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        ...apps.take(3).map((app) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ApplicationStatusCard(application: app),
                            )),
                        if (apps.length > 3)
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/applications'),
                              child: const Text('View All Applications'),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StartupDashboard extends StatelessWidget {
  final dynamic user;

  const _StartupDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<StartupCubit, StartupState>(
        builder: (context, startupState) {
          final startup = startupState.currentUserStartup;

          return BlocBuilder<ApplicationCubit, ApplicationState>(
            builder: (context, appState) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: AppColors.background,
                    title: Text(
                      'Startup Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    floating: true,
                    actions: [
                      IconButton(
                        onPressed: () => context.push('/startup/profile'),
                        icon: const Icon(Icons.settings_rounded),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Startup status card
                          if (startup != null) ...[
                            _StartupStatusCard(startup: startup),
                            const SizedBox(height: 20),
                          ] else ...[
                            _CreateStartupBanner(),
                            const SizedBox(height: 20),
                          ],

                          // Stats
                          if (startup != null) ...[
                            Text(
                              'Application Overview',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    title: 'Total',
                                    value: (appState.stats['total'] ?? 0)
                                        .toString(),
                                    icon: Icons.people_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    title: 'Pending',
                                    value: (appState.stats['pending'] ?? 0)
                                        .toString(),
                                    icon: Icons.pending_rounded,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    title: 'Accepted',
                                    value: (appState.stats['accepted'] ?? 0)
                                        .toString(),
                                    icon: Icons.check_circle_rounded,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                          ],

                          // Quick actions
                          Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _QuickAction(
                                  icon: Icons.add_circle_rounded,
                                  label: 'Post\nOpportunity',
                                  color: AppColors.primary,
                                  onTap: () => context.push('/opportunity/post'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _QuickAction(
                                  icon: Icons.people_rounded,
                                  label: 'View\nApplicants',
                                  color: AppColors.secondary,
                                  onTap: () => context.go('/applications'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _QuickAction(
                                  icon: Icons.business_rounded,
                                  label: 'Edit\nProfile',
                                  color: AppColors.accent,
                                  onTap: () => context.push('/startup/profile'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCompleteness extends StatelessWidget {
  final dynamic user;

  const _ProfileCompleteness({required this.user});

  @override
  Widget build(BuildContext context) {
    int completed = 0;
    int total = 5;
    if (user.bio != null && user.bio!.isNotEmpty) completed++;
    if (user.campus != null) completed++;
    if (user.major != null) completed++;
    if (user.skills.isNotEmpty) completed++;
    if (user.linkedInUrl != null) completed++;

    final percent = completed / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Profile Completeness',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const Spacer(),
              Text(
                '${(percent * 100).toInt()}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.push('/profile/edit'),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Complete Profile →',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationStatusCard extends StatelessWidget {
  final dynamic application;

  const _ApplicationStatusCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      'pending': AppColors.warning,
      'reviewing': AppColors.info,
      'shortlisted': AppColors.accent,
      'accepted': AppColors.success,
      'rejected': AppColors.error,
      'withdrawn': AppColors.textMuted,
    };

    final color = statusColors[application.status.toString().split('.').last] ?? AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.business_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  application.opportunityTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  application.startupName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _capitalizeFirst(application.status.toString().split('.').last),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeFirst(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }
}

class _StartupStatusCard extends StatelessWidget {
  final dynamic startup;

  const _StartupStatusCard({required this.startup});

  @override
  Widget build(BuildContext context) {
    final isVerified = startup.verificationStatus == VerificationStatus.verified;
    final isPending = startup.verificationStatus == VerificationStatus.pending;
    final color = isVerified
        ? AppColors.success
        : isPending
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.tealGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
                Icons.rocket_launch_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  startup.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVerified
                                ? Icons.verified_rounded
                                : Icons.pending_rounded,
                            size: 12,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isVerified
                                ? 'Verified'
                                : isPending
                                    ? 'Under Review'
                                    : 'Rejected',
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isVerified) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          context.read<StartupCubit>().verifyStartup(
                                startup.id,
                                VerificationStatus.verified,
                              );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.success.withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.gavel_rounded,
                                  size: 10, color: AppColors.success),
                              SizedBox(width: 4),
                              Text(
                                'Demo: Verify',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateStartupBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/startup/create'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.tealGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_business_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Register Your Startup',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Get verified and start posting opportunities',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
