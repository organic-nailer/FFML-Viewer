import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3, Vector4;

class PcdView extends StatefulWidget {
  final Size canvasSize;
  final Float32Array vertices;
  final Float32Array colors;
  const PcdView(
      {Key? key,
      required this.canvasSize,
      required this.vertices,
      required this.colors})
      : super(key: key);

  @override
  State<PcdView> createState() => _PcdViewState();
}

class _PcdViewState extends State<PcdView> {
  late FlutterGlPlugin _flutterGlPlugin;
  late dynamic _glProgram;
  late Future<void> _glFuture;
  final Matrix4 _viewingTransform = getViewingTransform(
    Vector3(0, 0, 3),
    Vector3(0, 0, 0),
    Vector3(0, 1, 0),
  );
  late Matrix4 _projectiveTransform;
  Matrix4 interactiveTransform = Matrix4.identity();

  @override
  void initState() {
    super.initState();
    _glFuture = setupGL();
  }

  @override
  Widget build(BuildContext context) {
    _projectiveTransform = getProjectiveTransform(
      30 * math.pi / 180,
      widget.canvasSize.width / widget.canvasSize.height,
      -1,
      -10,
    );
    return FutureBuilder(
      future: _glFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          render();
          return Listener(
            onPointerMove: (event) {
              final move = event.delta;
              final moveFactor = 90 / widget.canvasSize.height;
              final moveThetaX = move.dx * moveFactor * math.pi / 180;
              final moveThetaY = move.dy * moveFactor * math.pi / 180;
              final moveTransform = Matrix4.identity()
                ..rotateX(-moveThetaY)
                ..rotateY(-moveThetaX);
              setState(() {
                interactiveTransform = moveTransform * interactiveTransform;
              });
            },
            child: Container(
              width: widget.canvasSize.width,
              height: widget.canvasSize.height,
              color: Colors.yellowAccent,
              child: HtmlElementView(
                viewType: _flutterGlPlugin.textureId!.toString(),
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
      "width": widget.canvasSize.width,
      "height": widget.canvasSize.height,
      "dpr": 1.0,
    });
    final gl = _flutterGlPlugin.gl;
    _glProgram = initGL(gl, widget.vertices, widget.colors);
  }

  void render() {
    final gl = _flutterGlPlugin.gl;
    final size = widget.canvasSize;
    final color = Colors.black;
    final verticesLength = widget.vertices.length ~/ 3;
    // set transform
    final transformLoc = gl.getUniformLocation(_glProgram, 'transform');
    final transform = _projectiveTransform
      * _viewingTransform
      * interactiveTransform;
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

    gl.viewport(0, 0, size.width, size.height);
    gl.clearColor(color.red / 255, color.green / 255, color.blue / 255, 1);
    gl.clear(gl.COLOR_BUFFER_BIT);
    // gl.drawArrays(gl.TRIANGLES, 0, 3);
    gl.drawArrays(gl.POINTS, 0, verticesLength);

    gl.finish();
  }
}

dynamic initGL(dynamic gl, Float32Array vertices, Float32Array colors) {
  const vertexShaderSource = """#version 300 es
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
  const fragmentShaderSource = """#version 300 es
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

  final glProgram = gl.createProgram();
  gl.attachShader(glProgram, vertexShader);
  gl.attachShader(glProgram, fragmentShader);
  gl.linkProgram(glProgram);

  _res = gl.getProgramParameter(glProgram, gl.LINK_STATUS);
  print(" initShaders LINK_STATUS _res: ${_res} ");
  if (_res == false || _res == 0) {
    print("Unable to initialize the shader program");
  }

  gl.useProgram(glProgram);

  final vao = gl.createVertexArray();
  gl.bindVertexArray(vao);

  final vertexBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, vertices.length, vertices, gl.STATIC_DRAW);

  final aPosition = gl.getAttribLocation(glProgram, 'a_Position');
  gl.enableVertexAttribArray(aPosition);
  gl.vertexAttribPointer(
      aPosition, 3, gl.FLOAT, false, Float32List.bytesPerElement * 3, 0);

  final colorBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, colorBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, colors.length, colors, gl.STATIC_DRAW);

  final aColor = gl.getAttribLocation(glProgram, 'a_Color');
  gl.enableVertexAttribArray(aColor);
  gl.vertexAttribPointer(aColor, 3, gl.FLOAT, false, Float32List.bytesPerElement * 3, 0);

  return glProgram;
}

/// LookAt方式のビュー変換行列を返す
Matrix4 getViewingTransform(Vector3 cameraPosition, Vector3 lookAt, Vector3 up) {
  final zAxis = (cameraPosition - lookAt).normalized();
  final xAxis = up.cross(zAxis).normalized();
  final yAxis = zAxis.cross(xAxis).normalized();
  final translation = Matrix4.identity();
  translation.setTranslation(cameraPosition);
  final rotation = Matrix4.identity();
  rotation.setRow(0, Vector4(xAxis.x, yAxis.x, zAxis.x, 0));
  rotation.setRow(1, Vector4(xAxis.y, yAxis.y, zAxis.y, 0));
  rotation.setRow(2, Vector4(xAxis.z, yAxis.z, zAxis.z, 0));
  return rotation * translation;
}

Matrix4 getProjectiveTransform(double fovY, double aspect, double near, double far) {
  final f = 1 / math.tan(fovY / 2);
  final z = (far + near) / (near - far);
  final w = 2 * far * near / (near - far);
  return Matrix4(
    f / aspect, 0, 0, 0,
    0, f, 0, 0,
    0, 0, z, w,
    0, 0, -1, 0,
  );
}
