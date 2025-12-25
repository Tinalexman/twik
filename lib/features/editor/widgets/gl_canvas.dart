import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

const String _vertexShaderSource = '''#version 300 es
in vec2 a_position;
out vec2 v_uv;

void main() {
  v_uv = a_position * 0.5 + 0.5;
  gl_Position = vec4(a_position, 0.0, 1.0);
}
''';

const String _fragmentShaderSource = '''#version 300 es
precision highp float;

in vec2 v_uv;
out vec4 fragColor;

uniform vec2 u_resolution;
uniform float u_time;

// Signed distance function for a sphere
float sdSphere(vec3 p, float r) {
  return length(p) - r;
}

// Signed distance function for a triangular prism
float sdTriPrism(vec3 p, vec2 h) {
  vec3 q = abs(p);
  return max(q.z - h.y, max(q.x * 0.866025 + p.y * 0.5, -p.y) - h.x * 0.5);
}

// Scene SDF - combine all objects here
float sceneSDF(vec3 p) {
  // Rotating triangle prism
  float c = cos(u_time * 0.5);
  float s = sin(u_time * 0.5);
  vec3 rotatedP = vec3(
    p.x * c - p.z * s,
    p.y,
    p.x * s + p.z * c
  );
  return sdTriPrism(rotatedP, vec2(1.0, 0.5));
}

// Calculate normal using gradient
vec3 calcNormal(vec3 p) {
  float e = 0.001;
  return normalize(vec3(
    sceneSDF(vec3(p.x + e, p.y, p.z)) - sceneSDF(vec3(p.x - e, p.y, p.z)),
    sceneSDF(vec3(p.x, p.y + e, p.z)) - sceneSDF(vec3(p.x, p.y - e, p.z)),
    sceneSDF(vec3(p.x, p.y, p.z + e)) - sceneSDF(vec3(p.x, p.y, p.z - e))
  ));
}

// Ray march through the scene
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

  // Camera setup
  vec3 ro = vec3(0.0, 0.0, 3.0); // Ray origin (camera position)
  vec3 rd = normalize(vec3(uv, -1.0)); // Ray direction

  // Ray march
  float t = rayMarch(ro, rd);

  // Shading
  vec3 col = vec3(0.05, 0.05, 0.1); // Background color

  if (t < 100.0) {
    vec3 p = ro + rd * t;
    vec3 n = calcNormal(p);

    // Lighting
    vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
    float diff = max(dot(n, lightDir), 0.0);
    float amb = 0.2;

    // Phong specular
    vec3 viewDir = normalize(ro - p);
    vec3 reflectDir = reflect(-lightDir, n);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);

    vec3 baseColor = vec3(0.8, 0.4, 0.2);
    col = baseColor * (amb + diff) + vec3(1.0) * spec * 0.5;
  }

  // Gamma correction
  col = pow(col, vec3(0.4545));

  fragColor = vec4(col, 1.0);
}
''';

class GlCanvas extends StatefulWidget {
  const GlCanvas({super.key});

  @override
  State<GlCanvas> createState() => _GlCanvasState();
}

class _GlCanvasState extends State<GlCanvas> {
  static const String _viewType = 'webgl-canvas';
  static bool _viewFactoryRegistered = false;

