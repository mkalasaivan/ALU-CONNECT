import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/startup_model.dart';
import '../../blocs/startup/startup_cubit.dart';

class StartupProfileScreen extends StatelessWidget {
  const StartupProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StartupCubit, StartupState>(
      builder: (context, state) {
        final startup = state.currentUserStartup;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Startup Profile'),
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
          ),
          body: startup == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.business_outlined,
                          size: 60, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      const Text('No startup profile found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/startup/create'),
                        child: const Text('Create Startup Profile'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Startup header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: AppColors.tealGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.rocket_launch_rounded,
                                color: Colors.white, size: 44),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            startup.name,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            startup.tagline,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),

                          // Verification badge
                          _VerificationBadge(status: startup.verificationStatus),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Info section
                    _InfoRow(
                      icon: Icons.category_rounded,
                      label: 'Category',
                      value: startup.category,
                    ),
                    _InfoRow(
                      icon: Icons.location_city_rounded,
                      label: 'Campus',
                      value: startup.campus,
                    ),
                    _InfoRow(
                      icon: Icons.timeline_rounded,
                      label: 'Stage',
                      value: _capitalizeFirst(startup.stage),
                    ),
                    if (startup.aluProgramName != null)
                      _InfoRow(
                        icon: Icons.school_rounded,
                        label: 'ALU Program',
                        value: startup.aluProgramName!,
                      ),

                    const SizedBox(height: 24),

                    Text('About', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      startup.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(height: 1.6),
                    ),

                    if (startup.tags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Tags', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: startup.tags
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color:
                                            AppColors.secondary.withOpacity(0.3)),
                                  ),
                                  child: Text(tag,
                                      style: const TextStyle(
                                          color: AppColors.secondary,
                                          fontSize: 12)),
                                ))
                            .toList(),
                      ),
                    ],

                    if (startup.verificationStatus ==
                        VerificationStatus.rejected) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.cancel_rounded,
                                    color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Text('Not Approved',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: AppColors.error)),
                              ],
                            ),
                            if (startup.verificationNote != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                startup.verificationNote!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.error),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
        );
      },
    );
  }

  String _capitalizeFirst(String str) =>
      str.isEmpty ? str : str[0].toUpperCase() + str.substring(1);
}

class _VerificationBadge extends StatelessWidget {
  final VerificationStatus status;

  const _VerificationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isVerified = status == VerificationStatus.verified;
    final isPending = status == VerificationStatus.pending;
    final color = isVerified
        ? AppColors.success
        : isPending
            ? AppColors.warning
            : AppColors.error;
    final icon = isVerified
        ? Icons.verified_rounded
        : isPending
            ? Icons.pending_rounded
            : Icons.cancel_rounded;
    final label = isVerified
        ? 'ALU Verified'
        : isPending
            ? 'Awaiting Review'
            : 'Not Approved';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
