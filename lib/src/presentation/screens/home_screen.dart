// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_route/auto_route.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Project imports:
import 'package:hanahaki_tools/src/core/routing/app_router.dart';
import 'package:hanahaki_tools/src/core/theme/dimens.dart';
import 'package:hanahaki_tools/src/shared/extensions/context_extensions.dart';
import 'package:hanahaki_tools/src/shared/widgets/buttons/button.dart';
import 'package:hanahaki_tools/src/shared/widgets/buttons/square_button.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Dimens.spacing),
          children: [
            const SizedBox(height: Dimens.tripleSpacing),
            Text('Hanahaki Tools', style: context.textTheme.titleLarge),
            const SizedBox(height: Dimens.minSpacing),
            Text(
              'A set of tools designed to be use with the Hanahaki Roleplay',
              style: context.textTheme.bodyMedium,
            ),
            const SizedBox(height: Dimens.spacing),
            Button.outline(
              title: 'Settings',

              onPressed: () {
                context.router.push(const SettingsRoute());
              },
            ),
            const SizedBox(height: Dimens.doubleSpacing),
            // 2x2 grid of SquareButtons.outline
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: Dimens.spacing,
              crossAxisSpacing: Dimens.spacing,
              children: [
                SquareButton.primary(
                  title: 'Characters',
                  onPressed: () {
                    context.router.push(const CharactersRoute());
                  },
                  icon: Icon(
                    FontAwesomeIcons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SquareButton.primary(
                  title: 'Compendium',
                  onPressed: () {
                    context.router.push(const CompendiumRoute());
                  },
                  icon: Icon(
                    FontAwesomeIcons.book,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SquareButton.primary(
                  title: 'Skills',
                  onPressed: () {
                    context.router.push(const SkillsRoute());
                  },
                  icon: Icon(
                    FontAwesomeIcons.wandMagicSparkles,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SquareButton.primary(
                  title: 'Items',
                  onPressed: () {
                    context.router.push(const ItemsRoute());
                  },
                  icon: Icon(
                    FontAwesomeIcons.toolbox,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SquareButton.primary(
                  title: 'Tools',
                  onPressed: () {
                    context.router.push(const ToolsRoute());
                  },
                  icon: Icon(
                    FontAwesomeIcons.screwdriver,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SquareButton.primary(
                  title: 'Battle Simulator',
                  onPressed: () {
                    context.router.push(const BattleSimulatorRoute());
                  },
                  icon: Icon(
                    FontAwesomeIcons.personMilitaryPointing,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
