import 'scene.dart';

class ShaderGenerator {
  static const String vertexShader = '''#version 300 es
in vec2 a_position;
out vec2 v_uv;

void main() {
  v_uv = a_position * 0.5 + 0.5;
  gl_Position = vec4(a_position, 0.0, 1.0);
}
''';

  static const String _sdfLibrary = '''
// SDF Primitives
float sdSphere(vec3 p, float r) {
  return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdCylinder(vec3 p, float h, float r) {
  vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdTriPrism(vec3 p, vec2 h) {
  vec3 q = abs(p);
  return max(q.z - h.y, max(q.x * 0.866025 + p.y * 0.5, -p.y) - h.x * 0.5);
}

float sdTorus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz) - t.x, p.y);
  return length(q) - t.y;
}

float sdCapsule(vec3 p, float h, float r) {
  p.y -= clamp(p.y, 0.0, h);
  return length(p) - r;
}

// CSG Operations
float opUnion(float d1, float d2) {
  return min(d1, d2);
}

float opIntersect(float d1, float d2) {
  return max(d1, d2);
}

float opSubtract(float d1, float d2) {
  return max(-d1, d2);
}

// Rotation matrices
mat3 rotateX(float a) {
  float c = cos(a), s = sin(a);
  return mat3(1.0, 0.0, 0.0, 0.0, c, -s, 0.0, s, c);
}

mat3 rotateY(float a) {
  float c = cos(a), s = sin(a);
  return mat3(c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c);
}

mat3 rotateZ(float a) {
  float c = cos(a), s = sin(a);
  return mat3(c, -s, 0.0, s, c, 0.0, 0.0, 0.0, 1.0);
}
''';

  static String generateFragmentShader(Scene scene) {
    StringBuffer sb = StringBuffer();

    sb.writeln('#version 300 es');
    sb.writeln('precision highp float;');
    sb.writeln();
    sb.writeln('in vec2 v_uv;');
    sb.writeln('out vec4 fragColor;');
    sb.writeln();
    sb.writeln('uniform vec2 u_resolution;');
    sb.writeln('uniform float u_time;');
    sb.writeln('uniform vec3 u_cameraPos;');
    sb.writeln('uniform vec3 u_cameraDir;');
    sb.writeln('uniform vec3 u_cameraRight;');
    sb.writeln('uniform vec3 u_cameraUp;');
    sb.writeln();

    // Add node uniforms
    for (int i = 0; i < scene.nodes.length; i++) {
      sb.writeln('uniform vec3 u_node${i}_pos;');
      sb.writeln('uniform vec3 u_node${i}_rot;');
      sb.writeln('uniform vec3 u_node${i}_scale;');
      sb.writeln('uniform vec3 u_node${i}_color;');
    }
    sb.writeln();

    sb.writeln(_sdfLibrary);
    sb.writeln();

    // Generate node SDF functions
    for (int i = 0; i < scene.nodes.length; i++) {
      SdfNode node = scene.nodes[i];
      sb.writeln(_generateNodeFunction(i, node));
    }

    // Generate sceneSDF
    sb.writeln(_generateSceneSDF(scene));

    // Generate getMaterial function
    sb.writeln(_generateGetMaterial(scene));

    // Add raymarching and main
    sb.writeln(_rayMarchingCode);

    return sb.toString();
  }

  static String _generateNodeFunction(int index, SdfNode node) {
    String primitive = _getPrimitiveSdf(index, node.primitive);
    return '''
float node$index(vec3 p) {
  vec3 tp = p - u_node${index}_pos;
  tp = rotateX(u_node${index}_rot.x) * tp;
  tp = rotateY(u_node${index}_rot.y) * tp;
  tp = rotateZ(u_node${index}_rot.z) * tp;
  return $primitive;
}
''';
  }

  static String _getPrimitiveSdf(int index, SdfPrimitive primitive) {
    switch (primitive) {
      case SdfPrimitive.sphere:
        return 'sdSphere(tp, u_node${index}_scale.x)';
      case SdfPrimitive.box:
        return 'sdBox(tp, u_node${index}_scale)';
      case SdfPrimitive.cylinder:
        return 'sdCylinder(tp, u_node${index}_scale.y, u_node${index}_scale.x)';
      case SdfPrimitive.triPrism:
        return 'sdTriPrism(tp, u_node${index}_scale.xy)';
      case SdfPrimitive.torus:
        return 'sdTorus(tp, u_node${index}_scale.xy)';
      case SdfPrimitive.capsule:
        return 'sdCapsule(tp, u_node${index}_scale.y, u_node${index}_scale.x)';
    }
  }

