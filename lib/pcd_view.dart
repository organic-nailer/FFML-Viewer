import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

import 'package:flutter/gestures.dart' hide Matrix4;
import 'package:flutter/material.dart' hide Matrix4;
import 'package:flutter_gl/flutter_gl.dart';
import 'package:vector_math/vector_math.dart' show Vector3, Vector4, Matrix4;

class PcdView extends StatefulWidget {
  final Size canvasSize;
  final Float32List vertices;
  final int maxPointNum;
  final Color backgroundColor;
  const PcdView(
      {Key? key,
      required this.canvasSize,
      required this.vertices,
      int? maxPointNum,
      this.backgroundColor = Colors.black})
      : maxPointNum = maxPointNum ?? vertices.length ~/ 6, super(key: key);

  @override
  State<PcdView> createState() => _PcdViewState();
}

class _PcdViewState extends State<PcdView> {
  late FlutterGlPlugin _flutterGlPlugin;
  late dynamic _defaultFrameBuffer;
  late dynamic _sourceTexture;
  late dynamic _glProgram;
  late dynamic _vertexBuffer;
  late dynamic _vao;
  late dynamic _vaoGrid;
  late int _gridPointNum;
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
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _glFuture,
      builder: (context, snapshot) {
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

  Future<void> setupFBO() async {
    if (kIsWeb) return;

    await _flutterGlPlugin.prepareContext();

    // setup default FrameBufferObject(FBO)
    final gl = _flutterGlPlugin.gl;
    final width = widget.canvasSize.width.toInt();
    final height = widget.canvasSize.height.toInt();

    // create default FBO
    _defaultFrameBuffer = gl.createFramebuffer();
    gl.bindFramebuffer(gl.FRAMEBUFFER, _defaultFrameBuffer);

    // create default texture
    final defaultFrameBufferTexture = gl.createTexture();
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, defaultFrameBufferTexture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA,
        gl.UNSIGNED_BYTE, null);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D,
        defaultFrameBufferTexture, 0);

