import 'package:camera/camera.dart';
import 'package:face_recognition_flutter/screens/my_camera_preview.dart';
import 'package:face_recognition_flutter/screens/permission/cameraPermission.dart';
import 'package:face_recognition_flutter/utils.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future<bool>? cameraPermission;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    cameraPermission = isCameraPermissionGranted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
            future: cameraPermission,
            builder: (context, snapshot) {
              if (snapshot.data ?? false) {
                return MyCameraPreview();
              } else {
                return const CameraPermssion();
              }
            }),
      ),
    );
  }
}
