import 'package:camera/camera.dart';
import 'package:deep_ar/deep_ar_controller.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:deep_ar/deep_ar.dart';

import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras));
}

class MyApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  const MyApp(this.cameras, {Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  late final DeepArController _controller;
  @override
  void initState() {
    super.initState();
    // initPlatformState();

    CameraDescription front = widget.cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);
    _controller = DeepArController();
    _controller.initialize().then((value) => setState(() {}));
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await DeepAr.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text('Running on: $_platformVersion\n'),
            ),
            _controller.isInitialized
                ? SizedBox(height: 500, child: DeepArPreview(_controller))
                : SizedBox.shrink(),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                    onPressed: () {
                      _controller.switchEffect(Random().nextInt(10));
                    },
                    child: const Text("Switch Effect")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
