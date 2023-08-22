import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import 'package:flutter/gestures.dart' hide Matrix4;
import 'package:flutter/material.dart' hide Matrix4;
import 'package:flutter_gl/flutter_gl.dart';
import 'package:flutter_pcd/pcd_view/frame_buffer.dart';
import 'package:flutter_pcd/pcd_view/grid.dart';
import 'package:flutter_pcd/pcd_view/program.dart';
import 'package:vector_math/vector_math.dart' show Vector3, Vector4, Matrix4;

class PcdView extends StatefulWidget {
  final Size canvasSize;
  final Float32List vertices;
  final int maxPointNum;
  final double pointSize;
  final Color backgroundColor;
  const PcdView(
      {Key? key,
      required this.canvasSize,
      required this.vertices,
      int? maxPointNum,
      this.pointSize = 1.0,
      this.backgroundColor = Colors.black})
      : maxPointNum = maxPointNum ?? vertices.length ~/ 6, super(key: key);

  @override
  State<PcdView> createState() => _PcdViewState();
}

class _PcdViewState extends State<PcdView> {
  late FlutterGlPlugin _flutterGlPlugin;
  late FrameBuffer _frameBuffer;
  late PcdProgram _pcdProgram;
  late dynamic _vertexBuffer;
  late dynamic _vao;
  final GridBase _grid = VeloGrid();
  late Future<void> _glFuture;
  bool _isInitialized = false;
  final Matrix4 _viewingTransform = getViewingTransform(
    Vector3(0, 0, 3),
    Vector3(0, 0, 0),
    Vector3(0, 1, 0),
  );
  late Matrix4 _projectiveTransform;
  double prevTrackPadZoomScale = 1.0;
  Offset currentTrackPadZoomPosition = Offset.zero;

  /// World Coordinate での原点中心の回転
  Matrix4 rotOriginTransform = Matrix4.identity();

  /// Camera Coordinate でのカメラの移動
  Matrix4 cameraMoveTransform = Matrix4.identity();

  @override
  void initState() {
    super.initState();
    _glFuture = setupGL();
    _projectiveTransform = getProjectiveTransform(
      30 * math.pi / 180,
      widget.canvasSize.width / widget.canvasSize.height,
      -0.01,
      -600,
    );
  }

