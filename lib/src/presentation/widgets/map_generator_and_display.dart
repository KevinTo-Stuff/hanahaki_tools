import 'package:flutter/material.dart';

// Import the map implementation
import '../../shared/widgets/map/map.dart';

/// A simple screen that displays the generated map and allows regenerating it.
class MapGeneratorAndDisplay extends StatefulWidget {
  const MapGeneratorAndDisplay({super.key});

  @override
  State<MapGeneratorAndDisplay> createState() => _MapGeneratorState();
}

class _MapGeneratorState extends State<MapGeneratorAndDisplay> {
  // Unique key used to force rebuild of the CustomPaint/map when regenerating
  Key _mapKey = UniqueKey();

  void _regenerate() {
    setState(() {
      _mapKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Constrain the map size to a square container
              Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    // Use the MapWidget from the shared map implementation
                    child: SizedBox(
                      width: 500,
                      height: 500,
                      child: MapWidget(key: _mapKey),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _regenerate,
        tooltip: 'Regenerate map',
        child: const Icon(Icons.shuffle),
      ),
    );
  }
}
