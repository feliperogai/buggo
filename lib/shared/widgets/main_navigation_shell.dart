import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class MainNavigationShell extends StatelessWidget {
  final Widget child;
  final String location;

  const MainNavigationShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: _MainBottomNavigation(location: location),
    );
  }
}

class _MainBottomNavigation extends StatelessWidget {
  final String location;

  const _MainBottomNavigation({required this.location});

  static const _items = [
    _NavigationItem(
      route: '/home',
      semanticLabel: 'Inicio',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavigationItem(
      route: '/trophy',
      semanticLabel: 'Trofeu',
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events_rounded,
    ),
    _NavigationItem(
      route: '/market',
      semanticLabel: 'Market',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront_rounded,
    ),
    _NavigationItem(
      route: '/profile',
      semanticLabel: 'Perfil',
      icon: Icons.person_rounded,
      selectedIcon: Icons.person,
    ),
  ];

  int get _selectedIndex {
    if (location.startsWith('/profile') || location.startsWith('/settings')) {
      return 3;
    }
    if (location.startsWith('/trophy')) return 1;
    if (location.startsWith('/market')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var index = 0; index < _items.length; index++)
                _NavIconButton(
                  item: _items[index],
                  isSelected: index == selectedIndex,
                  onTap: () {
                    final item = _items[index];
                    if (location == item.route) return;
                    context.go(item.route);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final _NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavIconButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.semanticLabel,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: item.semanticLabel,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: isSelected ? 48 : 42,
                height: isSelected ? 48 : 42,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.32),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  size: isSelected ? 25 : 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem {
  final String route;
  final String semanticLabel;
  final IconData icon;
  final IconData selectedIcon;

  const _NavigationItem({
    required this.route,
    required this.semanticLabel,
    required this.icon,
    required this.selectedIcon,
  });
}
