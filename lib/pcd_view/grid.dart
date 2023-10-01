import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pcd/pcd_view/program.dart';

abstract class GridBase {
  void draw(dynamic gl);
}

class VeloGrid implements GridBase {
  late int _vao;
  late int _gridPointNum;

  VeloGrid(dynamic gl, PcdProgram pcdProgram) {
    final grid = _genGrid();
    _gridPointNum = grid.length ~/ 6;
    final gridBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, gridBuffer);
    if (kIsWeb) {
      gl.bufferData(gl.ARRAY_BUFFER, grid.length, grid, gl.STATIC_DRAW);
    } else {
      gl.bufferData(gl.ARRAY_BUFFER, grid.lengthInBytes, grid, gl.STATIC_DRAW);
    }

    final gridMaskBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, gridMaskBuffer);
    final gridMask = Float32List(_gridPointNum);
    for (var i = 0; i < _gridPointNum; i++) {
      gridMask[i] = 1.0;
    }
    if (kIsWeb) {
      gl.bufferData(gl.ARRAY_BUFFER, gridMask.length, gridMask, gl.STATIC_DRAW);
    } else {
      gl.bufferData(gl.ARRAY_BUFFER, gridMask.lengthInBytes, gridMask, gl.STATIC_DRAW);
    }

    final attrPosition = pcdProgram.getAttrPosition(gl);
    final attrColor = pcdProgram.getAttrColor(gl);
    final attrMask = pcdProgram.getAttrMask(gl);

    _vao = gl.createVertexArray();
    gl.bindVertexArray(_vao);
    {
      gl.bindBuffer(gl.ARRAY_BUFFER, gridBuffer);
      gl.vertexAttribPointer(
          attrPosition, 3, gl.FLOAT, false, 6 * Float32List.bytesPerElement, 0);
      gl.enableVertexAttribArray(attrPosition);
      gl.vertexAttribPointer(attrColor, 3, gl.FLOAT, false,
          6 * Float32List.bytesPerElement, 3 * Float32List.bytesPerElement);
      gl.enableVertexAttribArray(attrColor);
      gl.vertexAttribPointer(
          attrPosition, 3, gl.FLOAT, false, 6 * Float32List.bytesPerElement, 0);
      gl.vertexAttribPointer(attrColor, 3, gl.FLOAT, false,
          6 * Float32List.bytesPerElement, 3 * Float32List.bytesPerElement);
      gl.bindBuffer(gl.ARRAY_BUFFER, gridBuffer);
      gl.vertexAttribPointer(
          attrPosition, 3, gl.FLOAT, false, 6 * Float32List.bytesPerElement, 0);
      gl.enableVertexAttribArray(attrPosition);
      gl.vertexAttribPointer(attrColor, 3, gl.FLOAT, false,
          6 * Float32List.bytesPerElement, 3 * Float32List.bytesPerElement);
      gl.enableVertexAttribArray(attrColor);
      gl.vertexAttribPointer(
          attrPosition, 3, gl.FLOAT, false, 6 * Float32List.bytesPerElement, 0);
      gl.vertexAttribPointer(attrColor, 3, gl.FLOAT, false,
          6 * Float32List.bytesPerElement, 3 * Float32List.bytesPerElement);
      gl.bindBuffer(gl.ARRAY_BUFFER, gridMaskBuffer);
      gl.vertexAttribPointer(
          attrMask, 1, gl.FLOAT, false, 1 * Float32List.bytesPerElement, 0);
      gl.enableVertexAttribArray(attrMask);
      gl.vertexAttribPointer(
          attrMask, 1, gl.FLOAT, false, 1 * Float32List.bytesPerElement, 0);
    }
    gl.bindVertexArray(0);
  }

  @override
  void draw(dynamic gl) {
    gl.bindVertexArray(_vao);
    gl.drawArrays(gl.LINES, 0, _gridPointNum);
    gl.bindVertexArray(0);
  }
}

Float32List _genGrid() {
  const color = Colors.white54;
  const z = 0.0;
  List<double> genLineXY(double x0, double y0, double x1, double y1) {
    return [
      x0,
      y0,
      z,
      color.red / 255,
      color.green / 255,
      color.blue / 255,
      x1,
      y1,
      z,
      color.red / 255,
      color.green / 255,
      color.blue / 255,
    ];
  }

  List<double> genCircle(double cx, double cy, double r, int segments) {
    final result = <double>[];
    for (var i = 0; i < segments; i++) {
      final theta0 = 2 * math.pi * i / segments;
      final theta1 = 2 * math.pi * (i + 1) / segments;
      result.addAll(genLineXY(
        cx + r * math.cos(theta0),
        cy + r * math.sin(theta0),
        cx + r * math.cos(theta1),
        cy + r * math.sin(theta1),
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
    result.addAll(genLineXY(
        x.toDouble(), minY.toDouble(), x.toDouble(), maxY.toDouble()));
  }
  for (var y = minY; y <= maxY; y += interval) {
    result.addAll(genLineXY(
        minX.toDouble(), y.toDouble(), maxX.toDouble(), y.toDouble()));
  }
  for (var r = 10; r <= 100; r += 10) {
    result.addAll(genCircle(0, 0, r.toDouble(), 100));
  }
  return Float32List.fromList(result);
}
