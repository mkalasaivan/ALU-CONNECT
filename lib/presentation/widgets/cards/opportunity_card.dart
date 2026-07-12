import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../../data/models/opportunity_model.dart';

class OpportunityCard extends StatelessWidget {
  final OpportunityModel opportunity;
  final bool isBookmarked;
  final VoidCallback? onBookmark;
  final bool compact;

  const OpportunityCard({
    super.key,
    required this.opportunity,
    this.isBookmarked = false,
    this.onBookmark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/opportunity/${opportunity.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Startup logo
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: opportunity.startupLogoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            opportunity.startupLogoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.business_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.business_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              opportunity.startupName,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (opportunity.startupIsVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              color: AppColors.secondary,
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        timeago.format(opportunity.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (onBookmark != null)
                  GestureDetector(
                    onTap: onBookmark,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        key: ValueKey(isBookmarked),
                        color: isBookmarked ? AppColors.accent : AppColors.textMuted,
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              opportunity.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            if (!compact) ...[
              Text(
                opportunity.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],

            // Tags row
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _InfoChip(
                  icon: Icons.work_outline_rounded,
                  label: opportunity.type,
                  color: AppColors.primary,
                ),
                _InfoChip(
                  icon: Icons.location_on_outlined,
                  label: _capitalizeFirst(opportunity.location),
                  color: AppColors.secondary,
                ),
                _InfoChip(
                  icon: Icons.access_time_rounded,
                  label: opportunity.duration,
                  color: AppColors.textMuted,
                ),
                if (opportunity.isPaid)
                  _InfoChip(
                    icon: Icons.payments_outlined,
                    label: opportunity.stipend ?? 'Paid',
                    color: AppColors.success,
                  ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Footer
            Row(
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${opportunity.applicantCount} applicants',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (opportunity.deadline != null)
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: opportunity.isExpired
                            ? AppColors.error
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        opportunity.isExpired
                            ? 'Expired'
                            : 'Due ${timeago.format(opportunity.deadline!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: opportunity.isExpired
                                  ? AppColors.error
                                  : AppColors.warning,
                            ),
                      ),
                    ],
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'View',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizeFirst(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
