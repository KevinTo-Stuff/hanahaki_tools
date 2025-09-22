// Dart imports:
import 'dart:io';
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:path_provider/path_provider.dart';

// Project imports:
import '../../shared/widgets/map/map.dart';

/// A simple full-screen widget that displays the procedural map.
///
/// Includes a floating action button to "regenerate" the map by
/// changing the `Key` passed to the `MapWidget` which forces
/// the `CustomPaint` to be rebuilt with new procedural data.
class MapDisplay extends StatefulWidget {
  const MapDisplay({super.key});

  @override
  State<MapDisplay> createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  // Controller-based regeneration
  final MapSketchController _controller = MapSketchController();

  // Parameters exposed to the UI
  double _minDist = 40;
  double _maxDist = 80;
  int _tries = 30;

  void _regenerate() {
    // Tell the controller to regenerate procedural data
    _controller.regenerate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final dim = min(constraints.maxWidth, 500.0);
                  return MapSketch(
                    key: ValueKey('${_minDist}_${_maxDist}_$_tries'),
                    controller: _controller,
                    size: dim,
                    minDist: _minDist,
                    maxDist: _maxDist,
                    tries: _tries,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('minDist'),
                      Expanded(
                        child: Slider(
                          value: _minDist,
                          min: 10,
                          max: 200,
                          divisions: 19,
                          label: _minDist.toStringAsFixed(0),
                          onChanged: (v) => setState(() => _minDist = v),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('maxDist'),
                      Expanded(
                        child: Slider(
                          value: _maxDist,
                          min: 10,
                          max: 400,
                          divisions: 39,
                          label: _maxDist.toStringAsFixed(0),
                          onChanged: (v) => setState(() => _maxDist = v),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('tries'),
                      Expanded(
                        child: Slider(
                          value: _tries.toDouble(),
                          min: 1,
                          max: 100,
                          divisions: 99,
                          label: '$_tries',
                          onChanged: (v) => setState(() => _tries = v.toInt()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _regenerate,
              icon: const Icon(Icons.refresh),
              label: const Text('Regenerate'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final bytes = await _controller.capturePng();
                if (bytes == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to capture image')),
                  );
                  return;
                }
                try {
                  final dir = await getTemporaryDirectory();
                  final file = File(
                    '${dir.path}/map_${DateTime.now().millisecondsSinceEpoch}.png',
                  );
                  await file.writeAsBytes(bytes);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved to ${file.path}')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving image: $e')),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
