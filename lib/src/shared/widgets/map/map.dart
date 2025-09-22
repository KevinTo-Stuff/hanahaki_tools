// Dart imports:
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// A simplified translation of the provided p5.js sketch.
// - Bridson Poisson disk sampling
// - Graph built by connecting k nearest neighbors
// - A* pathfinding on the graph
// - CustomPainter draws arrows, dotted lines and emoji


class MapSketchController {
  VoidCallback? _listener;
  GlobalKey? _boundaryKey;

  /// Force the attached MapSketch to regenerate procedural data.
  void regenerate() => _listener?.call();

  /// Internal: used by the widget to attach/detach the controller.
  void _attach(VoidCallback listener) => _listener = listener;
  void _detach() => _listener = null;

  /// Internal: widget registers its RepaintBoundary key so controller
  /// can capture the rendered image.
  void _registerBoundaryKey(GlobalKey key) => _boundaryKey = key;

  /// Capture the current map as PNG bytes. Returns null on failure.
  Future<Uint8List?> capturePng() async {
    try {
      if (_boundaryKey == null) return null;
      final boundary =
          _boundaryKey!.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}

class MapSketch extends StatefulWidget {
  const MapSketch({
    super.key,
    this.size = 500,
    this.controller,
    this.minDist = 40,
    this.maxDist = 80,
    this.tries = 30,
  });

  final double size;
  final MapSketchController? controller;
  final double minDist;
  final double maxDist;
  final int tries;

  @override
  State<MapSketch> createState() => _MapSketchState();
}

class _MapSketchState extends State<MapSketch> {
  late double canvasSize;
  final double noiseScale = 0.02;

  late Point<double> startPoint;
  late Point<double> endPoint;
  late Graph graph;
  late List<Point<double>> points;
  final Random rng = Random();

  @override
  void initState() {
    super.initState();
    canvasSize = widget.size;
    _buildProcedural();
    widget.controller?._attach(() {
      // rebuild procedural data and repaint
      setState(() {
        canvasSize = widget.size;
        _buildProcedural();
      });
    });
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  void _buildProcedural() {
    // Poisson Disk Sampling (Bridson)
    final pds = PoissonDiskSampler(
      width: canvasSize * 0.9,
      height: canvasSize * 0.9,
      minDist: widget.minDist,
      maxDist: widget.maxDist,
      tries: widget.tries,
      rng: rng,
    );

    startPoint = Point(canvasSize * 0.45, canvasSize * 0.9);
    endPoint = Point(canvasSize * 0.45, 0);
    pds.addPoint(startPoint);
    pds.addPoint(endPoint);
    points = pds.fill().where((p) {
      final dx = p.x - canvasSize * 0.45;
      final dy = p.y - canvasSize * 0.45;
      return sqrt(dx * dx + dy * dy) <= canvasSize * 0.45;
    }).toList();

    // Build graph from Delaunay triangulation (Bowyer-Watson)
    graph = Graph();
    for (final p in points) {
      graph.addNode(p);
    }
    final triangles = _delaunayTriangles(points);
    for (final t in triangles) {
      graph.addLink(t[0], t[1], weight: distance(t[0], t[1]));
      graph.addLink(t[1], t[2], weight: distance(t[1], t[2]));
      graph.addLink(t[2], t[0], weight: distance(t[2], t[0]));
    }
  }

  double distance(Point a, Point b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  Widget build(BuildContext context) {
    // If a controller is provided, register a RepaintBoundary key so
    // the controller can export the widget as an image.
    final boundaryKey = widget.controller != null ? GlobalKey() : null;
    widget.controller?._registerBoundaryKey(boundaryKey!);

    final painter = _MapPainter(
      canvasSize: canvasSize,
      start: startPoint,
      end: endPoint,
      graph: graph,
      rng: rng,
    );

    final content = SizedBox(
      width: canvasSize,
      height: canvasSize,
      child: CustomPaint(painter: painter),
    );

    if (boundaryKey != null) {
      return RepaintBoundary(key: boundaryKey, child: content);
    }
    return content;
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.canvasSize,
    required this.start,
    required this.end,
    required this.graph,
    required this.rng,
  });

  final double canvasSize;
  final Point<double> start;
  final Point<double> end;
  final Graph graph;
  final Random rng;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bg = Paint()..color = const Color.fromARGB(255, 40, 50, 60);
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasSize, canvasSize), bg);

    final translateOffset = Offset(canvasSize * 0.05, canvasSize * 0.05);
    canvas.save();
    canvas.translate(translateOffset.dx, translateOffset.dy);

    // Active points collection and simple A* iterations
    final activePoints = <Point<double>>[];
    for (var iter = 0; iter < (canvasSize / 50).floor(); iter++) {
      final path = aStar(graph, start, end);
      if (path.isEmpty) break;
      activePoints.addAll(path);

      // draw arrows along path
      for (var i = 1; i < path.length; i++) {
        _drawArrow(canvas, path[i - 1], path[i]);
      }

      // remove a random middle node
      if (path.length > 2) {
        final idx = 1 + rng.nextInt(path.length - 2);
        graph.removeNode(path[idx]);
      }
    }

    // Draw points (emoji)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final unique = activePoints.toSet().toList();
    for (final p in unique) {
      final text = (p == start)
          ? '😀'
          : (p == end)
          ? '😈'
          : '💀';
      textPainter.text = TextSpan(
        text: text,
        style: const TextStyle(fontSize: 16),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(p.x - textPainter.width / 2, p.y - textPainter.height / 2),
      );
    }

    canvas.restore();

    // overlay
    final overlay = Paint()..color = const Color.fromRGBO(40, 50, 60, 0.3);
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasSize, canvasSize), overlay);
  }

  void _drawArrow(
    Canvas canvas,
    Point<double> a,
    Point<double> b, {
    double arrowSize = 6,
  }) {
    final vec = Offset(b.x - a.x, b.y - a.y);
    final len = vec.distance;
    final factor = (len - 10) / len;
    final endVec = Offset(vec.dx * factor, vec.dy * factor);

    // dotted line from a to a + endVec
    _dottedLine(
      canvas,
      Offset(a.x, a.y),
      Offset(a.x + endVec.dx, a.y + endVec.dy),
    );

    // triangle arrowhead
    canvas.save();
    canvas.translate(a.x, a.y);
    final angle = atan2(vec.dy, vec.dx);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(endVec.distance - arrowSize, arrowSize / 2)
      ..lineTo(endVec.distance - arrowSize, -arrowSize / 2)
      ..lineTo(endVec.distance, 0)
      ..close();
    final paint = Paint()..color = Colors.white;
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _dottedLine(Canvas canvas, Offset p1, Offset p2, {double fragment = 5}) {
    final vec = p2 - p1;
    final len = vec.distance;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    var pos = p1;
    var remaining = len;
    final direction = vec / len;
    while (remaining > 0) {
      final seg = min(fragment, remaining);
      final next = pos + direction * seg;
      canvas.drawLine(pos, next, paint);
      pos = next + direction * seg;
      remaining = (p2 - pos).distance;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------- Helpers: Poisson Disk Sampling ----------

class PoissonDiskSampler {
  PoissonDiskSampler({
    required this.width,
    required this.height,
    required this.minDist,
    required this.maxDist,
    this.tries = 30,
    Random? rng,
  }) : rng = rng ?? Random();

  final double width, height;
  final double minDist, maxDist;
  final int tries;
  final Random rng;

  final List<Point<double>> _points = [];

  void addPoint(Point<double> p) => _points.add(p);

  List<Point<double>> fill() {
    // Very simplified Bridson: start with existing points and attempt to add more
    final List<Point<double>> active = List.from(_points);
    while (active.isNotEmpty) {
      final idx = rng.nextInt(active.length);
      final center = active[idx];
      var found = false;
      for (var i = 0; i < tries; i++) {
        final r = minDist + rng.nextDouble() * (maxDist - minDist);
        final a = rng.nextDouble() * 2 * pi;
        final p = Point(center.x + r * cos(a), center.y + r * sin(a));
        if (p.x < 0 || p.x >= width || p.y < 0 || p.y >= height) continue;
        if (_points.any(
          (q) =>
              (q.x - p.x) * (q.x - p.x) + (q.y - p.y) * (q.y - p.y) <
              minDist * minDist,
        )) {
          continue;
        }
        _points.add(p);
        active.add(p);
        found = true;
        break;
      }
      if (!found) active.removeAt(idx);
    }
    return _points;
  }
}

// ---------- Simple Graph and A* ----------

class Graph {
  final Map<Point<double>, Map<Point<double>, double>> _adj = {};

  void addNode(Point<double> p) {
    _adj.putIfAbsent(p, () => {});
  }

  void addLink(Point<double> a, Point<double> b, {required double weight}) {
    addNode(a);
    addNode(b);
    _adj[a]![b] = weight;
    _adj[b]![a] = weight;
  }

  void removeNode(Point<double> p) {
    _adj.remove(p);
    for (final m in _adj.values) {
      m.remove(p);
    }
  }

  List<Point<double>> neighbors(Point<double> p) =>
      _adj[p]?.keys.toList() ?? [];

  double? weight(Point<double> a, Point<double> b) => _adj[a]?[b];
}

List<Point<double>> aStar(
  Graph graph,
  Point<double> start,
  Point<double> goal,
) {
  final closed = <Point<double>>{};
  final gScore = <Point<double>, double>{};
  final fScore = <Point<double>, double>{};
  final cameFrom = <Point<double>, Point<double>>{};

  double heuristic(Point<double> a, Point<double> b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }

  final open = <Point<double>>[];
  open.add(start);
  gScore[start] = 0;
  fScore[start] = heuristic(start, goal);

  while (open.isNotEmpty) {
    open.sort(
      (a, b) => (fScore[a] ?? double.infinity).compareTo(
        fScore[b] ?? double.infinity,
      ),
    );
    final current = open.removeAt(0);
    if (current == goal) {
      final path = <Point<double>>[];
      var cur = current;
      while (cameFrom.containsKey(cur)) {
        path.insert(0, cur);
        cur = cameFrom[cur]!;
      }
      path.insert(0, start);
      return path;
    }

    closed.add(current);
    for (final neighbor in graph.neighbors(current)) {
      if (closed.contains(neighbor)) continue;
      final tentative =
          (gScore[current] ?? double.infinity) +
          (graph.weight(current, neighbor) ?? double.infinity);
      if (!open.contains(neighbor)) open.add(neighbor);
      if (tentative >= (gScore[neighbor] ?? double.infinity)) continue;
      cameFrom[neighbor] = current;
      gScore[neighbor] = tentative;
      fScore[neighbor] = tentative + heuristic(neighbor, goal);
    }
  }

  return [];
}

// ---------- Delaunay (Bowyer-Watson) ----------

class _Tri {
  _Tri(this.a, this.b, this.c);
  final Point<double> a, b, c;
}

class _Edge {
  _Edge(this.u, this.v);
  final Point<double> u, v;
  @override
  bool operator ==(Object other) =>
      other is _Edge &&
      ((other.u == u && other.v == v) || (other.u == v && other.v == u));
  @override
  int get hashCode => u.hashCode ^ v.hashCode;
}

List<List<Point<double>>> _delaunayTriangles(List<Point<double>> pts) {
  if (pts.length < 3) return [];
  // Create a super-triangle that encompasses all points
  final minX = pts.map((p) => p.x).reduce(min);
  final minY = pts.map((p) => p.y).reduce(min);
  final maxX = pts.map((p) => p.x).reduce(max);
  final maxY = pts.map((p) => p.y).reduce(max);
  final dx = maxX - minX;
  final dy = maxY - minY;
  final dmax = max(dx, dy) * 10;
  final midx = (minX + maxX) / 2;
  final midy = (minY + maxY) / 2;

  final p1 = Point(midx - dmax, midy - dmax);
  final p2 = Point(midx, midy + dmax);
  final p3 = Point(midx + dmax, midy - dmax);

  final triangles = <_Tri>[];
  triangles.add(_Tri(p1, p2, p3));

  bool inCircumcircle(Point<double> p, _Tri t) {
    // Use a robust-ish test with a small epsilon and orientation check.
    const eps = 1e-9;
    final ax = t.a.x - p.x;
    final ay = t.a.y - p.y;
    final bx = t.b.x - p.x;
    final by = t.b.y - p.y;
    final cx = t.c.x - p.x;
    final cy = t.c.y - p.y;
    final det =
        (ax * ax + ay * ay) * (bx * cy - cx * by) -
        (bx * bx + by * by) * (ax * cy - cx * ay) +
        (cx * cx + cy * cy) * (ax * by - bx * ay);
    return det > eps;
  }

  for (final p in pts) {
    final bad = <_Tri>[];
    for (final t in triangles) {
      if (inCircumcircle(p, t)) bad.add(t);
    }
    final polygon = <_Edge>{};
    for (final t in bad) {
      polygon.add(_Edge(t.a, t.b));
      polygon.add(_Edge(t.b, t.c));
      polygon.add(_Edge(t.c, t.a));
    }
    // remove bad triangles
    triangles.removeWhere((t) => bad.contains(t));
    // remove duplicate edges
    final edgeCount = <_Edge, int>{};
    for (final e in polygon) {
      edgeCount[e] = (edgeCount[e] ?? 0) + 1;
    }
    final boundary = edgeCount.entries
        .where((e) => e.value == 1)
        .map((e) => e.key);
    for (final e in boundary) {
      triangles.add(_Tri(e.u, e.v, p));
    }
  }

  // Remove triangles that include super-triangle vertices
  final result = <List<Point<double>>>[];
  for (final t in triangles) {
    if (t.a == p1 || t.a == p2 || t.a == p3) continue;
    if (t.b == p1 || t.b == p2 || t.b == p3) continue;
    if (t.c == p1 || t.c == p2 || t.c == p3) continue;
    result.add([t.a, t.b, t.c]);
  }
  return result;
}
