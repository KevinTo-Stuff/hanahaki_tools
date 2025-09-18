// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_route/auto_route.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Project imports:
import 'package:hanahaki_tools/src/core/theme/dimens.dart';
import 'package:hanahaki_tools/src/shared/widgets/buttons/square_button.dart';
import 'package:hanahaki_tools/src/shared/widgets/dice/dice.dart';

@RoutePage()
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String? selectedTool;

  void _onToolSelected(String tool) {
    setState(() {
      selectedTool = tool;
    });
  }

  Widget _buildToolUX(String tool) {
    // Replace with custom UX for each tool
    switch (tool) {
      case 'Social Stat Check':
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Social Stat Check',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 24),
              DiceRollerWidget(initialDieType: DieType.d20),
            ],
          ),
        );
      case 'Damage Calculation':
        return Center(child: Text('Damage Calculation UX'));
      case 'Map Generator':
        return Center(child: Text('Map Generator UX'));
      case 'Ultimate Check':
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Social Stat Check',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 24),
              DiceRollerWidget(initialDieType: DieType.d100),
            ],
          ),
        );
      default:
        return Center(child: Text('Unknown Tool'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (selectedTool != null) {
          setState(() {
            selectedTool = null;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Tools')),
        body: SafeArea(
          child: selectedTool == null
              ? ListView(
                  padding: EdgeInsets.all(Dimens.radius),
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      mainAxisSpacing: Dimens.spacing,
                      crossAxisSpacing: Dimens.spacing,
                      children: [
                        SquareButton.outline(
                          title: 'Social Stat Check',
                          onPressed: () => _onToolSelected('Social Stat Check'),
                          icon: Icon(FontAwesomeIcons.dice, size: 30),
                        ),
                        SquareButton.outline(
                          title: 'Ultimate Check',
                          onPressed: () => _onToolSelected('Ultimate Check'),
                          icon: Icon(FontAwesomeIcons.star, size: 30),
                        ),
                        SquareButton.outline(
                          title: 'Damage Calculation',
                          onPressed: () =>
                              _onToolSelected('Damage Calculation'),
                          icon: Icon(FontAwesomeIcons.calculator, size: 30),
                        ),
                        SquareButton.outline(
                          title: 'Map Generator',
                          onPressed: () => _onToolSelected('Map Generator'),
                          icon: Icon(FontAwesomeIcons.map, size: 30),
                        ),
                      ],
                    ),
                  ],
                )
              : _buildToolUX(selectedTool!),
        ),
      ),
    );
  }
}
