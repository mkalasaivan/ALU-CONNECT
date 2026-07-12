import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/application/application_cubit.dart';
import '../../blocs/opportunity/opportunity_cubit.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/opportunity_model.dart';
import '../../blocs/startup/startup_cubit.dart';
import '../../../data/models/chat_room_model.dart';
import '../../blocs/chat/chat_cubit.dart';
import 'package:go_router/go_router.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    if (user.isStudent) {
      context.read<ApplicationCubit>().subscribeToMyApplications(user.uid);
      context.read<OpportunityCubit>().subscribeToBookmarks(user.uid);
    } else if (user.isStartup) {
      final startup = context.read<StartupCubit>().state.currentUserStartup;
      if (startup != null) {
        context.read<ApplicationCubit>().subscribeToReceivedApplications(startup.id);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StartupCubit, StartupState>(
      listener: (context, startupState) {
        final user = context.read<AuthBloc>().state.user;
        final startup = startupState.currentUserStartup;
        if (user != null && user.isStartup && startup != null) {
          context.read<ApplicationCubit>().subscribeToReceivedApplications(startup.id);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState.user;
          if (user == null) return const SizedBox();

          return Scaffold(
            backgroundColor: AppColors.background,
            body: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverAppBar(
                  backgroundColor: AppColors.background,
                  title: Text(
                    user.isStartup ? 'Received Applications' : 'My Applications',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  floating: true,
                  bottom: user.isStudent
                      ? TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.primary,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textMuted,
                          tabs: const [
                            Tab(text: 'Applications'),
                            Tab(text: 'Saved'),
                          ],
                        )
                      : null,
                ),
              ],
              body: user.isStartup
                  ? _StartupApplicationsView()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _StudentApplicationsView(),
                        _SavedOpportunitiesView(userId: user.uid),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _StudentApplicationsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApplicationCubit, ApplicationState>(
      builder: (context, state) {
        final apps = state.myApplications;

        if (apps.isEmpty) {
          return _EmptyView(
            icon: Icons.assignment_outlined,
            title: 'No Applications Yet',
            message: 'Start exploring opportunities and apply for roles that match your skills.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: apps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _StudentApplicationCard(
              application: apps[index],
            ).animate().fadeIn(delay: Duration(milliseconds: index * 80));
          },
        );
      },
    );
  }
}

class _StudentApplicationCard extends StatelessWidget {
  final ApplicationModel application;

  const _StudentApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(application.status);

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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.opportunityTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      application.startupName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: statusInfo['label'] as String,
                color: statusInfo['color'] as Color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Applied ${timeago.format(application.appliedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),

          if (application.statusNote != null &&
              application.statusNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (statusInfo['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.comment_outlined,
                      size: 14,
                      color: statusInfo['color'] as Color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      application.statusNote!,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusInfo['color'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (application.status == ApplicationStatus.pending ||
              application.status == ApplicationStatus.reviewing) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _confirmWithdraw(context, application),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Withdraw',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return {'label': 'Pending', 'color': AppColors.warning};
      case ApplicationStatus.reviewing:
        return {'label': 'Reviewing', 'color': AppColors.info};
      case ApplicationStatus.shortlisted:
        return {'label': 'Shortlisted ⭐', 'color': AppColors.accent};
      case ApplicationStatus.accepted:
        return {'label': 'Accepted 🎉', 'color': AppColors.success};
      case ApplicationStatus.rejected:
        return {'label': 'Not Selected', 'color': AppColors.error};
      case ApplicationStatus.withdrawn:
        return {'label': 'Withdrawn', 'color': AppColors.textMuted};
    }
  }

  void _confirmWithdraw(BuildContext context, ApplicationModel application) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Withdraw Application'),
        content: const Text(
            'Are you sure you want to withdraw this application? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context
                  .read<ApplicationCubit>()
                  .withdrawApplication(application.id);
              Navigator.pop(ctx);
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}

class _StartupApplicationsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApplicationCubit, ApplicationState>(
      builder: (context, state) {
        final apps = state.receivedApplications;

        if (apps.isEmpty) {
          return _EmptyView(
            icon: Icons.people_outline_rounded,
            title: 'No Applications Yet',
            message: 'Post opportunities to start receiving applications from talented ALU students.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: apps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _StartupApplicationCard(application: apps[index])
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: index * 80)),
        );
      },
    );
  }
}

class _StartupApplicationCard extends StatelessWidget {
  final ApplicationModel application;

  const _StartupApplicationCard({required this.application});

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
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Text(
                  application.applicantName.isNotEmpty
                      ? application.applicantName[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.applicantName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      application.applicantEmail,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                onPressed: () async {
                  final user = context.read<AuthBloc>().state.user;
                  if (user == null) return;

                  final roomId = '${application.applicantId}_${application.startupId}';
                  final room = ChatRoomModel(
                    id: roomId,
                    startupId: application.startupId,
                    startupOwnerId: user.uid,
                    startupName: application.startupName,
                    startupLogoUrl: application.startupLogoUrl,
                    applicantId: application.applicantId,
                    applicantName: application.applicantName,
                    applicantPhotoUrl: application.applicantPhotoUrl,
                    lastMessageTime: DateTime.now(),
                  );

                  final activeRoom = await context.read<ChatCubit>().getOrCreateChatRoom(room);
                  if (context.mounted && activeRoom != null) {
                    context.push('/chat/${activeRoom.id}', extra: activeRoom);
                  }
                },
              ),
              const SizedBox(width: 4),
              _StatusBadge(
                label: _capitalizeFirst(application.status.toString().split('.').last),
                color: _getStatusColor(application.status),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'For: ${application.opportunityTitle}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  application.coverLetter,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Skills
          if (application.relevantSkills.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: application.relevantSkills
                  .take(4)
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 11,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          if (application.status == ApplicationStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Shortlist',
                    color: AppColors.accent,
                    onTap: () => context
                        .read<ApplicationCubit>()
                        .updateApplicationStatus(
                          application.id,
                          ApplicationStatus.shortlisted,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'Accept',
                    color: AppColors.success,
                    onTap: () => context
                        .read<ApplicationCubit>()
                        .updateApplicationStatus(
                          application.id,
                          ApplicationStatus.accepted,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'Reject',
                    color: AppColors.error,
                    onTap: () => context
                        .read<ApplicationCubit>()
                        .updateApplicationStatus(
                          application.id,
                          ApplicationStatus.rejected,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending: return AppColors.warning;
      case ApplicationStatus.reviewing: return AppColors.info;
      case ApplicationStatus.shortlisted: return AppColors.accent;
      case ApplicationStatus.accepted: return AppColors.success;
      case ApplicationStatus.rejected: return AppColors.error;
      case ApplicationStatus.withdrawn: return AppColors.textMuted;
    }
  }

  String _capitalizeFirst(String str) =>
      str.isEmpty ? str : str[0].toUpperCase() + str.substring(1);
}

class _SavedOpportunitiesView extends StatelessWidget {
  final String userId;

  const _SavedOpportunitiesView({required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OpportunityCubit, OpportunityState>(
      builder: (context, state) {
        final saved = state.bookmarkedOpportunities;

        if (saved.isEmpty) {
          return _EmptyView(
            icon: Icons.bookmark_border_rounded,
            title: 'No Saved Opportunities',
            message: 'Bookmark opportunities you\'re interested in to view them here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: saved.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final opp = saved[index];
            return _SavedOpportunityCard(opportunity: opp, userId: userId);
          },
        );
      },
    );
  }
}

class _SavedOpportunityCard extends StatelessWidget {
  final OpportunityModel opportunity;
  final String userId;

  const _SavedOpportunityCard({
    required this.opportunity,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/opportunity/${opportunity.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.business_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opportunity.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${opportunity.startupName} • ${opportunity.type}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context
                  .read<OpportunityCubit>()
                  .toggleBookmark(opportunity.id, userId),
              child: const Icon(Icons.bookmark_rounded,
                  color: AppColors.accent, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyView({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 40, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
