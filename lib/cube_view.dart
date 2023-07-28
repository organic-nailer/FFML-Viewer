import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

import 'package:flutter/gestures.dart' hide Matrix4;
import 'package:flutter/material.dart' hide Matrix4;
import 'package:flutter_gl/flutter_gl.dart';
import 'package:vector_math/vector_math.dart' show Vector3, Vector4, Matrix4;

(Float32Array, Float32Array) genTetrahedron() {
  final a = [0.0,0.5,0.5];
  final b = [-0.5,-0.5,0.5];
  final c = [0.0,0.0,-0.5];
  final d = [0.5,-0.5,0.5];
  final vertices = Float32Array.fromList([
    ...a, ...b, ...c,
    ...a, ...d, ...c,
    ...b, ...c, ...d,
    ...a, ...b, ...d,
  ]);

  final white = [1.0,1.0,1.0];
  final red = [1.0,0.0,0.0];
  final green = [0.0,1.0,0.0];
  final blue = [0.0,0.0,1.0];
  final colors = Float32Array.fromList([
    ...white, ...white, ...white,
    ...red, ...red, ...red,
    ...green, ...green, ...green,
    ...blue, ...blue, ...blue,
  ]);
  return (vertices, colors);
}

(Float32Array, Float32Array) genCube(int sidePts) {
  // x y z
  final resultXYZ = Float32Array(sidePts * sidePts * sidePts * 3);
  for (var x = 0; x < sidePts; x++) {
    for (var y = 0; y < sidePts; y++) {
      for (var z = 0; z < sidePts; z++) {
        final index = x * sidePts * sidePts + y * sidePts + z;
        resultXYZ[index * 3 + 0] = x / (sidePts - 1) - 0.5;
        resultXYZ[index * 3 + 1] = y / (sidePts - 1) - 0.5;
        resultXYZ[index * 3 + 2] = z / (sidePts - 1) - 0.5;
      }
    }
  }
  // r g b
  final resultRGB = Float32Array(sidePts * sidePts * sidePts * 3);
  for (var x = 0; x < sidePts; x++) {
    for (var y = 0; y < sidePts; y++) {
      for (var z = 0; z < sidePts; z++) {
        final index = x * sidePts * sidePts + y * sidePts + z;
        resultRGB[index * 3 + 0] = x / (sidePts - 1);
        resultRGB[index * 3 + 1] = y / (sidePts - 1);
        resultRGB[index * 3 + 2] = z / (sidePts - 1);
      }
    }
  }
  print("done");
  return (resultXYZ, resultRGB);
}

class CubePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final (vertices, colors) = genTetrahedron();
    return Scaffold(
      body: LayoutBuilder(
        builder: ((context, constraints) {
          final canvasSize = constraints.biggest;
          return CubeView(
            canvasSize: canvasSize,
            vertices: vertices,
            colors: colors,
            maxPointNum: vertices.length ~/ 3,
            backgroundColor: Colors.grey.shade500,
          );
        }),
      ),
    );
  }
}

class CubeView extends StatefulWidget {
  final Size canvasSize;
  final Float32Array vertices;
  final Float32Array colors;
  final int maxPointNum;
  final Color backgroundColor;
  const CubeView(
      {Key? key,
      required this.canvasSize,
      required this.vertices,
      required this.colors,
      int? maxPointNum,
      this.backgroundColor = Colors.black})
      : maxPointNum = maxPointNum ?? vertices.length ~/ 3, super(key: key);

  @override
  State<CubeView> createState() => _CubeViewState();
}