  @override
  void dispose() {
    _flutterGlPlugin.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PcdView oldWidget) {
    if (!_flutterGlPlugin.isInitialized || !_isInitialized) return;
    if (oldWidget.vertices != widget.vertices) {
      updateVertices(widget.vertices);
    }
    if (oldWidget.canvasSize != widget.canvasSize) {
      _projectiveTransform = getProjectiveTransform(
        30 * math.pi / 180,
        widget.canvasSize.width / widget.canvasSize.height,
        -0.01,
        -600,
      );
      updateFBO(widget.canvasSize);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _glFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.done) {
          render();
          return Listener(
            onPointerSignal: (signal) {
              if (signal is PointerScrollEvent) {
                // マウスホイールのスクロール
                // タッチパッドの2本指スクロール
                final zoom = signal.scrollDelta.dy;
                const zoomFactor = 0.001;
                viewZoom(
                    zoom * zoomFactor, signal.position.dx, signal.position.dy);
              } else if (signal is PointerScaleEvent) {
                // タッチパッドの2本指ピンチ
                final zoom = signal.scale;
                const zoomFactor = 1;
                viewZoom((zoom - 1) * zoomFactor, signal.position.dx,
                    signal.position.dy);
              }
            },
            child: GestureDetector(
              onScaleStart: (details) {
                prevTrackPadZoomScale = 1.0;
                currentTrackPadZoomPosition = details.focalPoint;
              },
              onScaleUpdate: (details) {
                if (details.scale == 1.0) {
                  // rotate
                  final move = details.focalPointDelta;
                  final moveFactor = 90 / widget.canvasSize.height;
                  final moveThetaX = move.dx * moveFactor * math.pi / 180;
                  final moveThetaY = move.dy * moveFactor * math.pi / 180;
                  final moveTransform = Matrix4.identity()
                    ..rotateX(moveThetaY)
                    ..rotateY(moveThetaX);
                  setState(() {
                    rotOriginTransform = moveTransform * rotOriginTransform;
                  });
                } else {
                  // zoom
                  if (kIsWeb) {
                    final zoom = details.scale;
                    const zoomFactor = 0.01;
                    viewZoom((zoom - 1) * zoomFactor, details.focalPoint.dx,
                        details.focalPoint.dy);
                  } else {
                    // Windowsの場合、なぜかscaleが前からの合算の値を渡してくるのでこちらがわでdeltaを計算する
                    // さらにdetails.focalPointがバグっているので使わない
                    final zoom = details.scale / prevTrackPadZoomScale;
                    const zoomFactor = 1;
                    viewZoom(
                        (zoom - 1) * zoomFactor,
                        currentTrackPadZoomPosition.dx,
                        currentTrackPadZoomPosition.dy);
                    prevTrackPadZoomScale = details.scale;
                  }
                }
              },
              onScaleEnd: (details) {
                prevTrackPadZoomScale = 1.0;
                currentTrackPadZoomPosition = Offset.zero;
              },
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
    await initGL(gl, widget.vertices);
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
    final verticesLength = widget.vertices.length ~/ 6;
    // set transform
    final transformLoc = _pcdProgram.getUniformTransform(gl);
    final transform = _projectiveTransform *
        cameraMoveTransform *
        _viewingTransform *
        rotOriginTransform;
    gl.uniformMatrix4fv(transformLoc, false, transform.storage);
    gl.uniform1f(_pcdProgram.getUniformPointSize(gl), widget.pointSize);

    _frameBuffer.bind(gl, () {
      gl.viewport(0, 0, size.width.toInt(), size.height.toInt());
      gl.clearColor(color.red / 255, color.green / 255, color.blue / 255, 1);
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
      // gl.drawArrays(gl.TRIANGLES, 0, 3);
    
      // draw grid
      _grid.draw(gl);

      gl.bindVertexArray(_vao);
      gl.drawArrays(gl.POINTS, 0, verticesLength);
      gl.bindVertexArray(0);
    });

    gl.finish();

    if (!kIsWeb) {
      _flutterGlPlugin.updateTexture(_frameBuffer.sourceTexture);
    }
  }

  void updateVertices(Float32List vertices) {
    final gl = _flutterGlPlugin.gl;
    updateBuffer(gl, _vertexBuffer, vertices);
  }

  void viewZoom(double zoomNormalized, double mousePosX, double mousePosY) {
    // print("zoomNormalized: ${zoomNormalized}");
    // ズーム時のマウス位置の方向にカメラを移動させる
    final mouseClipX = mousePosX / widget.canvasSize.width * 2 - 1;
    final mouseClipY = -(mousePosY / widget.canvasSize.height * 2 - 1);
    final invMat = Matrix4.inverted(_projectiveTransform);
    Vector4 forwarding = invMat * Vector4(mouseClipX, mouseClipY, 0, 1);
    forwarding = forwarding / forwarding.w;
    Vector3 forwarding3 = forwarding.xyz.normalized();

    // カメラ位置が世界座標の原点を超えないよう移動量を制限する
    final worldOrigin =
        (cameraMoveTransform * _viewingTransform * rotOriginTransform) *
            Vector4(0, 0, 0, 1);

    // print("forwarding: ${forwarding3}");
    // print("worldOrigin: ${worldOrigin}");
    final d = forwarding3.dot(worldOrigin.xyz) / forwarding3.length;
    // print("d: ${d}");
    final moveFactor = d * 0.5;

    final translate = Matrix4.identity();
    translate.setTranslation(-forwarding3 * zoomNormalized * moveFactor);

    setState(() {
      cameraMoveTransform = translate * cameraMoveTransform;
    });
  }

  Future<void> initGL(dynamic gl, Float32List vertices) async {
    _pcdProgram = PcdProgram(gl);
    _pcdProgram.use(gl);

    _vertexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, _vertexBuffer);
    Float32Array initData = Float32Array(widget.maxPointNum * 6);
    if (kIsWeb) {
      gl.bufferData(gl.ARRAY_BUFFER, initData.length, initData, gl.DYNAMIC_DRAW);
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, vertices, 0, vertices.length);
    } else {
      gl.bufferData(gl.ARRAY_BUFFER, initData.lengthInBytes, initData, gl.DYNAMIC_DRAW);
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, vertices, 0, vertices.lengthInBytes);
    }

    final attrPosition = _pcdProgram.getAttrPosition(gl);
    final attrColor = _pcdProgram.getAttrColor(gl);

    _vao = gl.createVertexArray();
    gl.bindVertexArray(_vao); {
      // なぜかこの順番で呼ぶと動く
      gl.bindBuffer(gl.ARRAY_BUFFER, _vertexBuffer);
      gl.vertexAttribPointer(attrPosition, 3, gl.FLOAT, false, 6 * Float32List.bytesPerElement, 0);
      gl.enableVertexAttribArray(attrPosition);
      gl.vertexAttribPointer(attrColor, 3, gl.FLOAT, false, 
        6 * Float32List.bytesPerElement, 3 * Float32List.bytesPerElement);
      gl.enableVertexAttribArray(attrColor);
      gl.vertexAttribPointer(attrPosition, 3, gl.FLOAT, false, 6 * Float32List.bytesPerElement, 0);
      gl.vertexAttribPointer(attrColor, 3, gl.FLOAT, false, 
        6 * Float32List.bytesPerElement, 3 * Float32List.bytesPerElement);
    } gl.bindVertexArray(0);

    // grid
    _grid.prepareVAO(gl, attrPosition, attrColor);
  }
}

