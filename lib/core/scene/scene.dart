import 'dart:math' as math;
import 'package:flutter/foundation.dart';

enum SdfPrimitive {
  sphere,
  box,
  cylinder,
  triPrism,
  torus,
  capsule,
}

enum CsgOperation {
  union,
  intersect,
  subtract,
}

class Vec3 {
  final double x;
  final double y;
  final double z;

  const Vec3(this.x, this.y, this.z);
  const Vec3.zero() : x = 0, y = 0, z = 0;
  const Vec3.one() : x = 1, y = 1, z = 1;

  Vec3 operator +(Vec3 other) => Vec3(x + other.x, y + other.y, z + other.z);
  Vec3 operator -(Vec3 other) => Vec3(x - other.x, y - other.y, z - other.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);

  double get length => math.sqrt(x * x + y * y + z * z);

  Vec3 normalized() {
    double len = length;
    if (len == 0) return Vec3.zero();
    return Vec3(x / len, y / len, z / len);
  }

  Vec3 cross(Vec3 other) => Vec3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  Vec3 copyWith({double? x, double? y, double? z}) =>
      Vec3(x ?? this.x, y ?? this.y, z ?? this.z);
}

class SdfMaterial {
  final double r;
  final double g;
  final double b;

  const SdfMaterial({
    this.r = 0.8,
    this.g = 0.4,
    this.b = 0.2,
  });

  SdfMaterial copyWith({double? r, double? g, double? b}) =>
      SdfMaterial(r: r ?? this.r, g: g ?? this.g, b: b ?? this.b);
}

class SdfNode {
  final String id;
  String name;
  SdfPrimitive primitive;
  Vec3 position;
  Vec3 rotation;
  Vec3 scale;
  SdfMaterial material;
  CsgOperation operation;

  SdfNode({
    required this.id,
    required this.name,
    required this.primitive,
    this.position = const Vec3.zero(),
    this.rotation = const Vec3.zero(),
    this.scale = const Vec3.one(),
    this.material = const SdfMaterial(),
    this.operation = CsgOperation.union,
  });

  SdfNode copyWith({
    String? name,
    SdfPrimitive? primitive,
    Vec3? position,
    Vec3? rotation,
    Vec3? scale,
    SdfMaterial? material,
    CsgOperation? operation,
  }) =>
      SdfNode(
        id: id,
        name: name ?? this.name,
        primitive: primitive ?? this.primitive,
        position: position ?? this.position,
        rotation: rotation ?? this.rotation,
        scale: scale ?? this.scale,
        material: material ?? this.material,
        operation: operation ?? this.operation,
      );
}

class Camera {
  Vec3 position;
  double yaw;
  double pitch;
  double speed;
  double sensitivity;

  Camera({
    this.position = const Vec3(0, 0, 5),
    this.yaw = -90.0,
    this.pitch = 0.0,
    this.speed = 5.0,
    this.sensitivity = 0.1,
  });

  Vec3 get direction {
    double yawRad = yaw * math.pi / 180.0;
    double pitchRad = pitch * math.pi / 180.0;
    return Vec3(
      math.cos(yawRad) * math.cos(pitchRad),
      math.sin(pitchRad),
      math.sin(yawRad) * math.cos(pitchRad),
    ).normalized();
  }

  Vec3 get right => direction.cross(Vec3(0, 1, 0)).normalized();
  Vec3 get up => right.cross(direction).normalized();

  void rotate(double deltaX, double deltaY) {
    yaw += deltaX * sensitivity;
    pitch -= deltaY * sensitivity;
    pitch = pitch.clamp(-89.0, 89.0);
  }

  void moveForward(double delta) {
    position = position + direction * (speed * delta);
  }

  void moveBackward(double delta) {
    position = position - direction * (speed * delta);
  }

  void moveLeft(double delta) {
    position = position - right * (speed * delta);
  }

  void moveRight(double delta) {
    position = position + right * (speed * delta);
  }

  void moveUp(double delta) {
    position = position + Vec3(0, 1, 0) * (speed * delta);
  }

  void moveDown(double delta) {
    position = position - Vec3(0, 1, 0) * (speed * delta);
  }
}

class Scene extends ChangeNotifier {
  final List<SdfNode> _nodes = [];
  final Camera camera = Camera();
  int _nodeCounter = 0;

  List<SdfNode> get nodes => List.unmodifiable(_nodes);

  SdfNode addNode(SdfPrimitive primitive) {
    String name = _getPrimitiveName(primitive);
    SdfNode node = SdfNode(
      id: 'node_${_nodeCounter++}',
      name: '$name ${_nodes.length + 1}',
      primitive: primitive,
    );
    _nodes.add(node);
    notifyListeners();
    return node;
  }

  void removeNode(String id) {
    _nodes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void updateNode(String id, SdfNode updated) {
    int index = _nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _nodes[index] = updated;
      notifyListeners();
    }
  }

  SdfNode? getNode(String id) {
    try {
      return _nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  void notifyCameraChanged() {
    notifyListeners();
  }

  String _getPrimitiveName(SdfPrimitive primitive) {
    switch (primitive) {
      case SdfPrimitive.sphere:
        return 'Sphere';
      case SdfPrimitive.box:
        return 'Box';
      case SdfPrimitive.cylinder:
        return 'Cylinder';
      case SdfPrimitive.triPrism:
        return 'Triangle Prism';
      case SdfPrimitive.torus:
        return 'Torus';
      case SdfPrimitive.capsule:
        return 'Capsule';
    }
  }
}
