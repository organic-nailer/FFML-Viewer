import 'package:flutter/foundation.dart';

const _vertexShaderSource = """
#version ${kIsWeb ? "300 es" : "150"}
#define attribute in
#define varying out
attribute vec3 a_Position;
attribute vec3 a_Color;
uniform mat4 transform;
uniform float pointSize;
varying vec3 v_Color;
void main() {
  gl_Position = transform * vec4(a_Position, 1.0);
  gl_PointSize = pointSize;
  v_Color = a_Color;
}
""";

const _fragmentShaderSource = """
#version ${kIsWeb ? "300 es" : "150"}
out highp vec4 pc_fragColor;
#define gl_FragColor pc_fragColor
#define varying in

precision highp float;
varying vec3 v_Color;

void main() {
  gl_FragColor = vec4(v_Color, 1.0);
}
""";

class PcdProgram {
  late int _glProgram;
  PcdProgram(dynamic gl) {
    gl.enable(0x8642); // GL_PROGRAM_POINT_SIZE
    gl.enable(gl.DEPTH_TEST);

    final vertexShader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertexShader, _vertexShaderSource);
    gl.compileShader(vertexShader);

    var res = gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS);
    if (res == 0 || res == false) {
      throw Exception("Error compiling shader: ${gl.getShaderInfoLog(vertexShader)}");
    }

    final fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragmentShader, _fragmentShaderSource);
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

    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);
  }

  void use(dynamic gl) {
    gl.useProgram(_glProgram);
  }

  int getAttrPosition(dynamic gl) {
    return gl.getAttribLocation(_glProgram, "a_Position");
  }

  int getAttrColor(dynamic gl) {
    return gl.getAttribLocation(_glProgram, "a_Color");
  }

  int getUniformTransform(dynamic gl) {
    return gl.getUniformLocation(_glProgram, "transform");
  }

  int getUniformPointSize(dynamic gl) {
    return gl.getUniformLocation(_glProgram, "pointSize");
  }
}
