// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:hanahaki_tools/src/shared/widgets/map/map.dart';

class MapDisplay extends StatefulWidget {
  const MapDisplay({super.key});

  @override
  State<MapDisplay> createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  int _seed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

  void _regenerate() {
    setState(() {
      _seed = Random().nextInt(1 << 31);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = min(500.0, MediaQuery.of(context).size.width);
    final seedColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _regenerate,
            child: CustomPaint(
              size: Size(size, size),
              painter: MapPainter(canvasSize: size, seed: _seed),
            ),
          ),
          const SizedBox(height: 12),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _regenerate,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