/// LookAt方式のビュー変換行列を返す
/// パラメータは世界座標系
Matrix4 getViewingTransform(
    Vector3 cameraPosition, Vector3 lookAt, Vector3 up) {
  final zAxis = (cameraPosition - lookAt).normalized();
  final xAxis = up.cross(zAxis).normalized();
  final yAxis = zAxis.cross(xAxis).normalized();
  final translation = Matrix4.identity();
  translation.setTranslation(-cameraPosition);
  final rotation = Matrix4.identity();
  rotation.setRow(0, Vector4(xAxis.x, xAxis.y, xAxis.z, 0));
  rotation.setRow(1, Vector4(yAxis.x, yAxis.y, yAxis.z, 0));
  rotation.setRow(2, Vector4(zAxis.x, zAxis.y, zAxis.z, 0));

  /// カメラ周りの回転なので平行移動を先に行う
  return rotation * translation;
}

Matrix4 getProjectiveTransform(
    double fovY, double aspect, double near, double far) {
  final f = 1 / math.tan(fovY / 2);
  final z = (far + near) / (near - far);
  final w = -2 * far * near / (near - far);
  return Matrix4(
    f / aspect, 0, 0, 0,
    0         , f, 0, 0,
    0         , 0, z, w,
    0         , 0,-1, 0,
  ).transposed();
}

void updateBuffer(
  dynamic gl, dynamic buffer, dynamic data
) {
  // bufferSubDataでは最初にBufferDataで指定したサイズ以上のデータを受け入れてくれないので注意
  // 最初に想定される最大サイズで初期化する必要がある
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  if (kIsWeb) {
    gl.bufferSubData(gl.ARRAY_BUFFER, 0, data, 0, data.length);
  } else {
    gl.bufferSubData(gl.ARRAY_BUFFER, 0, data, 0, data.lengthInBytes);
  }
}
