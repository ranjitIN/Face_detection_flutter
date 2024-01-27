import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:face_recognition_flutter/painters/face_rectangle_paint.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class MyCameraPreview extends StatefulWidget {
  const MyCameraPreview({super.key});

  @override
  State<MyCameraPreview> createState() => _MyCameraPreviewState();
}

class _MyCameraPreviewState extends State<MyCameraPreview>
    with WidgetsBindingObserver {
  late List<CameraDescription> _cameras;
  CameraController? controller;
  late CameraDescription selectedCamera;

  Future<List<CameraDescription>>? cameraInitilization;

  // Future<List<CameraDescription>> initializeCamera() async {
  //   _cameras = await availableCameras();
  //   controller =
  //       CameraController(_cameras[0], ResolutionPreset.max, enableAudio: false);
  //   return _cameras;
  // }

  final FaceDetectorOptions options = FaceDetectorOptions();
  FaceDetector? faceDetector;
  CustomPaint? _customPaint;

  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    faceDetector = FaceDetector(options: options);
    cameraInitilization = availableCameras().then((value) async {
      _cameras = value;
      selectedCamera = _cameras[0];
      await startLiveFeed();
      return value;
    });
  }

  Future startLiveFeed() async {
    controller = CameraController(selectedCamera, ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888);
    controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller?.startImageStream(processFrame);
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  Future stopLiveFeed() async {
    await controller?.stopImageStream();
    await controller?.dispose();
    controller = null;
  }

  Future<void> processFrame(CameraImage cameraImage) async {
    try {
      if (isProcessing) return;
      isProcessing = true;
      final InputImage? inputImage = _inputImageFromCameraImage(cameraImage);
      if (inputImage != null) {
        final List<Face>? faces = await faceDetector?.processImage(inputImage);
        if (faces != null) {
          if (inputImage.metadata?.size != null &&
              inputImage.metadata?.rotation != null) {
            final painter = FaceDetectorPainter(
              faces: faces,
              imageSize: inputImage.metadata!.size,
              rotation: inputImage.metadata!.rotation,
              cameraLensDirection: selectedCamera.lensDirection,
            );
            _customPaint = CustomPaint(painter: painter);
          } else {
            _customPaint = null;
          }
        }
      }

      isProcessing = false;
      setState(() {});
    } catch (e) {
      // print("Exception");
      // print(e.toString());
    }
  }

  void updateController(CameraDescription description) async {
    try {
      setState(() => selectedCamera = description);
      await stopLiveFeed();
      await startLiveFeed();
      setState(() {});
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      print('paused');
    } else if (state == AppLifecycleState.resumed) {
      print('resumed');
    } else if (state == AppLifecycleState.detached) {
      print('detached');
    }
  }

  @override
  Future<AppExitResponse> didRequestAppExit() {
    // TODO: implement
    print('complete detached');
    return super.didRequestAppExit();
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final sensorOrientation = selectedCamera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation!);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller?.value.deviceOrientation];
      if (rotationCompensation == null) return null;

      if (selectedCamera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }

      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      // print('rotationCompensation: $rotationCompensation');
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  // static Future<List<Face>> processFrameInIsoLate(
  //     IsoLateArguments isoLateArguments) async {
  //   print("running on isolate");
  //   final FaceDetectorOptions options = FaceDetectorOptions();
  //   FaceDetector? faceDetector = FaceDetector(options: options);
  //   CameraImage cameraImage = isoLateArguments.argus["cameraImage"]!;
  //   CameraDescription selectedCamera = isoLateArguments.argus["selcetdCamera"];
  //   BackgroundIsolateBinaryMessenger.ensureInitialized(
  //       isoLateArguments.argus['token']!);

  //   final WriteBuffer allBytes = WriteBuffer();
  //   for (final Plane plane in cameraImage.planes) {
  //     allBytes.putUint8List(plane.bytes);
  //   }
  //   final bytes = allBytes.done().buffer.asUint8List();
  //   final Size imageSize = Size(
  //     cameraImage.width.toDouble(),
  //     cameraImage.height.toDouble(),
  //   );

  //   final imageRotation = InputImageRotationValue.fromRawValue(
  //           selectedCamera.sensorOrientation) ??
  //       InputImageRotation.rotation0deg;

  //   final inputImageFormat =
  //       InputImageFormatValue.fromRawValue(cameraImage.format.raw) ??
  //           InputImageFormat.nv21;

  //   InputImage inputImage = InputImage.fromBytes(
  //       bytes: bytes,
  //       metadata: InputImageMetadata(
  //           size: imageSize,
  //           rotation: imageRotation,
  //           format: inputImageFormat,
  //           bytesPerRow: cameraImage.planes.first.bytesPerRow));

  //   final List<Face> faces = await faceDetector.processImage(inputImage);
  //   print(faces);
  //   sendPort.send(faces);
  //   Isolate.exit(sendPort, faces);
  // }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller?.dispose();
    faceDetector?.close();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: FutureBuilder(
              future: cameraInitilization,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return (controller != null &&
                          (controller?.value.isInitialized ?? false))
                      ? CameraPreview(controller!, child: _customPaint)
                      : Container();
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                } else {
                  return const Center(child: Text("Init Camra"));
                }
              })),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(),
        height: kBottomNavigationBarHeight + 20,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Result",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                  iconSize: 24,
                  onPressed: () async {
                    if (_cameras.length > 2) {
                      if (selectedCamera.lensDirection ==
                          CameraLensDirection.back) {
                        updateController(_cameras.firstWhere((element) =>
                            element.lensDirection ==
                            CameraLensDirection.front));
                      } else {
                        updateController(_cameras.firstWhere((element) =>
                            element.lensDirection == CameraLensDirection.back));
                      }
                    }
                  },
                  icon: const Icon(Icons.flip_camera_android))
            ],
          ),
        ),
      ),
    );
  }
}