class _CubeViewState extends State<CubeView> {
  late FlutterGlPlugin _flutterGlPlugin;
  late dynamic _defaultFrameBuffer;
  late dynamic _sourceTexture;
  late dynamic _glProgram;
  late dynamic _posBuffer;
  late dynamic _colBuffer;
  late Future<void> _glFuture;
  final Matrix4 _viewingTransform = getViewingTransform(
    Vector3(0, 0, 6),
    Vector3(0, 0, 0),
    Vector3(0, 1, 0),
  );
  late Matrix4 _projectiveTransform;

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
      -300,
    );
  }

  @override
  void dispose() {
    _flutterGlPlugin.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CubeView oldWidget) {
    if (oldWidget.vertices != widget.vertices) {
      updateVertices(widget.vertices, widget.colors);
    }
    if (oldWidget.canvasSize != widget.canvasSize) {
      _projectiveTransform = getProjectiveTransform(
        30 * math.pi / 180,
        widget.canvasSize.width / widget.canvasSize.height,
        -0.01,
        -300,
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
          return GestureDetector(
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
              }
            },
            child: Container(
              width: widget.canvasSize.width,
              height: widget.canvasSize.height,
              color: widget.backgroundColor,
              child: Texture(textureId: _flutterGlPlugin.textureId!)
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
    await initGL(gl, widget.vertices, widget.colors);
  }

  Future<void> setupFBO() async {
    await _flutterGlPlugin.prepareContext();

    // setup default FrameBufferObject(FBO)
    final gl = _flutterGlPlugin.gl;
    final width = widget.canvasSize.width.toInt();
    final height = widget.canvasSize.height.toInt();

    _defaultFrameBuffer = gl.createFramebuffer();
    final defaultFrameBufferTexture = gl.createTexture();
    gl.activeTexture(gl.TEXTURE0);

    gl.bindTexture(gl.TEXTURE_2D, defaultFrameBufferTexture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA,
        gl.UNSIGNED_BYTE, null);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

    gl.bindFramebuffer(gl.FRAMEBUFFER, _defaultFrameBuffer);
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
    final verticesLength = widget.vertices.length ~/ 3;
    // set transform
    final transformLoc = gl.getUniformLocation(_glProgram, 'transform');
    final transform = _projectiveTransform *
        cameraMoveTransform *
        _viewingTransform *
        rotOriginTransform;
    // final transform = Matrix4.identity();
    gl.uniformMatrix4fv(transformLoc, false, transform.storage);

    // workaround for web: HTMLのcanvasの属性(width, height)を変更しないと、
    // WebGLの描画バッファの大きさが変わらないため、表示がおかしくなる
    // 参考: https://maku77.github.io/js/canvas/size.html
    final htmlCanvas = html.document.getElementById("canvas-id");
    if (htmlCanvas != null) {
      htmlCanvas as html.CanvasElement;
      htmlCanvas.width = size.width.toInt();
      htmlCanvas.height = size.height.toInt();
    }

    gl.viewport(0, 0, size.width.toInt(), size.height.toInt());
    gl.clearColor(color.red / 255, color.green / 255, color.blue / 255, 1);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    // gl.drawArrays(gl.TRIANGLES, 0, 3);
    gl.drawArrays(gl.TRIANGLES, 0, verticesLength);

    gl.finish();

    _flutterGlPlugin.updateTexture(_sourceTexture);
  }

  void updateVertices(Float32Array vertices, Float32Array colors) {
    final gl = _flutterGlPlugin.gl;
    updateBuffer(gl, _posBuffer, vertices);
    updateBuffer(gl, _colBuffer, colors);
  }

  dynamic initGL(dynamic gl, Float32Array vertices, Float32Array colors) {
    gl.enable(0x8642); // GL_PROGRAM_POINT_SIZE
    gl.enable(gl.DEPTH_TEST);
    const vertexShaderSource = """#version 150
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
    const fragmentShaderSource = """#version 150
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

    var _res = gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS);
    if (_res == 0 || _res == false) {
      print("Error compiling shader: ${gl.getShaderInfoLog(vertexShader)}");
      return;
    }

    final fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragmentShader, fragmentShaderSource);
    gl.compileShader(fragmentShader);

    _res = gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS);
    if (_res == 0 || _res == false) {
      print("Error compiling shader: ${gl.getShaderInfoLog(fragmentShader)}");
      return;
    }

    _glProgram = gl.createProgram();
    gl.attachShader(_glProgram, vertexShader);
    gl.attachShader(_glProgram, fragmentShader);
    gl.linkProgram(_glProgram);

    _res = gl.getProgramParameter(_glProgram, gl.LINK_STATUS);
    print(" initShaders LINK_STATUS _res: ${_res} ");
    if (_res == false || _res == 0) {
      print("Unable to initialize the shader program");
    }

    gl.useProgram(_glProgram);

    final vao = gl.createVertexArray();
    gl.bindVertexArray(vao);

    _posBuffer = setDataToAttribute(gl, _glProgram, widget.maxPointNum, vertices, "a_Position");
    _colBuffer = setDataToAttribute(gl, _glProgram, widget.maxPointNum, colors, "a_Color");

    // 1回だとうまく表示されないので、間をおいて再び呼び出す
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _posBuffer = setDataToAttribute(gl, _glProgram, widget.maxPointNum, vertices, "a_Position");
        _colBuffer = setDataToAttribute(gl, _glProgram, widget.maxPointNum, colors, "a_Color");
      });
    });
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

dynamic setDataToAttribute(
    dynamic gl, dynamic glProgram, int maxPointNum, Float32Array data, String attributeName) {
  final buffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  Float32Array initData = Float32Array(maxPointNum * 3);
  gl.bufferData(gl.ARRAY_BUFFER, initData.lengthInBytes, initData, gl.DYNAMIC_DRAW);
  gl.bufferSubData(gl.ARRAY_BUFFER, 0, data, 0, data.lengthInBytes);

  final attribute = gl.getAttribLocation(glProgram, attributeName);
  gl.enableVertexAttribArray(attribute);
  gl.vertexAttribPointer(
      attribute, 3, gl.FLOAT, false, Float32List.bytesPerElement * 3, 0);
  

  return buffer;
}

void updateBuffer(
  dynamic gl, dynamic buffer, Float32Array data
) {
  // bufferSubDataでは最初にBufferDataで指定したサイズ以上のデータを受け入れてくれないので注意
  // 最初に想定される最大サイズで初期化する必要がある
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.bufferSubData(gl.ARRAY_BUFFER, 0, data, 0, data.lengthInBytes);
}
