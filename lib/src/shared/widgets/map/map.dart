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
  // Basic Bowyer-Watson Delaunay triangulation (brute-force, 2D)
  if (points.length < 3) return [];

  // Super triangle covering all points
  final minX = points.map((p) => p[0]).reduce(min);
  final minY = points.map((p) => p[1]).reduce(min);
  final maxX = points.map((p) => p[0]).reduce(max);
  final maxY = points.map((p) => p[1]).reduce(max);
  final dx = maxX - minX;
  final dy = maxY - minY;
  final deltaMax = max(dx, dy) * 10;
  final midx = (minX + maxX) / 2;
  final midy = (minY + maxY) / 2;

  final superTriangle = [
    [midx - deltaMax, midy - deltaMax],
    [midx, midy + deltaMax],
    [midx + deltaMax, midy - deltaMax],
  ];

  List<List<List<double>>> triangles = [
    [superTriangle[0], superTriangle[1], superTriangle[2]],
  ];

  bool pointInCircumcircle(List<double> p, List<List<double>> tri) {
    final ax = tri[0][0], ay = tri[0][1];
    final bx = tri[1][0], by = tri[1][1];
    final cx = tri[2][0], cy = tri[2][1];
    final dx = p[0], dy = p[1];

    final a = ax - dx;
    final b = ay - dy;
    final c = (ax - dx) * (ax - dx) + (ay - dy) * (ay - dy);

    final d = bx - dx;
    final e = by - dy;
    final f = (bx - dx) * (bx - dx) + (by - dy) * (by - dy);

    final g = cx - dx;
    final h = cy - dy;
    final i = (cx - dx) * (cx - dx) + (cy - dy) * (cy - dy);

    final det =
        (a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g));
    return det > 0;
  }

  for (final p in points) {
    final badTriangles = <List<List<double>>>[];
    for (final tri in triangles) {
      if (pointInCircumcircle(p, tri)) {
        badTriangles.add(tri);
      }
    }

    final edgeSet = <List<List<double>>>[];
    for (final tri in badTriangles) {
      for (int i = 0; i < 3; i++) {
        final edge = [tri[i], tri[(i + 1) % 3]];
        bool shared = false;
        for (final otherTri in badTriangles) {
          if (identical(tri, otherTri)) continue;
          for (int j = 0; j < 3; j++) {
            final otherEdge = [otherTri[j], otherTri[(j + 1) % 3]];
            if ((edge[0] == otherEdge[1] && edge[1] == otherEdge[0]) ||
                (edge[0] == otherEdge[0] && edge[1] == otherEdge[1])) {
              shared = true;
              break;
            }
          }
          if (shared) break;
        }
        if (!shared) edgeSet.add(edge);
      }
    }

    triangles.removeWhere((tri) => badTriangles.contains(tri));
    for (final edge in edgeSet) {
      triangles.add([edge[0], edge[1], p]);
    }
  }

  // Remove triangles using super triangle vertices
  triangles = triangles.where((tri) {
    for (final v in superTriangle) {
      if (tri.contains(v)) return false;
    }
    return true;
  }).toList();

  return triangles;
}

List<List<double>> aStarPath(
  MapGraph graph,
  List<double> start,
  List<double> end,
) {
  // Basic A* pathfinding algorithm
  final openSet = <List<double>>[start];
  final cameFrom = <List<double>, List<double>>{};
  final gScore = <List<double>, double>{};
  final fScore = <List<double>, double>{};

  gScore[start] = 0;
  fScore[start] = sqrt(pow(start[0] - end[0], 2) + pow(start[1] - end[1], 2));

  while (openSet.isNotEmpty) {
    // Find node in openSet with lowest fScore
    openSet.sort(
      (a, b) => (fScore[a] ?? double.infinity).compareTo(
        fScore[b] ?? double.infinity,
      ),
    );
    final current = openSet.first;

    if (current[0] == end[0] && current[1] == end[1]) {
      // Reconstruct path
      final path = <List<double>>[current];
      var node = current;
      while (cameFrom.containsKey(node)) {
        node = cameFrom[node]!;
        path.insert(0, node);
      }
      return path;
    }

    openSet.remove(current);

    // Get neighbors from graph (assume MapGraph has a method getNeighbors)
    final neighbors = graph.getNeighbors(current);
    for (final neighbor in neighbors) {
      final tentativeGScore =
          (gScore[current] ?? double.infinity) +
          sqrt(
            pow(current[0] - neighbor[0], 2) + pow(current[1] - neighbor[1], 2),
          );
      if (tentativeGScore < (gScore[neighbor] ?? double.infinity)) {
        cameFrom[neighbor] = current;
        gScore[neighbor] = tentativeGScore;
        fScore[neighbor] =
            tentativeGScore +
            sqrt(pow(neighbor[0] - end[0], 2) + pow(neighbor[1] - end[1], 2));
        if (!openSet.any((p) => p[0] == neighbor[0] && p[1] == neighbor[1])) {
          openSet.add(neighbor);
        }
      }
    }
  }

  // No path found
  return [];
}

class MapGraph {
  // Internal representation of the graph as adjacency list
  final Map<List<double>, List<List<double>>> _adjacency = {};

  // Implement graph structure and methods
  void addLink(List<double> a, List<double> b, double weight) {
    _adjacency.putIfAbsent(a, () => []).add(b);
    _adjacency.putIfAbsent(b, () => []).add(a);
  }

  void removeNode(List<double> node) {
    _adjacency.remove(node);
    for (final neighbors in _adjacency.values) {
      neighbors.removeWhere((n) => n[0] == node[0] && n[1] == node[1]);
    }
  }

  List<List<double>> getNeighbors(List<double> node) {
    return _adjacency[node] ?? [];
  }
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
              ? '😀'
              : p == endPoint[0]
              ? '😈'
              : ['💀', '💰', '❓'][Random().nextInt(3)],
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
    // Initialize points, triangles, graph, startPoint, endPoint
    final points = poissonDiskSampling(Size(450, 450), 40, 60, 30, [
      [225, 450],
      [225, 0],
    ]);
    final triangles = delaunayTriangles(points);

    final graph = MapGraph();
    for (final tri in triangles) {
      for (int i = 0; i < 3; i++) {
        final a = tri[i];
        final b = tri[(i + 1) % 3];
        graph.addLink(a, b, sqrt(pow(a[0] - b[0], 2) + pow(a[1] - b[1], 2)));
      }
    }

    final startPoint = [
      [225.0, 450.0],
    ];
    final endPoint = [
      [225.0, 0.0],
    ];
    return CustomPaint(
      size: Size(500, 500),
      painter: MapPainter(
        canvasSize: 500,
        points: points, // Fill with Poisson Disk points
        triangles: triangles, // Fill with Delaunay triangles
        startPoint: startPoint,
        endPoint: endPoint,
        graph: graph,
      ),
    );
  }
}
