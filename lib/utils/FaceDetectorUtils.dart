import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

final FaceDetectorOptions options = FaceDetectorOptions();
FaceDetector? faceDetector = FaceDetector(options: options);
final ReceivePort receivePort = ReceivePort();
RootIsolateToken? rootToken = RootIsolateToken.instance;

class IsoLateArguments {
  SendPort sendPort;
  Map<String, dynamic> argus;
  IsoLateArguments({required this.sendPort, required this.argus});
}