  web.HTMLCanvasElement? _canvas;
  web.WebGL2RenderingContext? _gl;
  web.WebGLProgram? _program;
  web.WebGLBuffer? _vertexBuffer;
  int _animationFrameId = 0;
  double _startTime = 0;
  double _width = 0;
  double _height = 0;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
  }

  void _registerViewFactory() {
    if (_viewFactoryRegistered) return;
    _viewFactoryRegistered = true;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      _canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
      _canvas!.style.width = '100%';
      _canvas!.style.height = '100%';

      _setupContextListeners();
      _initWebGL();

      return _canvas!;
    });
  }

  void _setupContextListeners() {
    _canvas?.addEventListener(
      'webglcontextlost',
      (web.Event event) {
        event.preventDefault();
        _stopRenderLoop();
      }.toJS,
    );

    _canvas?.addEventListener(
      'webglcontextrestored',
      (web.Event event) {
        _initWebGL();
      }.toJS,
    );
  }

  void _initWebGL() {
    _gl = _canvas?.getContext('webgl2') as web.WebGL2RenderingContext?;
    if (_gl == null) return;

    _setupShaders();
    _setupGeometry();
    _startRenderLoop();
  }

  void _setupShaders() {
    web.WebGL2RenderingContext gl = _gl!;

    // Create and compile vertex shader
    web.WebGLShader vertexShader = gl.createShader(
      web.WebGL2RenderingContext.VERTEX_SHADER,
    )!;
    gl.shaderSource(vertexShader, _vertexShaderSource);
    gl.compileShader(vertexShader);

    if (!(gl.getShaderParameter(
            vertexShader,
            web.WebGL2RenderingContext.COMPILE_STATUS,
          )! as JSBoolean)
        .toDart) {
      print('Vertex shader error: ${gl.getShaderInfoLog(vertexShader)}');
      return;
    }

    // Create and compile fragment shader
    web.WebGLShader fragmentShader = gl.createShader(
      web.WebGL2RenderingContext.FRAGMENT_SHADER,
    )!;
    gl.shaderSource(fragmentShader, _fragmentShaderSource);
    gl.compileShader(fragmentShader);

    if (!(gl.getShaderParameter(
            fragmentShader,
            web.WebGL2RenderingContext.COMPILE_STATUS,
          )! as JSBoolean)
        .toDart) {
      print('Fragment shader error: ${gl.getShaderInfoLog(fragmentShader)}');
      return;
    }

    // Create and link program
    _program = gl.createProgram()!;
    gl.attachShader(_program!, vertexShader);
    gl.attachShader(_program!, fragmentShader);
    gl.linkProgram(_program!);

    if (!(gl.getProgramParameter(
            _program!,
            web.WebGL2RenderingContext.LINK_STATUS,
          )! as JSBoolean)
        .toDart) {
      print('Program link error: ${gl.getProgramInfoLog(_program!)}');
      return;
    }

    gl.useProgram(_program!);

    // Clean up shaders (no longer needed after linking)
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);
  }

  void _setupGeometry() {
    web.WebGL2RenderingContext gl = _gl!;

    // Full-screen quad vertices
    List<double> vertices = [-1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, 1.0];

    _vertexBuffer = gl.createBuffer()!;
    gl.bindBuffer(web.WebGL2RenderingContext.ARRAY_BUFFER, _vertexBuffer!);
    gl.bufferData(
      web.WebGL2RenderingContext.ARRAY_BUFFER,
      Float32List.fromList(vertices).toJS,
      web.WebGL2RenderingContext.STATIC_DRAW,
    );

    int positionLocation = gl.getAttribLocation(_program!, 'a_position');
    gl.enableVertexAttribArray(positionLocation);
    gl.vertexAttribPointer(
      positionLocation,
      2,
      web.WebGL2RenderingContext.FLOAT,
      false,
      0,
      0,
    );
  }

  void _startRenderLoop() {
    _startTime = _getCurrentTime();
    _renderFrame();
  }

  void _stopRenderLoop() {
    if (_animationFrameId != 0) {
      web.window.cancelAnimationFrame(_animationFrameId);
      _animationFrameId = 0;
    }
  }

  double _getCurrentTime() {
    return web.window.performance.now() / 1000.0;
  }

  void _renderFrame() {
    _render();
    _animationFrameId = web.window.requestAnimationFrame(
      ((JSNumber timestamp) {
        _renderFrame();
      }).toJS,
    );
  }

  void _render() {
    if (_gl == null || _program == null) return;

    web.WebGL2RenderingContext gl = _gl!;
    double time = _getCurrentTime() - _startTime;

    // Set uniforms
    web.WebGLUniformLocation? resolutionLocation = gl.getUniformLocation(
      _program!,
      'u_resolution',
    );
    web.WebGLUniformLocation? timeLocation = gl.getUniformLocation(
      _program!,
      'u_time',
    );

    gl.uniform2f(resolutionLocation, _width, _height);
    gl.uniform1f(timeLocation, time);

    // Clear and draw
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(web.WebGL2RenderingContext.COLOR_BUFFER_BIT);
    gl.drawArrays(web.WebGL2RenderingContext.TRIANGLE_STRIP, 0, 4);
  }

  void _updateSize(double width, double height) {
    if (_canvas == null || _gl == null) return;

    double dpr = web.window.devicePixelRatio;
    int pixelWidth = (width * dpr).toInt();
    int pixelHeight = (height * dpr).toInt();

    _canvas!.width = pixelWidth;
    _canvas!.height = pixelHeight;
    _width = pixelWidth.toDouble();
    _height = pixelHeight.toDouble();

    _gl!.viewport(0, 0, pixelWidth, pixelHeight);
  }

  @override
  void dispose() {
    _stopRenderLoop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateSize(constraints.maxWidth, constraints.maxHeight);
        });

        return HtmlElementView(viewType: _viewType);
      },
    );
  }
}
