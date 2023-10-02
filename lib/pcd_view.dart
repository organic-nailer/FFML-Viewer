import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:flutter_pcd/pcd_view/component/interactive_camera.dart';
import 'package:flutter_pcd/pcd_view/frame_buffer.dart';
import 'package:flutter_pcd/pcd_view/grid.dart';
import 'package:flutter_pcd/pcd_view/program.dart';
import 'package:flutter_pcd/pcd_view/vertex_buffer_manager.dart';

class PcdView extends StatefulWidget {
  final Size canvasSize;
  final Float32List vertices;
  final Float32List colors;
  final Float32List masks;
  final int maxPointNum;
  final double pointSize;
  final Color backgroundColor;
  const PcdView(
      {Key? key,
      required this.canvasSize,
      required this.vertices,
      required this.colors,
      required this.masks,
      int? maxPointNum,
      this.pointSize = 1.0,
      this.backgroundColor = Colors.black})
      : maxPointNum = maxPointNum ?? vertices.length ~/ 3,
        super(key: key);

  @override
  State<PcdView> createState() => _PcdViewState();
}

class _PcdViewState extends State<PcdView> {
  late FlutterGlPlugin _flutterGlPlugin;
  late FrameBuffer _frameBuffer;
  late PcdProgram _pcdProgram;
  late VertexBufferManager _vertexBufferManager;
  late GridBase _grid;
  late Future<void> _glFuture;
  bool _isInitialized = false;
  late final InteractiveCameraController controller;

  @override
  void initState() {
    super.initState();
    _glFuture = setupGL();
    controller = InteractiveCameraController(widget.canvasSize)..addListener(() {
      setState(() {});
      // print('update');
      // render();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _flutterGlPlugin.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PcdView oldWidget) {
    if (!_flutterGlPlugin.isInitialized || !_isInitialized) return;
    if (oldWidget.vertices != widget.vertices) {
      updateVertices(widget.vertices);
    }
    if (oldWidget.colors != widget.colors) {
      updateColors(widget.colors);
    }
    if (oldWidget.masks != widget.masks) {
      updateMasks(widget.masks!);
    }
    if (oldWidget.canvasSize != widget.canvasSize) {
      controller.updateCanvasSize(widget.canvasSize);
      updateFBO(widget.canvasSize);
    }
    super.didUpdateWidget(oldWidget);
    // render();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _glFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;
          if (error is Error) {
            return Text('Error: $error\n${error.stackTrace.toString()}');
          }
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.done) {
          render();
          return InteractiveCamera(
            controller: controller,
            child: Container(
              width: widget.canvasSize.width,
              height: widget.canvasSize.height,
              color: widget.backgroundColor,
              child: kIsWeb
                  ? HtmlElementView(
                      viewType: _flutterGlPlugin.textureId!.toString(),
                    )
                  : Texture(textureId: _flutterGlPlugin.textureId!),
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Future<void> setupGL() async {
    _flutterGlPlugin = FlutterGlPlugin();
    await _flutterGlPlugin.initialize(options: {
      "antialias": true,
      "alpha": false,
      "width": widget.canvasSize.width.toInt(),
      "height": widget.canvasSize.height.toInt(),
      "dpr": 1.0,
    });
    await Future.delayed(const Duration(milliseconds: 100));
    final gl = _flutterGlPlugin.gl;
    await setupFBO();
    await initGL(gl, widget.vertices, widget.colors, widget.masks);
    _isInitialized = true;
  }

  Future<void> updateFBO(Size size) async {
    // FlutterGlPlatform.instance.prepareContext();
    final gl = _flutterGlPlugin.gl;
    final width = size.width.toInt();
    final height = size.height.toInt();

    // recreate FBO
    _frameBuffer = FrameBuffer(gl, width, height);

    await _flutterGlPlugin.updateSize({
      "width": width,
      "height": height,
    });
  }

  Future<void> setupFBO() async {
    if (kIsWeb) return;

    await _flutterGlPlugin.prepareContext();

    // setup default FrameBufferObject(FBO)
    final gl = _flutterGlPlugin.gl;
    final width = widget.canvasSize.width.toInt();
    final height = widget.canvasSize.height.toInt();

    // create default FBO
    _frameBuffer = FrameBuffer(gl, width, height);
  }

  void render() async {
    final gl = _flutterGlPlugin.gl;
    final size = widget.canvasSize;
    final color = widget.backgroundColor;
    // set transform
    final transformLoc = _pcdProgram.getUniformTransform(gl);
    final transform = controller.synthesizedTransform;
    gl.uniformMatrix4fv(transformLoc, false, transform.storage);
    gl.uniform1f(_pcdProgram.getUniformPointSize(gl), widget.pointSize);

    _frameBuffer.bind(gl, () {
      gl.viewport(0, 0, size.width.toInt(), size.height.toInt());
      gl.clearColor(color.red / 255, color.green / 255, color.blue / 255, 1);
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
      // gl.drawArrays(gl.TRIANGLES, 0, 3);

      // draw grid
      _grid.draw(gl);

      // draw points
      _vertexBufferManager.draw(gl);
    });

    gl.finish();

    if (!kIsWeb) {
      _flutterGlPlugin.updateTexture(_frameBuffer.sourceTexture);
    }
  }

  void updateVertices(Float32List vertices) {
    final gl = _flutterGlPlugin.gl;
    _vertexBufferManager.updateVertices(gl, vertices);
  }

  void updateColors(Float32List colors) {
    final gl = _flutterGlPlugin.gl;
    _vertexBufferManager.updateColors(gl, colors);
  }

  void updateMasks(Float32List masks) {
    final gl = _flutterGlPlugin.gl;
    _vertexBufferManager.updateMasks(gl, masks);
  }

  Future<void> initGL(
      dynamic gl, Float32List vertices, Float32List colors, Float32List masks) async {
    _pcdProgram = PcdProgram(gl);
    _pcdProgram.use(gl);

    _vertexBufferManager = VertexBufferManager(
        gl, _pcdProgram, vertices, colors, masks, widget.maxPointNum);

    // grid
    _grid = VeloGrid(gl, _pcdProgram);
  }
}
