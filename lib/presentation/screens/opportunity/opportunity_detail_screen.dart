import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/opportunity/opportunity_cubit.dart';
import '../../blocs/application/application_cubit.dart';
import '../../../data/models/opportunity_model.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/chat_room_model.dart';
import '../../../data/repositories/opportunity_repository.dart';
import '../../../data/repositories/startup_repository.dart';
import '../../widgets/common/gradient_button.dart';
import '../../blocs/chat/chat_cubit.dart';

class OpportunityDetailScreen extends StatefulWidget {
  final String opportunityId;

  const OpportunityDetailScreen({super.key, required this.opportunityId});

  @override
  State<OpportunityDetailScreen> createState() =>
      _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  OpportunityModel? _opportunity;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOpportunity();
  }

  Future<void> _loadOpportunity() async {
    final repo = context.read<OpportunityRepository>();
    final opp = await repo.getOpportunityById(widget.opportunityId);
    if (mounted) {
      setState(() {
        _opportunity = opp;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _opportunity == null
                  ? Center(
                      child: Text('Opportunity not found',
                          style: Theme.of(context).textTheme.bodyLarge))
                  : CustomScrollView(
                      slivers: [
                        // Custom header
                        SliverAppBar(
                          expandedHeight: 200,
                          pinned: true,
                          backgroundColor: AppColors.background,
                          leading: GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  size: 20),
                            ),
                          ),
                          actions: [
                            BlocBuilder<OpportunityCubit, OpportunityState>(
                              builder: (context, state) {
                                final isBookmarked = state.bookmarkedOpportunities
                                    .any((o) => o.id == _opportunity!.id);
                                return GestureDetector(
                                  onTap: user != null
                                      ? () => context
                                          .read<OpportunityCubit>()
                                          .toggleBookmark(
                                              _opportunity!.id, user.uid)
                                      : null,
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isBookmarked
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      color: isBookmarked
                                          ? AppColors.accent
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                          flexibleSpace: FlexibleSpaceBar(
                            background: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryDark,
                                    AppColors.surface,
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        // Startup logo
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            gradient: AppColors.primaryGradient,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: const Icon(Icons.business_rounded,
                                              color: Colors.white, size: 28),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    _opportunity!.startupName,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium,
                                                  ),
                                                  if (_opportunity!
                                                      .startupIsVerified) ...[
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.verified_rounded,
                                                      color: AppColors.secondary,
                                                      size: 16,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Text(
                                                'Posted ${timeago.format(_opportunity!.createdAt)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _opportunity!.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ).animate().fadeIn(),

                                const SizedBox(height: 16),

                                // Info chips
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _InfoBadge(
                                      icon: Icons.work_outline_rounded,
                                      label: _opportunity!.type,
                                      color: AppColors.primary,
                                    ),
                                    _InfoBadge(
                                      icon: Icons.location_on_outlined,
                                      label: _capitalizeFirst(
                                          _opportunity!.location),
                                      color: AppColors.secondary,
                                    ),
                                    _InfoBadge(
                                      icon: Icons.access_time_rounded,
                                      label: _opportunity!.duration,
                                      color: AppColors.accent,
                                    ),
                                    _InfoBadge(
                                      icon: Icons.group_outlined,
                                      label:
                                          '${_opportunity!.openings} opening${_opportunity!.openings > 1 ? 's' : ''}',
                                      color: AppColors.info,
                                    ),
                                    if (_opportunity!.isPaid)
                                      _InfoBadge(
                                        icon: Icons.payments_outlined,
                                        label: _opportunity!.stipend ?? 'Paid',
                                        color: AppColors.success,
                                      ),
                                  ],
                                ).animate().fadeIn(delay: 100.ms),

                                const SizedBox(height: 28),

                                // About section
                                _SectionTitle('About This Role'),
                                const SizedBox(height: 12),
                                Text(
                                  _opportunity!.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(height: 1.7),
                                ).animate().fadeIn(delay: 200.ms),

                                // Responsibilities
                                if (_opportunity!.responsibilities.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  _SectionTitle('What You\'ll Do'),
                                  const SizedBox(height: 12),
                                  ..._opportunity!.responsibilities.map(
                                    (r) => _BulletPoint(text: r),
                                  ),
                                ],

                                // Requirements
                                if (_opportunity!.requirements.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  _SectionTitle('Requirements'),
                                  const SizedBox(height: 12),
                                  ..._opportunity!.requirements.map(
                                    (r) => _BulletPoint(text: r),
                                  ),
                                ],

                                // Skills
                                if (_opportunity!.requiredSkills.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  _SectionTitle('Required Skills'),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _opportunity!.requiredSkills
                                        .map(
                                          (skill) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppColors.primary
                                                    .withOpacity(0.4),
                                              ),
                                            ),
                                            child: Text(
                                              skill,
                                              style: const TextStyle(
                                                color: AppColors.primaryLight,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],

                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
          bottomNavigationBar: _opportunity == null || _isLoading || user == null
              ? null
              : BlocBuilder<ApplicationCubit, ApplicationState>(
                  builder: (context, appState) {
                    final myApps = appState.myApplications;
                    final activeApplications = myApps.where((a) =>
                        a.opportunityId == _opportunity!.id &&
                        a.status != ApplicationStatus.rejected &&
                        a.status != ApplicationStatus.withdrawn);
                    final activeApp = activeApplications.isNotEmpty
                        ? activeApplications.first
                        : null;

                    return _ApplyBar(
                      opportunity: _opportunity!,
                      userId: user.uid,
                      isStartup: user.isStartup,
                      startupOwnerId: _opportunity!.startupId,
                      activeApplication: activeApp,
                    );
                  },
                ),
        );
      },
    );
  }

  String _capitalizeFirst(String str) =>
      str.isEmpty ? str : str[0].toUpperCase() + str.substring(1);
}

class _ApplyBar extends StatelessWidget {
  final OpportunityModel opportunity;
  final String userId;
  final bool isStartup;
  final String startupOwnerId;
  final ApplicationModel? activeApplication;

  const _ApplyBar({
    required this.opportunity,
    required this.userId,
    required this.isStartup,
    required this.startupOwnerId,
    this.activeApplication,
  });

  @override
  Widget build(BuildContext context) {
    // Startups shouldn't apply to opportunities
    if (isStartup) {
      return const SizedBox();
    }

    final hasApplied = activeApplication != null;
    final buttonLabel = opportunity.isExpired
        ? 'Closed'
        : hasApplied
            ? 'Applied (${_capitalizeFirst(activeApplication!.status.toString().split('.').last)})'
            : 'Apply Now';

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${opportunity.applicantCount} applicants',
                  style: Theme.of(context).textTheme.bodySmall),
              if (opportunity.deadline != null)
                Text(
                  'Deadline: ${_formatDate(opportunity.deadline!)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.warning,
                      ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () async {
              final user = context.read<AuthBloc>().state.user;
              if (user == null) return;

              final startupRepo = context.read<StartupRepository>();
              final startup = await startupRepo.getStartupById(opportunity.startupId);
              final ownerId = startup?.ownerId ?? opportunity.startupId;

              final roomId = '${user.uid}_${opportunity.startupId}';
              final room = ChatRoomModel(
                id: roomId,
                startupId: opportunity.startupId,
                startupOwnerId: ownerId,
                startupName: opportunity.startupName,
                startupLogoUrl: opportunity.startupLogoUrl,
                applicantId: user.uid,
                applicantName: user.displayName,
                applicantPhotoUrl: user.photoUrl,
                lastMessageTime: DateTime.now(),
              );

              if (context.mounted) {
                final activeRoom = await context.read<ChatCubit>().getOrCreateChatRoom(room);
                if (context.mounted && activeRoom != null) {
                  context.push('/chat/${activeRoom.id}', extra: activeRoom);
                }
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GradientButton(
              label: buttonLabel,
              onTap: (opportunity.isExpired || hasApplied)
                  ? () {}
                  : () => context.push('/opportunity/${opportunity.id}/apply'),
              colors: (opportunity.isExpired || hasApplied)
                  ? [AppColors.textMuted, AppColors.textMuted]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _capitalizeFirst(String str) {
    return str.isEmpty ? str : str[0].toUpperCase() + str.substring(1);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
