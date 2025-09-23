// Dart imports:
import 'dart:math';
import 'dart:collection';

// Flutter imports:
import 'package:flutter/material.dart';
// Package imports:
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MapPainter extends CustomPainter {
  final double canvasSize;
  final int seed;
  final MapConfig config;

  MapPainter({required this.canvasSize, required this.seed, MapConfig? config})
    : _rnd = Random(seed),
      config = config ?? MapConfig.defaults();

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
    final generator = _MapGenerator(_innerSize, _rnd, config);
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

    // Draw points using Font Awesome icons — ensure each point only gets one icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final uniqueIndices = LinkedHashSet<int>.from(map.activePointIndices);
    for (final idx in uniqueIndices) {
      final p = map.points[idx];
      IconData icon = FontAwesomeIcons.question;
      // start / end overrides
      if ((p - map.startPoint).distance < 0.1) {
        icon = FontAwesomeIcons.doorOpen;
      } else if ((p - map.endPoint).distance < 0.1) {
        icon = FontAwesomeIcons.flagCheckered;
      } else {
        // map a point type to an icon
        final type = map.pointTypes[idx];
        switch (type) {
          case PointType.regular:
            icon = FontAwesomeIcons.skull;
          case PointType.elite:
            icon = FontAwesomeIcons.skullCrossbones;
          case PointType.merchant:
            icon = FontAwesomeIcons.cashRegister;
          case PointType.event:
            icon = FontAwesomeIcons.book;
          case PointType.safe:
            icon = FontAwesomeIcons.water;
          case PointType.unknown:
            icon = FontAwesomeIcons.question;
        }
      }

      // Build the font family string. When the font comes from a package
      // the family registered in the FontManifest is usually prefixed with
      // `packages/<packageName>/`, so replicate that to ensure the font is found.
      String? family = icon.fontFamily;
      if (icon.fontPackage != null && family != null) {
        family = 'packages/${icon.fontPackage}/$family';
      }

      textPainter.text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 16,
          fontFamily: family,
          color: Colors.white,
          package: null,
        ),
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
  final List<PointType> pointTypes;

  _GeneratedMap({
    required this.points,
    required this.startPoint,
    required this.endPoint,
    required this.paths,
    required this.activePointIndices,
    required this.pointTypes,
  });
}

enum PointType { regular, elite, merchant, event, safe, unknown }

class MapConfig {
  final Set<PointType> enabledTypes;
  final int targetNodes;
  final int branchingPaths;

  MapConfig({
    required this.enabledTypes,
    required this.targetNodes,
    required this.branchingPaths,
  });

  factory MapConfig.defaults() => MapConfig(
    enabledTypes: PointType.values.toSet(),
    targetNodes: 120,
    branchingPaths: 3,
  );
}

class _MapGenerator {
  final double size;
  final Random rnd;

  _MapGenerator(this.size, this.rnd, [MapConfig? config])
    : config = config ?? MapConfig.defaults();

  final MapConfig config;

  _GeneratedMap generate() {
    // padding handled by painter
    final center = Offset(size * 0.45, size * 0.45);
    final startPoint = Offset(size * 0.45, size * 0.9);
    final endPoint = Offset(size * 0.45, 0);

    final points = <Offset>[];
    points.add(startPoint);
    points.add(endPoint);

    // Simple rejection sampling to approximate Poisson-disc
    final int target = config.targetNodes;
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
    // assign weighted point types (biased toward regular mobs)
    final pointTypes = List<PointType>.filled(points.length, PointType.regular);
    final baseWeights = {
      PointType.regular: 60,
      PointType.elite: 8,
      PointType.merchant: 8,
      PointType.event: 8,
      PointType.safe: 10,
      PointType.unknown: 6,
    };
    // Filter weights by enabled types in config
    final weights = <PointType, int>{};
    for (final e in config.enabledTypes) {
      weights[e] = baseWeights[e] ?? 0;
    }
    final totalWeight = weights.values.isEmpty
        ? 1
        : weights.values.reduce((a, b) => a + b);
    for (int i = 0; i < points.length; i++) {
      // start and end keep default but still assign something
      int r = rnd.nextInt(totalWeight);
      var cum = 0;
      PointType chosen = PointType.regular;
      for (final entry in weights.entries) {
        cum += entry.value;
        if (r < cum) {
          chosen = entry.key;
          break;
        }
      }
      pointTypes[i] = chosen;
    }

    final startIdx = 0;
    final endIdx = 1;

    final iterations = min(config.branchingPaths, max(1, (size / 50).floor()));
    for (int it = 0; it < iterations; it++) {
      final path = _aStar(points, adj, startIdx, endIdx, removed);
      if (path.isEmpty) break;
      // ensure each path has at least one safe point (not start/end)
      bool hasSafe = false;
      for (final idx in path) {
        if (idx != startIdx &&
            idx != endIdx &&
            pointTypes[idx] == PointType.safe) {
          hasSafe = true;
          break;
        }
      }
      if (!hasSafe &&
          path.length > 2 &&
          config.enabledTypes.contains(PointType.safe)) {
        // pick a random internal node and mark it safe
        final internal = path[1 + rnd.nextInt(path.length - 2)];
        if (internal != startIdx && internal != endIdx) {
          // ensure neighbors are not safe to avoid consecutive safe points
          final idxPos = path.indexOf(internal);
          if (idxPos > 0) {
            final left = path[idxPos - 1];
            if (left != startIdx && left != endIdx) {
              pointTypes[left] = PointType.regular;
            }
          }
          if (idxPos < path.length - 1) {
            final right = path[idxPos + 1];
            if (right != startIdx && right != endIdx) {
              pointTypes[right] = PointType.regular;
            }
          }
          pointTypes[internal] = PointType.safe;
        }
      }
      // Post-process path to ensure there are no consecutive safe points
      for (int p = 0; p < path.length - 1; p++) {
        final a = path[p];
        final b = path[p + 1];
        if (a != startIdx && a != endIdx && b != startIdx && b != endIdx) {
          if (pointTypes[a] == PointType.safe &&
              pointTypes[b] == PointType.safe) {
            // demote the later one to regular
            pointTypes[b] = PointType.regular;
          }
        }
      }
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
      pointTypes: pointTypes,
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
