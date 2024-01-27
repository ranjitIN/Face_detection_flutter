// import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

var camera_svg = "lib/assets/svg/camera_2.svg";

Future<bool> requestCameraPermission(BuildContext context) async {
  var status = await Permission.camera.status;
  if (status.isGranted) {
    return true;
  } else {
    var requestStatus = await Permission.camera.onDeniedCallback(() {
      showDialog(
          context: context,
          builder: (context) => const CameraPermissonDetails(
                callBackType: "ondined",
              ));
    }).onGrantedCallback(() {
      // Your code
    }).onPermanentlyDeniedCallback(() {
      showDialog(
          context: context,
          builder: (context) => const CameraPermissonDetails(
                callBackType: "on permanet dined",
              ));
      // Your code
    }).onRestrictedCallback(() {
      showDialog(
          context: context,
          builder: (context) => const CameraPermissonDetails(
                callBackType: "restricted",
              ));
      // Your code
    }).onLimitedCallback(() {
      showDialog(
          context: context,
          builder: (context) => const CameraPermissonDetails(
                callBackType: "limited",
              ));
      // Your code
    }).onProvisionalCallback(() {
      showDialog(
          context: context,
          builder: (context) => const CameraPermissonDetails(
                callBackType: "provision",
              ));
      // Your code
    }).request();
    if (requestStatus.isGranted) {
      return true;
    } else {
      return false;
    }
  }
}

Future<bool> isCameraPermissionGranted() async {
  return await Permission.camera.status.isGranted;
}

class CameraPermissonDetails extends StatelessWidget {
  final String callBackType;
  const CameraPermissonDetails(
      {super.key, this.callBackType = "Camera Permission Needed"});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Camera Permission Needed'),
      content: const Text(
          'Permission is denied Navigate to app settings and allow camera permission'),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel')),
        TextButton(
            onPressed: () async {
              var status = await Permission.camera.status;
              if (status.isDenied || status.isPermanentlyDenied) {
              } else {
                requestCameraPermission(context);
              }
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text('Ok'))
      ],
    );
  }
}
