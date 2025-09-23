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
    return Scaffold(
      body: Center(
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
