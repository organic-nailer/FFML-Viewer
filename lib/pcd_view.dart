import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';

class PcdView extends StatefulWidget {
  final Size canvasSize;
  final Matrix4 transform;
  final Float32Array vertices;
  const PcdView(
      {Key? key,
      required this.canvasSize,
      required this.vertices,
      required this.transform})
      : super(key: key);

  @override
  State<PcdView> createState() => _PcdViewState();
}

class _PcdViewState extends State<PcdView> {
  late FlutterGlPlugin _flutterGlPlugin;
  late dynamic _glProgram;
  late Future<void> _glFuture;

  @override
  void initState() {
    super.initState();
    _glFuture = setupGL();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _glFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          render();
          return Container(
            width: widget.canvasSize.width,
            height: widget.canvasSize.height,
            color: Colors.yellowAccent,
            child: HtmlElementView(
              viewType: _flutterGlPlugin.textureId!.toString(),
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
    _glProgram = initGL(gl, widget.vertices);
  }

  void render() {
    final gl = _flutterGlPlugin.gl;
    final size = widget.canvasSize;
    final color = Colors.black;
    final verticesLength = widget.vertices.length ~/ 3;
    // set transform
    final transformLoc = gl.getUniformLocation(_glProgram, 'transform');
    // final matrix = Float32Array.fromList([
    //   1, 0, 0, 0.5,
    //   0, 1, 0, 0,
    //   0, 0, 1, 0,
    //   0, 0, 0, 1,
    // ]);
    gl.uniformMatrix4fv(transformLoc, false, widget.transform.storage);

    gl.viewport(0, 0, size.width, size.height);
    gl.clearColor(color.red / 255, color.green / 255, color.blue / 255, 1);
    gl.clear(gl.COLOR_BUFFER_BIT);
    // gl.drawArrays(gl.TRIANGLES, 0, 3);
    gl.drawArrays(gl.POINTS, 0, verticesLength);

    gl.finish();
  }
}

dynamic initGL(dynamic gl, Float32Array vertices) {
  const vertexShaderSource = """#version 300 es
#define attribute in
#define varying out
attribute vec3 a_Position;
uniform mat4 transform;
void main() {
  gl_Position = transform * vec4(a_Position, 1.0);
  gl_PointSize = 1.0;
}
""";
  const fragmentShaderSource = """#version 300 es
out highp vec4 pc_fragColor;
#define gl_FragColor pc_fragColor

void main() {
  gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);
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

  // final vertices = Float32Array.fromList([
  //   -0.5,
  //   -0.5,
  //   0,
  //   0.5,
  //   -0.5,
  //   0,
  //   0,
  //   0.5,
  //   0,
  //   0,
  //   0,
  //   0,
  // ]);

  final vao = gl.createVertexArray();
  gl.bindVertexArray(vao);

  final vertexBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, vertices.length, vertices, gl.STATIC_DRAW);

  final aPosition = gl.getAttribLocation(glProgram, 'a_Position');
  gl.enableVertexAttribArray(aPosition);
  gl.vertexAttribPointer(
      aPosition, 3, gl.FLOAT, false, Float32List.bytesPerElement * 3, 0);

  return glProgram;
}
