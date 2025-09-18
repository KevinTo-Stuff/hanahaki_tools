// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Placeholder for Poisson Disk Sampling, Delaunay, and pathfinding
// You need to implement or use packages for these
List<List<double>> poissonDiskSampling(
  Size size,
  double minDist,
  double maxDist,
  int tries,
  List<List<double>> initialPoints,
) {
  final points = <List<double>>[];
  final rng = Random();
  final cellSize = minDist / sqrt(2);
  final gridWidth = (size.width / cellSize).ceil();
  final gridHeight = (size.height / cellSize).ceil();
  final grid = List.generate(gridWidth * gridHeight, (_) => -1);

  List<int> gridIndex(List<double> p) => [
    (p[0] / cellSize).floor(),
    (p[1] / cellSize).floor(),
  ];

  bool isValid(List<double> p) {
    if (p[0] < 0 || p[0] >= size.width || p[1] < 0 || p[1] >= size.height) {
      return false;
    }
    final gi = gridIndex(p);
    for (int i = max(gi[0] - 2, 0); i <= min(gi[0] + 2, gridWidth - 1); i++) {
      for (
        int j = max(gi[1] - 2, 0);
        j <= min(gi[1] + 2, gridHeight - 1);
        j++
      ) {
        final idx = i + j * gridWidth;
        final ptIdx = grid[idx];
        if (ptIdx != -1) {
          final pt = points[ptIdx];
          final dx = pt[0] - p[0];
          final dy = pt[1] - p[1];
          if (sqrt(dx * dx + dy * dy) < minDist) return false;
        }
      }
    }
    return true;
  }

  final processList = <List<double>>[];

  for (final p in initialPoints) {
    points.add(p);
    final gi = gridIndex(p);
    grid[gi[0] + gi[1] * gridWidth] = points.length - 1;
    processList.add(p);
  }

  if (points.isEmpty) {
    final p = [rng.nextDouble() * size.width, rng.nextDouble() * size.height];
    points.add(p);
    final gi = gridIndex(p);
    grid[gi[0] + gi[1] * gridWidth] = 0;
    processList.add(p);
  }

  while (processList.isNotEmpty) {
    final idx = rng.nextInt(processList.length);
    final point = processList[idx];
    bool found = false;
    for (int t = 0; t < tries; t++) {
      final angle = rng.nextDouble() * 2 * pi;
      final radius = minDist + rng.nextDouble() * (maxDist - minDist);
      final newPoint = [
        point[0] + cos(angle) * radius,
        point[1] + sin(angle) * radius,
      ];
      if (isValid(newPoint)) {
        points.add(newPoint);
        final gi = gridIndex(newPoint);
        grid[gi[0] + gi[1] * gridWidth] = points.length - 1;
        processList.add(newPoint);
        found = true;
        break;
      }
    }
    if (!found) {
      processList.removeAt(idx);
    }
  }

  return points;
}

List<List<List<double>>> delaunayTriangles(List<List<double>> points) {
  // Implement or use a package
  return [];
}

List<List<double>> aStarPath(
  MapGraph graph,
  List<double> start,
  List<double> end,
) {
  // Implement or use a package
  return [];
}

class MapGraph {
  // Implement graph structure and methods
  void addLink(List<double> a, List<double> b, double weight) {}
  void removeNode(List<double> node) {}
}

class MapPainter extends CustomPainter {
  final double canvasSize;
  final List<List<double>> points;
  final List<List<List<double>>> triangles;
  final List<List<double>> startPoint;
  final List<List<double>> endPoint;
  final MapGraph graph;

  MapPainter({
    required this.canvasSize,
    required this.points,
    required this.triangles,
    required this.startPoint,
    required this.endPoint,
    required this.graph,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Background
    paint.color = Color.fromARGB(255, 40, 50, 60);
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasSize, canvasSize), paint);

    // Border
    paint
      ..color = Color.fromARGB(255, 40, 80, 20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasSize, canvasSize), paint);

    // Translate for drawing
    canvas.save();
    canvas.translate(canvasSize * 0.05, canvasSize * 0.05);

    // Pathfinding and drawing arrows
    List<List<double>> activePoints = [];
    for (int i = 0; i < canvasSize / 50; i++) {
      final foundPath = aStarPath(graph, startPoint[0], endPoint[0]);
      if (foundPath.isEmpty) break;
      activePoints.addAll(foundPath);

      for (int j = 1; j < foundPath.length; j++) {
        drawArrow(canvas, foundPath[j], foundPath[j - 1]);
      }

      // Remove a random node from the path
      if (foundPath.length > 2) {
        final idx = Random().nextInt(foundPath.length - 2) + 1;
        graph.removeNode(foundPath[idx]);
      }
    }

    // Draw points
    for (final p in activePoints.toSet()) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: p == startPoint[0]
              ? "😀"
              : p == endPoint[0]
              ? "😈"
              : ["💀", "💰", "❓"][Random().nextInt(3)],
          style: TextStyle(fontSize: 16),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(p[0], p[1]));
    }

    canvas.restore();

    // Overlay
    paint
      ..color = Color.fromARGB(77, 40, 50, 60)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasSize, canvasSize), paint);
  }

  void drawArrow(
    Canvas canvas,
    List<double> from,
    List<double> to, {
    double arrowSize = 6,
  }) {
    final dx = to[0] - from[0];
    final dy = to[1] - from[1];
    final len = sqrt(dx * dx + dy * dy);
    final angle = atan2(dy, dx);

    canvas.save();
    canvas.translate(from[0], from[1]);
    canvas.rotate(angle);

    // Dotted line
    drawDottedLine(canvas, 0, 0, len - 10, 0);

    // Arrowhead
    final path = Path();
    path.moveTo(len - arrowSize, arrowSize / 2);
    path.lineTo(len - arrowSize, -arrowSize / 2);
    path.lineTo(len, 0);
    path.close();
    final paint = Paint()..color = Colors.black;
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  void drawDottedLine(
    Canvas canvas,
    double x1,
    double y1,
    double x2,
    double y2, {
    double fragment = 5,
  }) {
    final len = sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
    final dx = (x2 - x1) / len;
    final dy = (y2 - y1) / len;
    for (double i = 0; i < len; i += fragment * 2) {
      canvas.drawLine(
        Offset(x1 + dx * i, y1 + dy * i),
        Offset(x1 + dx * (i + fragment), y1 + dy * (i + fragment)),
        Paint()..color = Colors.black,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Usage in a Flutter widget
class MapWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // You need to initialize points, triangles, graph, startPoint, endPoint
    return CustomPaint(
      size: Size(500, 500),
      painter: MapPainter(
        canvasSize: 500,
        points: [], // Fill with Poisson Disk points
        triangles: [], // Fill with Delaunay triangles
        startPoint: [
          [225, 450],
        ],
        endPoint: [
          [225, 0],
        ],
        graph: MapGraph(),
      ),
    );
  }
}
