// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:hanahaki_tools/src/shared/services/map/map.dart';
import 'package:hanahaki_tools/src/shared/widgets/buttons/button.dart';

class MapDisplay extends StatefulWidget {
  const MapDisplay({super.key});

  @override
  State<MapDisplay> createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  int _seed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  // config state
  final Set<PointType> _enabled = PointType.values.toSet();
  double _nodes = 120;
  double _paths = 3;

  void _regenerate() {
    setState(() {
      _seed = Random().nextInt(1 << 31);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canvasSize = min(500.0, MediaQuery.of(context).size.width);
    final seedColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70;
    // final size = min(500.0, MediaQuery.of(context).size.width);
    final mapConfig = MapConfig(
      enabledTypes: _enabled,
      targetNodes: _nodes.toInt(),
      branchingPaths: _paths.toInt(),
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _regenerate,
              child: CustomPaint(
                size: Size(canvasSize, canvasSize),
                painter: MapPainter(
                  canvasSize: canvasSize,
                  seed: _seed,
                  config: mapConfig,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Controls: put filter chips on their own row above other options
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final t in PointType.values)
                      FilterChip(
                        label: Text(t.toString().split('.').last),
                        selected: _enabled.contains(t),
                        onSelected: (v) => setState(
                          () => v ? _enabled.add(t) : _enabled.remove(t),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 220,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Nodes: ${_nodes.toInt()}'),
                        Slider(
                          min: 40,
                          max: 240,
                          divisions: 20,
                          value: _nodes,
                          onChanged: (v) => setState(() => _nodes = v),
                        ),
                        Text('Paths: ${_paths.toInt()}'),
                        Slider(
                          min: 1,
                          max: 8,
                          divisions: 7,
                          value: _paths,
                          onChanged: (v) => setState(() => _paths = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Seed: ',
                    style: TextStyle(fontSize: 12, color: seedColor),
                  ),
                  const SizedBox(width: 6),
                  SelectableText(
                    '$_seed',
                    style: TextStyle(
                      fontSize: 12,
                      color: seedColor,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Button.outline(
                    title: 'Refresh',
                    onPressed: _regenerate,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Button.outline(
                    title: 'Load from Seed',
                    onPressed: () => _askForSeed(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _askForSeed(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Load from Seed'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter numeric seed'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                final value = int.tryParse(text);
                Navigator.of(ctx).pop(value);
              },
              child: const Text('Load'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _seed = result;
      });
    }
  }
}