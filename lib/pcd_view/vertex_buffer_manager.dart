import 'package:flutter/foundation.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:flutter_pcd/pcd_view/program.dart';

class VertexBufferManager {
  late dynamic _vVertexBuffer;
  late dynamic _cVertexBuffer;
  late int _vao;
  late int _pointNum;

  VertexBufferManager(dynamic gl, PcdProgram pcdProgram, Float32List vertices, Float32List colors, int maxPointNum) {
    pcdProgram.use(gl);

    _pointNum = vertices.length ~/ 3;

    _vVertexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, _vVertexBuffer);
    Float32Array initData = Float32Array(maxPointNum * 3);
    if (kIsWeb) {
      gl.bufferData(gl.ARRAY_BUFFER, initData.length, initData, gl.DYNAMIC_DRAW);
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, vertices, 0, vertices.length);
    } else {
      gl.bufferData(gl.ARRAY_BUFFER, initData.lengthInBytes, initData, gl.DYNAMIC_DRAW);
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, vertices, 0, vertices.lengthInBytes);
    }

    _cVertexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, _cVertexBuffer);
    if (kIsWeb) {
      gl.bufferData(gl.ARRAY_BUFFER, initData.length, initData, gl.DYNAMIC_DRAW);
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, colors, 0, colors.length);
    } else {
      gl.bufferData(gl.ARRAY_BUFFER, initData.lengthInBytes, initData, gl.DYNAMIC_DRAW);
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, colors, 0, colors.lengthInBytes);
    }

    final attrPosition = pcdProgram.getAttrPosition(gl);
    final attrColor = pcdProgram.getAttrColor(gl);

    _vao = gl.createVertexArray();
    gl.bindVertexArray(_vao); {
      // なぜかこの順番で呼ぶと動く
      gl.bindBuffer(gl.ARRAY_BUFFER, _vVertexBuffer);
      gl.vertexAttribPointer(attrPosition, 3, gl.FLOAT, false, 3 * Float32List.bytesPerElement, 0);
      gl.enableVertexAttribArray(attrPosition);
      gl.bindBuffer(gl.ARRAY_BUFFER, _cVertexBuffer);
      gl.vertexAttribPointer(attrColor, 3, gl.FLOAT, false, 
        3 * Float32List.bytesPerElement, 0);
      gl.enableVertexAttribArray(attrColor);
      gl.bindBuffer(gl.ARRAY_BUFFER, _vVertexBuffer);
      gl.vertexAttribPointer(attrPosition, 3, gl.FLOAT, false, 3 * Float32List.bytesPerElement, 0);
      gl.bindBuffer(gl.ARRAY_BUFFER, _cVertexBuffer);
      gl.vertexAttribPointer(attrColor, 3, gl.FLOAT, false, 
        3 * Float32List.bytesPerElement, 0);
      gl.bindBuffer(gl.ARRAY_BUFFER, _vVertexBuffer);
      gl.vertexAttribPointer(attrPosition, 3, gl.FLOAT, false, 3 * Float32List.bytesPerElement, 0);
      gl.enableVertexAttribArray(attrPosition);
      gl.bindBuffer(gl.ARRAY_BUFFER, _cVertexBuffer);
      gl.vertexAttribPointer(attrColor, 3, gl.FLOAT, false, 
        3 * Float32List.bytesPerElement, 0);
      gl.enableVertexAttribArray(attrColor);
      gl.bindBuffer(gl.ARRAY_BUFFER, _vVertexBuffer);
      gl.vertexAttribPointer(attrPosition, 3, gl.FLOAT, false, 3 * Float32List.bytesPerElement, 0);
      gl.bindBuffer(gl.ARRAY_BUFFER, _cVertexBuffer);
      gl.vertexAttribPointer(attrColor, 3, gl.FLOAT, false, 
        3 * Float32List.bytesPerElement, 0);
    } gl.bindVertexArray(0);
  }

  void updateVertices(dynamic gl, Float32List vertices) {
    // bufferSubDataでは最初にBufferDataで指定したサイズ以上のデータを受け入れてくれないので注意
    // 最初に想定される最大サイズで初期化する必要がある
    _pointNum = vertices.length ~/ 3;
    gl.bindBuffer(gl.ARRAY_BUFFER, _vVertexBuffer);
    if (kIsWeb) {
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, vertices, 0, vertices.length);
    } else {
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, vertices, 0, vertices.lengthInBytes);
    }
  }

  void updateColors(dynamic gl, Float32List colors) {
    gl.bindBuffer(gl.ARRAY_BUFFER, _cVertexBuffer);
    if (kIsWeb) {
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, colors, 0, colors.length);
    } else {
      gl.bufferSubData(gl.ARRAY_BUFFER, 0, colors, 0, colors.lengthInBytes);
    }
  }

  void draw(dynamic gl) {
    gl.bindVertexArray(_vao);
    gl.drawArrays(gl.POINTS, 0, _pointNum);
    gl.bindVertexArray(0);
  }
}