    // bind depth texture
    final depthTexture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, depthTexture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE); // Required for non-power-of-2 textures
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE); // Required for non-power-of-2 textures
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.DEPTH_COMPONENT, width, height, 0,
        gl.DEPTH_COMPONENT, gl.UNSIGNED_SHORT, null);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT,
        gl.TEXTURE_2D, depthTexture, 0);

    _sourceTexture = defaultFrameBufferTexture;
  }

  void render() async {
    final gl = _flutterGlPlugin.gl;
    final size = widget.canvasSize;
    final color = widget.backgroundColor;
    final verticesLength = widget.vertices.length ~/ 6;
    // set transform
    final transformLoc = gl.getUniformLocation(_glProgram, 'transform');
    final transform = _projectiveTransform *
        cameraMoveTransform *
        _viewingTransform *
        rotOriginTransform;
    gl.uniformMatrix4fv(transformLoc, false, transform.storage);

    if (kIsWeb) {
      // workaround for web: HTMLのcanvasの属性(width, height)を変更しないと、
      // WebGLの描画バッファの大きさが変わらないため、表示がおかしくなる
      // 参考: https://maku77.github.io/js/canvas/size.html
      final htmlCanvas = html.document.getElementById("canvas-id");
      if (htmlCanvas != null) {
        htmlCanvas as html.CanvasElement;
        htmlCanvas.width = size.width.toInt();
        htmlCanvas.height = size.height.toInt();
      }
    }

    gl.viewport(0, 0, size.width.toInt(), size.height.toInt());
    gl.clearColor(color.red / 255, color.green / 255, color.blue / 255, 1);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    // gl.drawArrays(gl.TRIANGLES, 0, 3);
    
    gl.bindVertexArray(_vaoGrid);
    gl.drawArrays(gl.LINES, 0, _gridPointNum);
    gl.bindVertexArray(0);


    gl.bindVertexArray(_vao);
    gl.drawArrays(gl.POINTS, 0, verticesLength);
    gl.bindVertexArray(0);

    gl.finish();

    if (!kIsWeb) {
      _flutterGlPlugin.updateTexture(_sourceTexture);
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

  dynamic initGL(dynamic gl, Float32List vertices) {
    gl.enable(0x8642); // GL_PROGRAM_POINT_SIZE
    gl.enable(gl.DEPTH_TEST);
    const vertexShaderSource = """#version ${kIsWeb ? "300 es" : "150"}
#define attribute in
#define varying out
attribute vec3 a_Position;
attribute vec3 a_Color;
uniform mat4 transform;
varying vec3 v_Color;
void main() {
  gl_Position = transform * vec4(a_Position, 1.0);
  gl_PointSize = 5.0;
  v_Color = a_Color;
}
""";
    const fragmentShaderSource = """#version ${kIsWeb ? "300 es" : "150"}
out highp vec4 pc_fragColor;
#define gl_FragColor pc_fragColor
#define varying in

precision highp float;
varying vec3 v_Color;

void main() {
  gl_FragColor = vec4(v_Color, 1.0);
}
""";

    final vertexShader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertexShader, vertexShaderSource);
    gl.compileShader(vertexShader);

    var res = gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS);
    if (res == 0 || res == false) {
      throw Exception("Error compiling shader: ${gl.getShaderInfoLog(vertexShader)}");
    }

    final fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragmentShader, fragmentShaderSource);
    gl.compileShader(fragmentShader);

    res = gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS);
    if (res == 0 || res == false) {
      throw Exception("Error compiling shader: ${gl.getShaderInfoLog(fragmentShader)}");
    }

    _glProgram = gl.createProgram();
    gl.attachShader(_glProgram, vertexShader);
    gl.attachShader(_glProgram, fragmentShader);
    gl.linkProgram(_glProgram);

    res = gl.getProgramParameter(_glProgram, gl.LINK_STATUS);
    if (res == false || res == 0) {
      throw Exception("Unable to initialize the shader program");
    }

    gl.useProgram(_glProgram);

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

    _vao = gl.createVertexArray();
    gl.bindVertexArray(_vao); {
      // なぜかこの順番で呼ぶと動く
      final attrPos = gl.getAttribLocation(_glProgram, "a_Position");
      final attrCol = gl.getAttribLocation(_glProgram, "a_Color");
      gl.bindBuffer(gl.ARRAY_BUFFER, _vertexBuffer);
      gl.vertexAttribPointer(attrPos, 3, gl.FLOAT, false, 6 * Float32List.bytesPerElement, 0);
      gl.enableVertexAttribArray(attrPos);
      gl.vertexAttribPointer(attrCol, 3, gl.FLOAT, false, 
        6 * Float32List.bytesPerElement, 3 * Float32List.bytesPerElement);
      gl.enableVertexAttribArray(attrCol);
      gl.vertexAttribPointer(attrPos, 3, gl.FLOAT, false, 6 * Float32List.bytesPerElement, 0);
      gl.vertexAttribPointer(attrCol, 3, gl.FLOAT, false, 
        6 * Float32List.bytesPerElement, 3 * Float32List.bytesPerElement);
    } gl.bindVertexArray(0);

    // grid
    final grid = genGrid();
    _gridPointNum = grid.length ~/ 6;
    final gridBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, gridBuffer);
    if (kIsWeb) {
      gl.bufferData(gl.ARRAY_BUFFER, grid.length, grid, gl.STATIC_DRAW);
    } else {
      gl.bufferData(gl.ARRAY_BUFFER, grid.lengthInBytes, grid, gl.STATIC_DRAW);
    }

    _vaoGrid = gl.createVertexArray();
    gl.bindVertexArray(_vaoGrid); {
      gl.bindBuffer(gl.ARRAY_BUFFER, gridBuffer);
      final attrPos = gl.getAttribLocation(_glProgram, "a_Position");
      final attrCol = gl.getAttribLocation(_glProgram, "a_Color");
      gl.vertexAttribPointer(attrPos, 3, gl.FLOAT, false, 6 * Float32List.bytesPerElement, 0);
      gl.enableVertexAttribArray(attrPos);
      gl.vertexAttribPointer(attrCol, 3, gl.FLOAT, false, 
        6 * Float32List.bytesPerElement, 3 * Float32List.bytesPerElement);
      gl.enableVertexAttribArray(attrCol);
      gl.vertexAttribPointer(attrPos, 3, gl.FLOAT, false, 6 * Float32List.bytesPerElement, 0);
      gl.vertexAttribPointer(attrCol, 3, gl.FLOAT, false, 
        6 * Float32List.bytesPerElement, 3 * Float32List.bytesPerElement);
    } gl.bindVertexArray(0);
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

Float32List genGrid() {
  const color = Colors.white54;
  const z = 0.0;
  List<double> genLineXY(double x0, double y0, double x1, double y1) {
    return [
      x0, y0, z, color.red / 255, color.green / 255, color.blue / 255,
      x1, y1, z, color.red / 255, color.green / 255, color.blue / 255,
    ];
  }
  List<double> genCircle(double cx, double cy, double r, int segments) {
    final result = <double>[];
    for (var i = 0; i < segments; i++) {
      final theta0 = 2 * math.pi * i / segments;
      final theta1 = 2 * math.pi * (i + 1) / segments;
      result.addAll(genLineXY(
        cx + r * math.cos(theta0), cy + r * math.sin(theta0),
        cx + r * math.cos(theta1), cy + r * math.sin(theta1),
      ));
    }
    return result;
  }
  const minX = -100;
  const maxX = 100;
  const minY = -100;
  const maxY = 100;
  const interval = 10;
  final result = <double>[];
  for (var x = minX; x <= maxX; x += interval) {
    result.addAll(genLineXY(x.toDouble(), minY.toDouble(), x.toDouble(), maxY.toDouble()));
  }
  for (var y = minY; y <= maxY; y += interval) {
    result.addAll(genLineXY(minX.toDouble(), y.toDouble(), maxX.toDouble(), y.toDouble()));
  }
  for (var r = 10; r <= 100; r += 10) {
    result.addAll(genCircle(0, 0, r.toDouble(), 100));
  }
  return Float32List.fromList(result);
}