  static String _generateSceneSDF(Scene scene) {
    if (scene.nodes.isEmpty) {
      return '''
float sceneSDF(vec3 p) {
  return 1000.0; // No objects
}
''';
    }

    StringBuffer sb = StringBuffer();
    sb.writeln('float sceneSDF(vec3 p) {');
    sb.writeln('  float d = node0(p);');

    for (int i = 1; i < scene.nodes.length; i++) {
      SdfNode node = scene.nodes[i];
      String op = _getCsgOp(node.operation);
      sb.writeln('  d = $op(node$i(p), d);');
    }

    sb.writeln('  return d;');
    sb.writeln('}');
    return sb.toString();
  }

  static String _getCsgOp(CsgOperation op) {
    switch (op) {
      case CsgOperation.union:
        return 'opUnion';
      case CsgOperation.intersect:
        return 'opIntersect';
      case CsgOperation.subtract:
        return 'opSubtract';
    }
  }

  static String _generateGetMaterial(Scene scene) {
    if (scene.nodes.isEmpty) {
      return '''
vec3 getMaterial(vec3 p) {
  return vec3(0.8, 0.4, 0.2);
}
''';
    }

    StringBuffer sb = StringBuffer();
    sb.writeln('vec3 getMaterial(vec3 p) {');
    sb.writeln('  float minD = node0(p);');
    sb.writeln('  vec3 col = u_node0_color;');

    for (int i = 1; i < scene.nodes.length; i++) {
      sb.writeln('  float d$i = node$i(p);');
      sb.writeln('  if (d$i < minD) { minD = d$i; col = u_node${i}_color; }');
    }

    sb.writeln('  return col;');
    sb.writeln('}');
    return sb.toString();
  }

  static const String _rayMarchingCode = '''
vec3 calcNormal(vec3 p) {
  float e = 0.001;
  return normalize(vec3(
    sceneSDF(vec3(p.x + e, p.y, p.z)) - sceneSDF(vec3(p.x - e, p.y, p.z)),
    sceneSDF(vec3(p.x, p.y + e, p.z)) - sceneSDF(vec3(p.x, p.y - e, p.z)),
    sceneSDF(vec3(p.x, p.y, p.z + e)) - sceneSDF(vec3(p.x, p.y, p.z - e))
  ));
}

float rayMarch(vec3 ro, vec3 rd) {
  float t = 0.0;
  for (int i = 0; i < 100; i++) {
    vec3 p = ro + rd * t;
    float d = sceneSDF(p);
    if (d < 0.001) break;
    if (t > 100.0) break;
    t += d;
  }
  return t;
}

void main() {
  vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;

  // Camera ray
  vec3 ro = u_cameraPos;
  vec3 rd = normalize(u_cameraDir + uv.x * u_cameraRight + uv.y * u_cameraUp);

  float t = rayMarch(ro, rd);

  vec3 col = vec3(0.05, 0.05, 0.1);

  if (t < 100.0) {
    vec3 p = ro + rd * t;
    vec3 n = calcNormal(p);

    vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
    float diff = max(dot(n, lightDir), 0.0);
    float amb = 0.2;

    vec3 viewDir = normalize(ro - p);
    vec3 reflectDir = reflect(-lightDir, n);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);

    vec3 baseColor = getMaterial(p);
    col = baseColor * (amb + diff) + vec3(1.0) * spec * 0.5;
  }

  col = pow(col, vec3(0.4545));
  fragColor = vec4(col, 1.0);
}
''';

  /// Get all uniform names for a scene
  static List<String> getUniformNames(Scene scene) {
    List<String> uniforms = [
      'u_resolution',
      'u_time',
      'u_cameraPos',
      'u_cameraDir',
      'u_cameraRight',
      'u_cameraUp',
    ];

    for (int i = 0; i < scene.nodes.length; i++) {
      uniforms.add('u_node${i}_pos');
      uniforms.add('u_node${i}_rot');
      uniforms.add('u_node${i}_scale');
      uniforms.add('u_node${i}_color');
    }

    return uniforms;
  }
}
