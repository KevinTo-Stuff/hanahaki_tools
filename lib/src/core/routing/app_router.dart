// Package imports:
import 'package:auto_route/auto_route.dart';

// Project imports:
import 'package:hanahaki_tools/src/presentation/screens/battle_simulator_screen.dart';
import 'package:hanahaki_tools/src/presentation/screens/characters_screen.dart';
import 'package:hanahaki_tools/src/presentation/screens/compendium_screen.dart';
import 'package:hanahaki_tools/src/presentation/screens/home_screen.dart';
import 'package:hanahaki_tools/src/presentation/screens/items_screen.dart';
import 'package:hanahaki_tools/src/presentation/screens/settings_screen.dart';
import 'package:hanahaki_tools/src/presentation/screens/skills_screen.dart';
import 'package:hanahaki_tools/src/presentation/screens/tools_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> routes = [
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(page: SettingsRoute.page),
    AutoRoute(page: CharactersRoute.page),
    AutoRoute(page: CompendiumRoute.page),
    AutoRoute(page: SkillsRoute.page),
    AutoRoute(page: ItemsRoute.page),
    AutoRoute(page: ToolsRoute.page),
    AutoRoute(page: BattleSimulatorRoute.page),
  ];
}
