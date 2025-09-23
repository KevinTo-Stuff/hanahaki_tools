// Dart imports:
import 'dart:math';
import 'dart:collection';

// Flutter imports:
import 'package:flutter/material.dart';

class MapPainter extends CustomPainter {
  final double canvasSize;
  final int seed;

  MapPainter({required this.canvasSize, required this.seed})
    : _rnd = Random(seed);

  final Random _rnd;

  late final double _pad = canvasSize * 0.05;
  late final double _innerSize = canvasSize * 0.9;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Background
    paint.color = const Color(0xFF2B2B2B);
    canvas.drawRect(Offset.zero & size, paint);

    // Border square
    canvas.save();
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 10;
    paint.color = const Color(0xFF556B2F);
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasSize, canvasSize), paint);
    canvas.restore();

    // Compute points and graph
    final generator = _MapGenerator(_innerSize, _rnd);
    final map = generator.generate();

    // Translate by padding like the original sketch
    canvas.translate(_pad, _pad);

    // Draw arrows/paths
    for (final path in map.paths) {
      for (int j = 1; j < path.length; j++) {
        final a = path[j - 1];
        final b = path[j];
        _drawArrow(canvas, Offset(a.dx, a.dy), Offset(b.dx, b.dy));
      }
    }

    // Draw points (emojis) — ensure each point only gets one emoji
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final uniqueIndices = LinkedHashSet<int>.from(map.activePointIndices);
    for (final idx in uniqueIndices) {
      final p = map.points[idx];
      String emoji = '❓';
      if ((p - map.startPoint).distance < 0.1) emoji = '😀';
      if ((p - map.endPoint).distance < 0.1) emoji = '😈';
      // random filler for others
      if (emoji == '❓') {
        final choices = ['💀', '💰', '❓'];
        emoji = choices[_rnd.nextInt(choices.length)];
      }
      textPainter.text = TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 16),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(p.dx - textPainter.width / 2, p.dy - textPainter.height / 2),
      );
    }

    // translucent overlay
    paint.color = const Color.fromRGBO(40, 50, 60, 0.3);
    paint.style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(-_pad, -_pad, canvasSize, canvasSize), paint);
  }

  void _drawArrow(
    Canvas canvas,
    Offset from,
    Offset to, {
    double arrowSize = 6,
  }) {
    final vec = to - from;
    final len = vec.distance;
    if (len < 1) return;
    final dir = Offset(vec.dx / len, vec.dy / len);
    final end = from + dir * (len - 10);

    // Dotted line
    _dottedLine(canvas, from, end);

    // Arrowhead
    final paint = Paint()..color = const Color(0xFF556B2F);
    // angle is not used but computed in original sketch; omitted here
    final path = Path();
    final tip = end + dir * arrowSize;
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(end.dx, end.dy + arrowSize / 2);
    path.lineTo(end.dx, end.dy - arrowSize / 2);
    path.close();
    canvas.save();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _dottedLine(Canvas canvas, Offset a, Offset b, {double fragment = 5}) {
    final vec = b - a;
    final len = vec.distance;
    final dir = Offset(vec.dx / len, vec.dy / len);
    var pos = a;
    final paint = Paint()
      ..color = const Color(0xFF556B2F)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    int steps = max(1, (len * 0.5 / fragment).floor());
    for (int i = steps; i >= 0; i--) {
      final seg = (i == 0 && (len / fragment).floor() % 2 == 0)
          ? len % fragment
          : fragment;
      final next = pos + dir * seg;
      canvas.drawLine(pos, next, paint);
      pos = next + dir * seg;
      if ((pos - a).distance >= len) break;
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.canvasSize != canvasSize;
}

class _GeneratedMap {
  final List<Offset> points;
  final Offset startPoint;
  final Offset endPoint;
  final List<List<Offset>> paths;
  final List<int> activePointIndices;

  _GeneratedMap({
    required this.points,
    required this.startPoint,
    required this.endPoint,
    required this.paths,
    required this.activePointIndices,
  });
}

class _MapGenerator {
  final double size;
  final Random rnd;

  _MapGenerator(this.size, this.rnd);

  _GeneratedMap generate() {
    // padding handled by painter
    final center = Offset(size * 0.45, size * 0.45);
    final startPoint = Offset(size * 0.45, size * 0.9);
    final endPoint = Offset(size * 0.45, 0);

    final points = <Offset>[];
    points.add(startPoint);
    points.add(endPoint);

    // Simple rejection sampling to approximate Poisson-disc
    const int target = 120;
    const double minDist = 40.0;
    int attempts = 0;
    while (points.length < target && attempts < 20000) {
      attempts++;
      final x = rnd.nextDouble() * size * 0.9;
      final y = rnd.nextDouble() * size * 0.9;
      final p = Offset(x, y);
      if ((p - center).distance > size * 0.45) continue;
      bool ok = true;
      for (final q in points) {
        if ((p - q).distance < minDist) {
          ok = false;
          break;
        }
      }
      if (ok) points.add(p);
    }

    // Build k-nearest neighbor graph
    final adj = List<List<int>>.generate(points.length, (_) => []);
    final k = 6;
    for (int i = 0; i < points.length; i++) {
      final dists = <MapEntry<int, double>>[];
      for (int j = 0; j < points.length; j++) {
        if (i == j) continue;
        dists.add(MapEntry(j, (points[i] - points[j]).distance));
      }
      dists.sort((a, b) => a.value.compareTo(b.value));
      for (int t = 0; t < min(k, dists.length); t++) {
        final j = dists[t].key;
        if (!adj[i].contains(j)) adj[i].add(j);
        if (!adj[j].contains(i)) adj[j].add(i);
      }
    }

    // Path finding multiple times, removing a node from found path each iteration
    final removed = <int>{};
    final paths = <List<Offset>>[];
    final activePoints = <int>[];

    final startIdx = 0;
    final endIdx = 1;

    final iterations = max(1, (size / 50).floor());
    for (int it = 0; it < iterations; it++) {
      final path = _aStar(points, adj, startIdx, endIdx, removed);
      if (path.isEmpty) break;
      paths.add(path.map((i) => points[i]).toList());
      activePoints.addAll(path);
      // remove a random internal node
      if (path.length > 2) {
        final idx = path[1 + rnd.nextInt(path.length - 2)];
        removed.add(idx);
      } else {
        break;
      }
    }

    return _GeneratedMap(
      points: points,
      startPoint: startPoint,
      endPoint: endPoint,
      paths: paths,
      activePointIndices: activePoints,
    );
  }

  List<int> _aStar(
    List<Offset> points,
    List<List<int>> adj,
    int start,
    int goal,
    Set<int> removed,
  ) {
    final open = <int>{start};
    final cameFrom = <int, int>{};
    final gScore = List<double>.filled(points.length, double.infinity);
    gScore[start] = 0.0;
    final fScore = List<double>.filled(points.length, double.infinity);
    fScore[start] = (points[start] - points[goal]).distance;

    while (open.isNotEmpty) {
      int current = open.reduce((a, b) => fScore[a] < fScore[b] ? a : b);
      if (current == goal) {
        // reconstruct
        final path = <int>[];
        var cur = current;
        while (cameFrom.containsKey(cur)) {
          path.insert(0, cur);
          cur = cameFrom[cur]!;
        }
        path.insert(0, cur);
        return path;
      }

      open.remove(current);

      for (final neighbor in adj[current]) {
        if (removed.contains(neighbor)) continue;
        if (removed.contains(current)) continue;
        final tentative =
            gScore[current] + (points[current] - points[neighbor]).distance;
        if (tentative < gScore[neighbor]) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentative;
          fScore[neighbor] =
              tentative + (points[neighbor] - points[goal]).distance;
          open.add(neighbor);
        }
      }
    }
    return <int>[];
  }
}
