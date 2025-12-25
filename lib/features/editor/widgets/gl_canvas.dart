import 'dart:ui_web' as ui_web;
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class GlCanvas extends StatefulWidget {
  const GlCanvas({super.key});

  @override
  State<GlCanvas> createState() => _GlCanvasState();
}

class _GlCanvasState extends State<GlCanvas> {
  late web.HTMLCanvasElement _canvas;
  late web.WebGL2RenderingContext? _gl;

  web.WebGL2RenderingContext? get gl => _gl;

  @override
  void initState() {
    super.initState();
    _canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
    _canvas.style.width = "100%";
    _canvas.style.height = "100%";

    ui_web.platformViewRegistry.registerViewFactory(
      'webgl-_canvas',
      (_) => _canvas,
    );

    _setupContextListeners();
    _initWebGL();
  }


  void _setupContextListeners() {
    _canvas.addEventListener('webglcontextlost', (web.Event event) {
      event.preventDefault();
      print("WebGL Context Lost!");
      // Stop your animation timers here
    }.toJS);


    _canvas.addEventListener('webglcontextrestored', (web.Event event) {
      _initWebGL();
      _render();
    }.toJS);
  }

  void _initWebGL() {
    _gl = _canvas.getContext('webgl2') as web.WebGL2RenderingContext?;
    _render();
  }

  void _updateSize(double width, double height) {
    double dpr = web.window.devicePixelRatio;
    _canvas.width = (width * dpr).toInt();
    _canvas.height = (height * dpr).toInt();

    _gl?.viewport(0, 0, _canvas.width, _canvas.height);

    _render();
  }


  void _render() {
    _gl?.clearColor(0.0, 0.5, 0.8, 1.0);
    _gl?.clear(web.WebGLRenderingContext.COLOR_BUFFER_BIT);
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateSize(constraints.maxWidth, constraints.maxHeight);
        });

        return HtmlElementView(viewType: 'webgl-view');
      },
    );
  }
}
