import 'package:flutter/gestures.dart' hide Matrix4;
import 'package:flutter/material.dart' hide Matrix4;
import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' show Vector3, Vector4, Matrix4;

class InteractiveCameraController {
  Size _canvasSize;
  late Matrix4 _projectiveTransform;
  final Matrix4 _viewingTransform = _getViewingTransform(
    Vector3(0, 0, 3),
    Vector3(0, 0, 0),
    Vector3(0, 1, 0),
  );

  InteractiveCameraController(this._canvasSize) {
    _projectiveTransform = _initProjectiveTransform(_canvasSize);
  }

  /// World Coordinate での原点中心の回転
  Matrix4 rotOriginTransform = Matrix4.identity();

  /// Camera Coordinate でのカメラの移動
  Matrix4 cameraMoveTransform = Matrix4.identity();

  Matrix4 get synthesizedTransform {
    return _projectiveTransform *
        cameraMoveTransform *
        _viewingTransform *
        rotOriginTransform;
  }

  Matrix4 _initProjectiveTransform(Size size) {
    return _getProjectiveTransform(
      30 * math.pi / 180,
      size.width / size.height,
      -0.01,
      -600,
    );
  }

  void updateCanvasSize(Size size) {
    _canvasSize = size;
    _projectiveTransform = _initProjectiveTransform(size);
    _onUpdate?.call();
  }

  
  double prevTrackPadZoomScale = 1.0;
  Offset currentTrackPadZoomPosition = Offset.zero;

  VoidCallback? _onUpdate;

  void addListener(VoidCallback listener) {
    _onUpdate = listener;
  }

  void dispose() {
    _onUpdate = null;
  }

  void _viewZoom(double zoomNormalized, double mousePosX, double mousePosY) {
    // print("zoomNormalized: ${zoomNormalized}");
    // ズーム時のマウス位置の方向にカメラを移動させる
    final mouseClipX = mousePosX / _canvasSize.width * 2 - 1;
    final mouseClipY = -(mousePosY / _canvasSize.height * 2 - 1);
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

    cameraMoveTransform = translate * cameraMoveTransform;
    _onUpdate?.call();
  }

  void _onScaleStart(ScaleStartDetails details) {
    prevTrackPadZoomScale = 1.0;
    currentTrackPadZoomPosition = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale == 1.0) {
      // rotate
      final move = details.focalPointDelta;
      final moveFactor = 90 / _canvasSize.height;
      final moveThetaX = move.dx * moveFactor * math.pi / 180;
      final moveThetaY = move.dy * moveFactor * math.pi / 180;
      final moveTransform = Matrix4.identity()
        ..rotateX(moveThetaY)
        ..rotateY(moveThetaX);
      rotOriginTransform = moveTransform * rotOriginTransform;
      _onUpdate?.call();
    } else {
      // zoom
      // Windowsの場合、なぜかscaleが前からの合算の値を渡してくるのでこちらがわでdeltaを計算する
      // さらにdetails.focalPointがバグっているので使わない
      final zoom = details.scale / prevTrackPadZoomScale;
      const zoomFactor = 1;
      _viewZoom((zoom - 1) * zoomFactor, currentTrackPadZoomPosition.dx,
          currentTrackPadZoomPosition.dy);
      prevTrackPadZoomScale = details.scale;
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    prevTrackPadZoomScale = 1.0;
    currentTrackPadZoomPosition = Offset.zero;
  }
}

class InteractiveCamera extends StatelessWidget {
  final InteractiveCameraController controller;
  final Widget child;

  const InteractiveCamera({Key? key, required this.controller, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (signal) {
        if (signal is PointerScrollEvent) {
          // マウスホイールのスクロール
          // タッチパッドの2本指スクロール
          final zoom = signal.scrollDelta.dy;
          const zoomFactor = 0.001;
          controller._viewZoom(zoom * zoomFactor, signal.position.dx, signal.position.dy);
        } else if (signal is PointerScaleEvent) {
          // タッチパッドの2本指ピンチ
          final zoom = signal.scale;
          const zoomFactor = 1;
          controller._viewZoom(
              (zoom - 1) * zoomFactor, signal.position.dx, signal.position.dy);
        }
      },
      child: GestureDetector(
        onScaleStart: (details) {
          controller._onScaleStart(details);
        },
        onScaleUpdate: (details) {
          controller._onScaleUpdate(details);
        },
        onScaleEnd: (details) {
          controller._onScaleEnd(details);
        },
        child: child,
      ),
    );
  }
}

/// LookAt方式のビュー変換行列を返す
/// パラメータは世界座標系
Matrix4 _getViewingTransform(
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

Matrix4 _getProjectiveTransform(
    double fovY, double aspect, double near, double far) {
  final f = 1 / math.tan(fovY / 2);
  final z = (far + near) / (near - far);
  final w = -2 * far * near / (near - far);
  return Matrix4(
    f / aspect,
    0,
    0,
    0,
    0,
    f,
    0,
    0,
    0,
    0,
    z,
    w,
    0,
    0,
    -1,
    0,
  ).transposed();
}
