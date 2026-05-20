import 'package:flutter/material.dart';
import 'package:spotlight/app/app_constants.dart';
import 'package:spotlight/widgets/ui_components.dart';

class MobileHeader extends StatelessWidget {
  const MobileHeader({
    super.key,
    required this.darkMode,
    required this.onProfile,
    required this.profileActive,
  });

  final bool darkMode;
  final VoidCallback onProfile;
  final bool profileActive;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: darkMode ? const Color(0xEE09090B) : const Color(0xEEFFFFFF),
          border: Border(
            bottom: BorderSide(
              color: darkMode
                  ? const Color(0xFF18181B)
                  : const Color(0xFFE4E4E7),
            ),
          ),
        ),
        child: Row(
          children: [
            SpotlightLogo(darkMode: darkMode, size: 30),
            const SizedBox(width: 10),
            Text(
              'Spotlight',
              style: TextStyle(
                color: darkMode ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onProfile,
              style: IconButton.styleFrom(
                backgroundColor: profileActive
                    ? (darkMode
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE4E4E7))
                    : Colors.transparent,
              ),
              icon: Icon(
                Icons.person_outline,
                size: 20,
                color: darkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.darkMode,
    required this.activeTab,
    required this.onTab,
    required this.onProfile,
  });

  final bool darkMode;
  final AppTab activeTab;
  final ValueChanged<AppTab> onTab;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: darkMode ? const Color(0xFF09090B) : Colors.white,
        border: Border(
          right: BorderSide(
            color: darkMode ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                SpotlightLogo(darkMode: darkMode, size: 34),
                const SizedBox(width: 12),
                const Text(
                  'Spotlight',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          NavButton(
            icon: Icons.tv,
            label: 'Início',
            active: activeTab == AppTab.hub,
            darkMode: darkMode,
            onTap: () => onTab(AppTab.hub),
            desktop: true,
          ),
          NavButton(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            active: activeTab == AppTab.chat,
            darkMode: darkMode,
            onTap: () => onTab(AppTab.chat),
            desktop: true,
          ),
          NavButton(
            icon: Icons.bookmark_border,
            label: 'Lista',
            active: activeTab == AppTab.list,
            darkMode: darkMode,
            onTap: () => onTab(AppTab.list),
            desktop: true,
          ),
          NavButton(
            icon: Icons.search,
            label: 'Buscar',
            active: activeTab == AppTab.search,
            darkMode: darkMode,
            onTap: () => onTab(AppTab.search),
            desktop: true,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: IconButton(
              onPressed: onProfile,
              style: IconButton.styleFrom(
                minimumSize: const Size(220, 50),
                backgroundColor: activeTab == AppTab.profile
                    ? (darkMode
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE4E4E7))
                    : Colors.transparent,
              ),
              icon: Icon(
                Icons.person_outline,
                color: darkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({
    super.key,
    required this.darkMode,
    required this.activeTab,
    required this.onTab,
    required this.bottomInset,
  });

  final bool darkMode;
  final AppTab activeTab;
  final ValueChanged<AppTab> onTab;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 86 + bottomInset,
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 6,
          bottom: 14 + bottomInset,
        ),
        decoration: BoxDecoration(
          color: darkMode ? const Color(0xF209090B) : const Color(0xF2FFFFFF),
          border: Border(
            top: BorderSide(
              color: darkMode
                  ? const Color(0xFF18181B)
                  : const Color(0xFFE4E4E7),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            NavButton(
              icon: Icons.tv,
              label: 'Início',
              active: activeTab == AppTab.hub,
              darkMode: darkMode,
              onTap: () => onTab(AppTab.hub),
              desktop: false,
            ),
            NavButton(
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              active: activeTab == AppTab.chat,
              darkMode: darkMode,
              onTap: () => onTab(AppTab.chat),
              desktop: false,
            ),
            NavButton(
              icon: Icons.bookmark_border,
              label: 'Lista',
              active: activeTab == AppTab.list,
              darkMode: darkMode,
              onTap: () => onTab(AppTab.list),
              desktop: false,
            ),
            NavButton(
              icon: Icons.search,
              label: 'Buscar',
              active: activeTab == AppTab.search,
              darkMode: darkMode,
              onTap: () => onTab(AppTab.search),
              desktop: false,
            ),
          ],
        ),
      ),
    );
  }
}

class NavButton extends StatelessWidget {
  const NavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.darkMode,
    required this.onTap,
    required this.desktop,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool darkMode;
  final VoidCallback onTap;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final activeColor = darkMode ? Colors.white : Colors.black;
    final inactiveColor = darkMode
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: desktop ? double.infinity : 76,
        margin: desktop
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 2)
            : null,
        padding: EdgeInsets.symmetric(
          horizontal: desktop ? 14 : 0,
          vertical: desktop ? 12 : 4,
        ),
        decoration: BoxDecoration(
          color: active && desktop
              ? (darkMode ? const Color(0xFF27272A) : const Color(0xFFE4E4E7))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: desktop
            ? Row(
                children: [
                  Icon(
                    icon,
                    color: active ? activeColor : inactiveColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: active ? activeColor : inactiveColor,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: active ? activeColor : inactiveColor,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: active ? activeColor : inactiveColor,
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
