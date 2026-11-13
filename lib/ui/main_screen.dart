import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:movies/state/main_nav_index.dart';
import 'package:movies/ui/menus.dart';
import 'package:movies/ui/screens/favorites/favorite_screen.dart';
import 'package:movies/ui/screens/genres/genre_screen.dart';
import 'package:movies/ui/screens/genres/search_dialog.dart';
import 'package:movies/ui/screens/home/home_screen.dart';
import 'package:movies/ui/screens/source_sheet/source_rules_dialog.dart';
import 'package:movies/ui/theme/theme.dart';

/// 主框架：AdaptiveLayout 三槽位
/// primaryNavigation — 中大屏左侧 NavigationRail
/// body — 当前页面
/// bottomNavigation — 小屏底部导航
@RoutePage(name: 'MainRoute')
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  /// 缓存页面，避免切换时反复重建
  late final List<Widget> _screens = const [
    HomeScreen(),
    GenreScreen(),
    FavoriteScreen(),
  ];

  static const _navDestinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Symbols.genres), label: 'Genre'),
    NavigationDestination(icon: Icon(Icons.favorite), label: 'Favorites'),
  ];

  static const _railDestinations = <NavigationRailDestination>[
    NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
    NavigationRailDestination(icon: Icon(Icons.tag), label: Text('Genre')),
    NavigationRailDestination(
      icon: Icon(Icons.favorite),
      label: Text('Favorites'),
    ),
  ];

  void _onNavSelected(int navIndex) {
    ref.read(currentNavIndexProvider.notifier).goTo(navIndex);
  }

  Future<void> _onMenuSelected(AppMenuAction action) async {
    switch (action) {
      case AppMenuAction.search:
        await showDialog<void>(
          context: context,
          builder: (_) => const SearchDialog(),
        );
        break;
      case AppMenuAction.home:
        ref.read(currentNavIndexProvider.notifier).goTo(0);
        break;
      case AppMenuAction.genres:
        ref.read(currentNavIndexProvider.notifier).goTo(1);
        break;
      case AppMenuAction.favorites:
        ref.read(currentNavIndexProvider.notifier).goTo(2);
        break;
      case AppMenuAction.sources:
        await showSourceRulesDialog(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 当前导航下标
    final currentIndex = ref.watch(currentNavIndexProvider);
    return Scaffold(
      backgroundColor: ArchiveTone.of(context).pageEnd,
      body: AdaptiveLayout(
        // 左侧导航轨：中屏及以上
        primaryNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.medium: SlotLayout.from(
              key: const Key('primaryNavigation'),
              builder: (_) => AdaptiveScaffold.standardNavigationRail(
                destinations: _railDestinations,
                selectedIndex: currentIndex,
                onDestinationSelected: _onNavSelected,
              ),
            ),
            // mediumLargeAndUp 覆盖 840 及以上所有宽度（含 large/extraLarge）
            Breakpoints.mediumLargeAndUp: SlotLayout.from(
              key: const Key('primaryNavigationLarge'),
              builder: (_) => AdaptiveScaffold.standardNavigationRail(
                extended: true,
                destinations: _railDestinations,
                selectedIndex: currentIndex,
                onDestinationSelected: _onNavSelected,
              ),
            ),
          },
        ),
        // 正文：当前页面（smallAndUp 无上限，覆盖所有宽度）
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.smallAndUp: SlotLayout.from(
              key: const Key('body'),
              builder: (_) => Stack(
                children: [
                  _screens[currentIndex],
                  // 应用菜单：搜索 / 页面跳转
                  Positioned(
                    top: 14,
                    right: 20,
                    child: PopupMenuButton<AppMenuAction>(
                      tooltip: 'Menu',
                      icon: const Icon(Icons.more_horiz),
                      iconColor: ArchiveTone.of(context).ink,
                      onSelected: _onMenuSelected,
                      itemBuilder: (_) => buildAppMenuItems(),
                    ),
                  ),
                ],
              ),
            ),
          },
        ),
        // 底部导航：仅小屏
        bottomNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.small: SlotLayout.from(
              key: const Key('bottomNavigation'),
              builder: (_) => AdaptiveScaffold.standardBottomNavigationBar(
                destinations: _navDestinations,
                currentIndex: currentIndex,
                onDestinationSelected: _onNavSelected,
              ),
            ),
          },
        ),
      ),
    );
  }
}
