import 'dart:typed_data';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';

class HesaiPcapParser {
  final XFile file;
  HesaiPcapParser(this.file);

  List<List<VeloPoint>> frames = [];

  Future<void> readPcap() async {
    final content = await file.readAsBytes();
    int prevAzimuth = 0;
    List<VeloPoint> frame = [];
    final contentNoHeader = content.sublist(24);
    const packetWithHeaderLen = 1122 + 16;
    for (var i = 0;
        i < content.length - packetWithHeaderLen - 1;
        i += packetWithHeaderLen) {
      for (var point in parsePacketBody(
          contentNoHeader.sublist(i + 16 + 42, i + packetWithHeaderLen))) {
        if (point.azimuth < prevAzimuth) {
          frames.add(frame);
          frame = [];
        }
        frame.add(point);
        prevAzimuth = point.azimuth;
      }
    }
    print("read ${frames.length} frames from ${file.name}");
  }

  Iterable<VeloPoint> parsePacketBody(Uint8List packetBody) sync* {
    final header = packetBody.sublist(6, 12);
    final blockNum = header[1];
    final body = packetBody.sublist(12, 1052);
    final tail = packetBody.sublist(1052, 1076);
    final returnMode = tail[10];
    final dateTime = tail.sublist(13, 19);
    final timestamp = ((tail[22] << 24) +
        (tail[21] << 16) +
        (tail[20] << 8) +
        (tail[19] << 0));

    for (int blockIndex = 0; blockIndex < blockNum; blockIndex++) {
      final blockTimestamp =
          _calcBlockTimestamp(dateTime, timestamp, blockIndex, returnMode);
      final blockStart = blockIndex * 130;

      final block = body.sublist(blockStart, blockStart + 130);
      yield* _parseBlock(block, blockTimestamp);
    }
  }

  int _calcBlockTimestamp(
      Uint8List dateTime, int timestamp, int blockId, int returnMode) {
    final t0 = dateTime[4] * 60 * 1000000 + dateTime[5] * 1000000 + timestamp;
    if (returnMode == 0x37 || returnMode == 0x38) {
      return (t0 + 3.28 - 50 * (8 - blockId)).round();
    } else {
      return (t0 + 3.28 - 50 * ((8 - blockId) / 2)).round();
    }
  }

  int _channelToVAngle(int channel) {
    return -channel + 16;
  }

  (double, double, double) _calcPolarCoordinate(
      double azimuthDeg, double vAngleDeg, double distanceM) {
    final azimuthRad = azimuthDeg * math.pi / 180;
    final vAngleRad = vAngleDeg * math.pi / 180;
    final x = distanceM * math.cos(vAngleRad) * math.sin(azimuthRad);
    final y = distanceM * math.cos(vAngleRad) * math.cos(azimuthRad);
    final z = distanceM * math.sin(vAngleRad);
    return (x, y, z);
  }

  Iterable<VeloPoint> _parseBlock(
      Uint8List packetBlock, int blockTimestamp) sync* {
    final azimuth = (packetBlock[1] << 8) + packetBlock[0];
    for (int channel = 0; channel < 32; channel++) {
      final channelTimestamp = blockTimestamp + 1.512 * channel + 0.28;
      final vAngle = _channelToVAngle(channel);
      final channelStart = 2 + channel * 4;
      final channelData = packetBlock.sublist(channelStart, channelStart + 4);
      final distance = (channelData[1] << 8) + channelData[0];
      final reflectivity = channelData[2];
      final (x, y, z) = _calcPolarCoordinate(
          azimuth / 100.0, vAngle.toDouble(), distance * 4.0 / 1000.0);
      yield VeloPoint(
        reflectivity,
        channel,
        azimuth,
        distance * 4.0 / 1000.0,
        channelTimestamp.toInt(),
        channelTimestamp.toInt(),
        vAngle.toDouble(),
        x,
        y,
        z,
      );
    }
  }
}

class VeloPoint {
  final int reflectivity;
  final int channel;
  final int azimuth;
  final double distance_m;
  final int adjusted_time;
  final int timestamp;
  final double vertical_angle;
  final double x;
  final double y;
  final double z;

  VeloPoint(
    this.reflectivity,
    this.channel,
    this.azimuth,
    this.distance_m,
    this.adjusted_time,
    this.timestamp,
    this.vertical_angle,
    this.x,
    this.y,
    this.z,
  );
}
