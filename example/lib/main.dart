import 'dart:io';

import 'package:camera/camera.dart';
import 'package:deep_ar/deep_ar_controller.dart';
import 'package:flutter/material.dart';
import 'package:deep_ar/deep_ar.dart';
import 'dart:convert';

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
  bool isFlashOn = false;
  String version = '';
  List<String> effectsList = [];
  int _effectIndex = 0;

  @override
  void initState() {
    _controller = DeepArController();
    initializeDeepAr();

    super.initState();
  }

  @override
  void didChangeDependencies() {
    _getEffects(context).then((values) {
      effectsList.clear();
      effectsList.addAll(values);
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.isPermission
        ? Stack(
            children: [
              _controller.isInitialized
                  ? DeepArPreview(_controller)
                  : const Center(
                      child: Text(
                          "Something went wrong while initializing DeepAR"),
                    ),
              Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                      onPressed: () {
                        _controller.toggleFlash();
                        setState(() {
                          isFlashOn = !isFlashOn;
                        });
                      },
                      color: Colors.white70,
                      iconSize: 40,
                      icon:
                          Icon(isFlashOn ? Icons.flash_on : Icons.flash_off))),
              _bottomButtons(),
            ],
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      initializeDeepAr();
                    },
                    child:
                        const Text("Click here to update permission status")),
              ],
            ),
          );
  }

  Future<void> initializeDeepAr() async {
    await _controller
        .initialize(
          androidLicenseKey:
              "53de9b68021fd5be051ddd80c8d1aee5653eda7cabcd58776c1a96e5027f4a8c78d4946795ccd944",
          iosLicenseKey:
              "38c170bb360fff2913731fdb0bb17a6257d85e6240d53aeb53a997886698ab4cb13a8b90736684ae",
          preset: Resolution.high,
        )
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
                  String prevEffect = getPrevEffect();
                  _controller.switchEffect(prevEffect);
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white70,
                )),
            IconButton(
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
                iconSize: 50,
                color: Colors.white70,
                icon: Icon(isRecording
                    ? Icons.videocam_sharp
                    : Icons.videocam_outlined)),
            const SizedBox(width: 20),
            IconButton(
                onPressed: () {
                  _controller.flipCamera();
                },
                iconSize: 50,
                color: Colors.white70,
                icon: const Icon(Icons.cameraswitch)),
            IconButton(
                iconSize: 60,
                onPressed: () {
                  String nextEffect = getNextEffect();
                  _controller.switchEffect(nextEffect);
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

  Future<List<String>> _getEffects(BuildContext context) async {
    // Load as String
    final manifestContent =
        await DefaultAssetBundle.of(context).loadString('AssetManifest.json');

    // Decode to Map
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    // Filter by path
    final filtered = manifestMap.keys
        .where((path) => path.startsWith('assets/effects/'))
        .toList();
    return filtered;
  }

  String getNextEffect() {
    _effectIndex < effectsList.length ? _effectIndex++ : _effectIndex = 0;
    return effectsList[_effectIndex];
  }

  String getPrevEffect() {
    _effectIndex > 0 ? _effectIndex-- : _effectIndex = effectsList.length;
    return effectsList[_effectIndex];
  }
}
