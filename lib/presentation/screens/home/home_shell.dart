import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../data/models/user_model.dart';

import '../../blocs/chat/chat_cubit.dart';
import '../../blocs/startup/startup_cubit.dart';
import '../../blocs/notification/notification_cubit.dart';

class HomeShell extends StatefulWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSubscriptions();
    });
  }

  void _initSubscriptions() {
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      if (user.isStudent) {
        context.read<ChatCubit>().subscribeToChatRooms(user.uid, false);
        context.read<NotificationCubit>().subscribeToNotifications(user.uid);
      } else if (user.isStartup) {
        final startup = context.read<StartupCubit>().state.currentUserStartup;
        if (startup != null) {
          context.read<ChatCubit>().subscribeToChatRooms(startup.id, true);
          context.read<NotificationCubit>().subscribeToNotifications(user.uid);
        }
      }
    }
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/dashboard')) return 1;
    if (location.startsWith('/applications')) return 2;
    if (location.startsWith('/chats')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            _initSubscriptions();
          },
        ),
        BlocListener<StartupCubit, StartupState>(
          listener: (context, startupState) {
            _initSubscriptions();
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState.user;
          final isStartup = user?.isStartup ?? false;

          final selectedIndex = _getSelectedIndex(context);

          // Calculate total unread messages
          int unreadChatsCount = 0;
          final chatState = context.watch<ChatCubit>().state;
          if (user != null) {
            for (final room in chatState.chatRooms) {
              unreadChatsCount += room.unreadCounts[user.uid] ?? 0;
            }
          }

          return Scaffold(
            body: widget.child,
            bottomNavigationBar: _BottomNav(
              selectedIndex: selectedIndex,
              isStartup: isStartup,
              unreadChatsCount: unreadChatsCount,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/home');
                    break;
                  case 1:
                    context.go('/dashboard');
                    break;
                  case 2:
                    context.go('/applications');
                    break;
                  case 3:
                    context.go('/chats');
                    break;
                  case 4:
                    context.go('/profile');
                    break;
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final bool isStartup;
  final int unreadChatsCount;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.isStartup,
    required this.unreadChatsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: 'Discover',
                isSelected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: isStartup ? 'Manage' : 'Dashboard',
                isSelected: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment_rounded,
                label: isStartup ? 'Applicants' : 'My Apps',
                isSelected: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Chats',
                isSelected: selectedIndex == 3,
                badgeCount: unreadChatsCount,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isSelected: selectedIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
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
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
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
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
