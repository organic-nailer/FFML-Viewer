import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
// import 'package:vector_math/vector_math.dart' hide Colors;

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late FlutterGlPlugin _flutterGlPlugin;
  late dynamic _glProgram;
  late Future<void> _glFuture;

  @override
  void initState() {
    super.initState();
    _glFuture = setupGL();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final randomColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
      final phaseRad = (timer.tick * 0.03 * math.pi) % (2 * math.pi);
      render(_flutterGlPlugin.gl, _glProgram, randomColor, phaseRad);
    });
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        body: Center(
          child: FutureBuilder(
            future: _glFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Container(
                  width: 300,
                  height: 300,
                  color: Colors.yellowAccent,
                  child: HtmlElementView(
                    viewType: _flutterGlPlugin.textureId!.toString(),
                  )
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
          )
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final randomColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
            render(_flutterGlPlugin.gl, _glProgram, randomColor, 0);
          },
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      );
  }

  Future<void> setupGL() async {
    _flutterGlPlugin = FlutterGlPlugin();
    await _flutterGlPlugin.initialize(options: {
      "antialias": true,
      "alpha": true,
      "width": 300,
      "height": 300,
      "dpr": 1.0,
    });
    final gl = _flutterGlPlugin.gl;
    _glProgram = initGL(gl);
  }
}

dynamic initGL(dynamic gl) {
  const vertexShaderSource = """#version 300 es
#define attribute in
#define varying out
attribute vec3 a_Position;
uniform mat4 transform;
void main() {
  gl_Position = transform * vec4(a_Position, 1.0);
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

  final vertices = Float32Array.fromList([
    -0.5, -0.5, 0,
    0.5, -0.5, 0,
    0, 0.5, 0,
  ]);

  final vao = gl.createVertexArray();
  gl.bindVertexArray(vao);

  final vertexBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, vertices.length, vertices, gl.STATIC_DRAW);

  final aPosition = gl.getAttribLocation(glProgram, 'a_Position');
  gl.enableVertexAttribArray(aPosition);
  gl.vertexAttribPointer(aPosition, 3, gl.FLOAT, false, Float32List.bytesPerElement * 3, 0);

  return glProgram;
}

void render(dynamic gl, dynamic glProgram, Color color, double phaseRad) {
  // set transform
  final transform = gl.getUniformLocation(glProgram, 'transform');
  // final matrix = Float32Array.fromList([
  //   1, 0, 0, 0.5,
  //   0, 1, 0, 0, 
  //   0, 0, 1, 0,
  //   0, 0, 0, 1,
  // ]);
  var matrix = Matrix4.rotationZ(phaseRad).storage;
  gl.uniformMatrix4fv(transform, false, matrix);

  gl.viewport(0, 0, 300, 300);
  gl.clearColor(color.red / 255, color.green / 255, color.blue / 255, 1);
  gl.clear(gl.COLOR_BUFFER_BIT);
  gl.drawArrays(gl.TRIANGLES, 0, 3);

  gl.finish();
}