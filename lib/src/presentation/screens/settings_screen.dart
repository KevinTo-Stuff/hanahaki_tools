// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:hanahaki_tools/src/core/settings/settings_cubit.dart';
import 'package:hanahaki_tools/src/core/settings/settings_state.dart';
import 'package:hanahaki_tools/src/core/theme/dimens.dart';
import 'package:hanahaki_tools/src/shared/widgets/buttons/button.dart';

@RoutePage()
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(Dimens.radius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: state.isDarkMode,
                  onChanged: (value) {
                    context.read<SettingsCubit>().toggleDarkMode();
                  },
                ),
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  value: state.notificationsEnabled,
                  onChanged: (value) {
                    context.read<SettingsCubit>().setNotificationsEnabled(
                      value,
                    );
                  },
                ),
                const Spacer(),
                Button.primary(
                  title: 'Save',
                  onPressed: () {
                    // TODO: Implement save logic if needed
                    context.router.pop();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
