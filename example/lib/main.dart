import 'package:camera/camera.dart';
import 'package:deep_ar/deep_ar_controller.dart';
import 'package:flutter/material.dart';
import 'package:deep_ar/deep_ar.dart';

import 'dart:math';
import 'package:deep_ar/resolution_preset.dart';

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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('DeepAR Flutter Plugin'),
        ),
        body: const Home(),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final DeepArController _controller;
  bool isRecording = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _controller = DeepArController();
    initializeDeepAr();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.isInitialized
        ? Stack(
            children: [
              DeepArPreview(_controller),
              _bottomButtons(),
            ],
          )
        : Center(
            child: ElevatedButton(
                onPressed: () {
                  initializeDeepAr();
                },
                child: const Text("Click here to update permission status")),
          );
  }

  void initializeDeepAr() {
    var mediaQuery = MediaQuery.of(context);
    int pixelWidth =
        (mediaQuery.size.width * mediaQuery.devicePixelRatio).toInt();
    int pixelHeight =
        (mediaQuery.size.height * mediaQuery.devicePixelRatio).toInt();

    _controller
        .initialize(
            licenseKey:
                "53de9b68021fd5be051ddd80c8d1aee5653eda7cabcd58776c1a96e5027f4a8c78d4946795ccd944",
            preset: Resolution.high,
            width: pixelWidth,
            height: pixelHeight)
        .then((value) => setState(() {}));
  }

  Positioned _bottomButtons() {
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                iconSize: 60,
                onPressed: () {
                  _controller.switchEffect(Random().nextInt(15));
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white70,
                )),
            ElevatedButton(
                onPressed: () {
                  if (isRecording) {
                    _controller.stopVideoRecording();
                    isRecording = false;
                  } else {
                    _controller.startVideoRecording();
                    isRecording = true;
                  }

                  setState(() {});
                },
                child:
                    Text(isRecording ? "Stop Recording" : "Start Recording")),
            IconButton(
                iconSize: 60,
                onPressed: () {
                  _controller.switchEffect(Random().nextInt(15));
                },
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                )),
          ],
        ),
      ),
    );
  }
}
