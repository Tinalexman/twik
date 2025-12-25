import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'package:twik/core/scene/scene.dart';
import 'package:twik/core/scene/shader_generator.dart';

class GlCanvas extends StatefulWidget {
  const GlCanvas({super.key, required this.scene});

  final Scene scene;

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
  double _lastFrameTime = 0;
  double _width = 0;
  double _height = 0;

  String _currentFragmentShader = '';
  bool _shaderNeedsRecompile = true;
  bool _isPointerLocked = false;

  final Set<LogicalKeyboardKey> _pressedKeys = {};
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.scene.addListener(_onSceneChanged);
    _registerViewFactory();
  }

  @override
  void didUpdateWidget(GlCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) {
      oldWidget.scene.removeListener(_onSceneChanged);
      widget.scene.addListener(_onSceneChanged);
      _shaderNeedsRecompile = true;
    }
  }

  void _onSceneChanged() {
    _shaderNeedsRecompile = true;
  }

  void _registerViewFactory() {
    if (_viewFactoryRegistered) return;
    _viewFactoryRegistered = true;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      _canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
      _canvas!.style.width = '100%';
      _canvas!.style.height = '100%';
      _canvas!.style.cursor = 'crosshair';

      _setupContextListeners();
      _setupInputListeners();
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

  void _setupInputListeners() {
    // Click to capture pointer
    _canvas?.addEventListener(
      'click',
      (web.Event event) {
        _canvas?.requestPointerLock();
      }.toJS,
    );

    // Pointer lock change
    web.document.addEventListener(
      'pointerlockchange',
      (web.Event event) {
        _isPointerLocked = web.document.pointerLockElement == _canvas;
        if (_isPointerLocked) {
          _canvas!.style.cursor = 'none';
        } else {
          _canvas!.style.cursor = 'crosshair';
        }
      }.toJS,
    );

    // Mouse move for camera rotation
    web.document.addEventListener(
      'mousemove',
      (web.Event event) {
        if (!_isPointerLocked) return;
        web.MouseEvent mouseEvent = event as web.MouseEvent;
        widget.scene.camera.rotate(
          mouseEvent.movementX.toDouble(),
          mouseEvent.movementY.toDouble(),
        );
      }.toJS,
    );
  }

  void _initWebGL() {
    _gl = _canvas?.getContext('webgl2') as web.WebGL2RenderingContext?;
    if (_gl == null) return;

    _setupGeometry();
    _startRenderLoop();
  }

  void _setupShaders() {
    if (_gl == null) return;
    web.WebGL2RenderingContext gl = _gl!;

    String newFragmentShader = ShaderGenerator.generateFragmentShader(widget.scene);

    // Skip if shader hasn't changed
    if (newFragmentShader == _currentFragmentShader && _program != null) {
      _shaderNeedsRecompile = false;
      return;
    }

    // Clean up old program
    if (_program != null) {
      gl.deleteProgram(_program!);
    }

    // Create and compile vertex shader
    web.WebGLShader vertexShader = gl.createShader(
      web.WebGL2RenderingContext.VERTEX_SHADER,
    )!;
    gl.shaderSource(vertexShader, ShaderGenerator.vertexShader);
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
    gl.shaderSource(fragmentShader, newFragmentShader);
    gl.compileShader(fragmentShader);

    if (!(gl.getShaderParameter(
            fragmentShader,
            web.WebGL2RenderingContext.COMPILE_STATUS,
          )! as JSBoolean)
        .toDart) {
      print('Fragment shader error: ${gl.getShaderInfoLog(fragmentShader)}');
      print('Generated shader:\n$newFragmentShader');
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

    // Clean up shaders
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);

    // Re-setup vertex attribute
    int positionLocation = gl.getAttribLocation(_program!, 'a_position');
    gl.enableVertexAttribArray(positionLocation);
    gl.bindBuffer(web.WebGL2RenderingContext.ARRAY_BUFFER, _vertexBuffer!);
    gl.vertexAttribPointer(
      positionLocation,
      2,
      web.WebGL2RenderingContext.FLOAT,
      false,
      0,
      0,
    );

    _currentFragmentShader = newFragmentShader;
    _shaderNeedsRecompile = false;
  }

  void _setupGeometry() {
    web.WebGL2RenderingContext gl = _gl!;

    List<double> vertices = [-1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, 1.0];

    _vertexBuffer = gl.createBuffer()!;
    gl.bindBuffer(web.WebGL2RenderingContext.ARRAY_BUFFER, _vertexBuffer!);
    gl.bufferData(
      web.WebGL2RenderingContext.ARRAY_BUFFER,
      Float32List.fromList(vertices).toJS,
      web.WebGL2RenderingContext.STATIC_DRAW,
    );
  }

  void _startRenderLoop() {
    _startTime = _getCurrentTime();
    _lastFrameTime = _startTime;
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

  void _handleInput(double deltaTime) {
    if (!_isPointerLocked) return;

    Camera camera = widget.scene.camera;

    if (_pressedKeys.contains(LogicalKeyboardKey.keyW)) {
      camera.moveForward(deltaTime);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS)) {
      camera.moveBackward(deltaTime);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA)) {
      camera.moveLeft(deltaTime);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD)) {
      camera.moveRight(deltaTime);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.space)) {
      camera.moveUp(deltaTime);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.shiftLeft) ||
        _pressedKeys.contains(LogicalKeyboardKey.shiftRight)) {
      camera.moveDown(deltaTime);
    }
  }

  void _renderFrame() {
    double currentTime = _getCurrentTime();
    double deltaTime = currentTime - _lastFrameTime;
    _lastFrameTime = currentTime;

    _handleInput(deltaTime);
    _render();

    _animationFrameId = web.window.requestAnimationFrame(
      ((JSNumber timestamp) {
        _renderFrame();
      }).toJS,
    );
  }

  void _render() {
    if (_gl == null) return;

    // Recompile shaders if needed
    if (_shaderNeedsRecompile) {
      _setupShaders();
    }

    if (_program == null) return;

    web.WebGL2RenderingContext gl = _gl!;
    double time = _getCurrentTime() - _startTime;

    gl.useProgram(_program!);

    // Set base uniforms
    _setUniform2f('u_resolution', _width, _height);
    _setUniform1f('u_time', time);

    // Set camera uniforms
    Camera camera = widget.scene.camera;
    _setUniform3f('u_cameraPos', camera.position.x, camera.position.y, camera.position.z);
    _setUniform3f('u_cameraDir', camera.direction.x, camera.direction.y, camera.direction.z);
    _setUniform3f('u_cameraRight', camera.right.x, camera.right.y, camera.right.z);
    _setUniform3f('u_cameraUp', camera.up.x, camera.up.y, camera.up.z);

    // Set node uniforms
    for (int i = 0; i < widget.scene.nodes.length; i++) {
      SdfNode node = widget.scene.nodes[i];
      _setUniform3f('u_node${i}_pos', node.position.x, node.position.y, node.position.z);
      _setUniform3f('u_node${i}_rot', node.rotation.x, node.rotation.y, node.rotation.z);
      _setUniform3f('u_node${i}_scale', node.scale.x, node.scale.y, node.scale.z);
      _setUniform3f('u_node${i}_color', node.material.r, node.material.g, node.material.b);
    }

    // Clear and draw
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(web.WebGL2RenderingContext.COLOR_BUFFER_BIT);
    gl.drawArrays(web.WebGL2RenderingContext.TRIANGLE_STRIP, 0, 4);
  }

  void _setUniform1f(String name, double value) {
    web.WebGLUniformLocation? loc = _gl!.getUniformLocation(_program!, name);
    if (loc != null) {
      _gl!.uniform1f(loc, value);
    }
  }

  void _setUniform2f(String name, double x, double y) {
    web.WebGLUniformLocation? loc = _gl!.getUniformLocation(_program!, name);
    if (loc != null) {
      _gl!.uniform2f(loc, x, y);
    }
  }

  void _setUniform3f(String name, double x, double y, double z) {
    web.WebGLUniformLocation? loc = _gl!.getUniformLocation(_program!, name);
    if (loc != null) {
      _gl!.uniform3f(loc, x, y, z);
    }
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

  void _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      // ESC to exit pointer lock
      if (event.logicalKey == LogicalKeyboardKey.escape && _isPointerLocked) {
        web.document.exitPointerLock();
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
  }

  @override
  void dispose() {
    _stopRenderLoop();
    widget.scene.removeListener(_onSceneChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateSize(constraints.maxWidth, constraints.maxHeight);
          });

          return HtmlElementView(viewType: _viewType);
        },
      ),
    );
  }
}
