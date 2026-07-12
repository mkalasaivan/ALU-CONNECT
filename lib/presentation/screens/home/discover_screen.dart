import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/opportunity/opportunity_cubit.dart';
import '../../blocs/startup/startup_cubit.dart';
import '../../../data/models/opportunity_model.dart';
import '../../widgets/cards/opportunity_card.dart';
import '../../blocs/notification/notification_cubit.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  String? _selectedType;
  String? _selectedLocation;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authState = context.read<AuthBloc>().state;
    final opportunityCubit = context.read<OpportunityCubit>();

    opportunityCubit.subscribeToOpportunities();
    if (authState.user != null) {
      opportunityCubit.subscribeToBookmarks(authState.user!.uid);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.isEmpty && _selectedType == null && _selectedLocation == null) {
      context.read<OpportunityCubit>().clearSearch();
    } else {
      context.read<OpportunityCubit>().searchOpportunities(
            query: query.isEmpty ? null : query,
            type: _selectedType,
            location: _selectedLocation,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        final isStartup = user?.isStartup ?? false;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: AppColors.background,
                expandedHeight: 130,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Good ${_greeting()}, ${user?.displayName.split(' ').first ?? 'there'} 👋',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Discover Opportunities',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                            // Notification bell & Avatar
                            BlocBuilder<NotificationCubit, NotificationState>(
                              builder: (context, state) {
                                final unreadCount = state.unreadCount;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.notifications_none_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                      onPressed: () => context.push('/notifications'),
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Center(
                                            child: Text(
                                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.go('/profile'),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary,
                                backgroundImage: user?.photoUrl != null
                                    ? NetworkImage(user!.photoUrl!)
                                    : null,
                                child: user?.photoUrl == null
                                    ? Text(
                                        user?.displayName.isNotEmpty == true
                                            ? user!.displayName[0].toUpperCase()
                                            : 'A',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearch,
                              style: Theme.of(context).textTheme.bodyLarge,
                              decoration: const InputDecoration(
                                hintText: 'Search opportunities...',
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => setState(() => _showFilters = !_showFilters),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _showFilters
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: _showFilters
                                  ? Colors.white
                                  : AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Filter row
              if (_showFilters)
                SliverToBoxAdapter(
                  child: _buildFilterRow(),
                ),

              // Category quick filters
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _selectedType == null,
                        onTap: () {
                          setState(() => _selectedType = null);
                          _onSearch(_searchController.text);
                        },
                      ),
                      ...AppConstants.opportunityTypes.take(6).map(
                            (type) => _FilterChip(
                              label: type,
                              isSelected: _selectedType == type,
                              onTap: () {
                                setState(() => _selectedType =
                                    _selectedType == type ? null : type);
                                _onSearch(_searchController.text);
                              },
                            ),
                          ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Opportunities list
              BlocBuilder<OpportunityCubit, OpportunityState>(
                builder: (context, state) {
                  final opportunities = state.displayedOpportunities;

                  if (state.status == OpportunityStatus2.loading) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ShimmerCard(),
                        childCount: 4,
                      ),
                    );
                  }

                  if (opportunities.isEmpty) {
                    return SliverFillRemaining(
                      child: _EmptyState(isStartup: isStartup),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final opportunity = opportunities[index];
                          final uid = user?.uid ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: OpportunityCard(
                              opportunity: opportunity,
                              isBookmarked: state.bookmarkedOpportunities
                                  .any((o) => o.id == opportunity.id),
                              onBookmark: uid.isNotEmpty
                                  ? () => context
                                      .read<OpportunityCubit>()
                                      .toggleBookmark(opportunity.id, uid)
                                  : null,
                            ).animate().fadeIn(
                                  delay: Duration(milliseconds: index * 80),
                                ),
                          );
                        },
                        childCount: opportunities.length,
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          floatingActionButton: isStartup
              ? FloatingActionButton.extended(
                  onPressed: () => context.push('/opportunity/post'),
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Post Opportunity',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _DropdownFilter(
              hint: 'Location',
              value: _selectedLocation,
              items: ['remote', 'on-campus', 'hybrid'],
              onChanged: (val) {
                setState(() => _selectedLocation = val);
                _onSearch(_searchController.text);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.hint,
    this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          dropdownColor: AppColors.surfaceCard,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          items: [
            const DropdownMenuItem(value: null, child: Text('Any Location')),
            ...items.map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(_capitalizeFirst(item)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _capitalizeFirst(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Shimmer.fromColors(
        baseColor: AppColors.surface,
        highlightColor: AppColors.surfaceLight,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isStartup;

  const _EmptyState({required this.isStartup});

  @override
  Widget build(BuildContext context) {
    return Center(
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
            child: const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No opportunities found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            isStartup
                ? 'Be the first to post an opportunity for ALU students!'
                : 'Check back soon for new opportunities from ALU startups.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
