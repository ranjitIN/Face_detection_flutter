import 'package:face_recognition_flutter/screens/permission/Home.dart';
import 'package:face_recognition_flutter/utils.dart';
import 'package:flutter/material.dart';

class CameraPermssion extends StatefulWidget {
  const CameraPermssion({super.key});

  @override
  State<CameraPermssion> createState() => _CameraPermssionState();
}

class _CameraPermssionState extends State<CameraPermssion> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 50,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  'Enable Camera',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Text(
                'Please provide us access to your camera, which is required for capture your Face',
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: ElevatedButton(
                    onPressed: () async {
                      var res = await requestCameraPermission(context);
                      if (res) {
                        // ignore: use_build_context_synchronously
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Home()),
                            (route) => false);
                      }
                    },
                    child: const Text('Allow')),
              )
            ],
          ),
        ),
      ),
    );
  }
}
