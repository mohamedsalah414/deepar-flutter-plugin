import 'dart:io';

import 'package:deep_ar/deep_ar_controller.dart';
import 'package:flutter/material.dart';
import 'package:deep_ar/deep_ar.dart';
import 'dart:convert';

import 'package:deep_ar/resolution_preset.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

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
  bool _isRecording = false;
  final List<String> _effectsList = [];
  int _effectIndex = 0;

  final String _assetEffectsPath = 'assets/effects/';

  @override
  void initState() {
    _controller = DeepArController();
    _initializeDeepAr();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _initEffects();
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
              
              _mediaOptions(),
            ],
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      _initializeDeepAr();
                    },
                    child:
                        const Text("Click here to update permission status")),
              ],
            ),
          );
  }

  Future<void> _initializeDeepAr() async {
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

  /// Sample option which can be performed
  Positioned _mediaOptions() {
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
                  String prevEffect = _getPrevEffect();
                  _controller.switchEffect(prevEffect);
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white70,
                )),
            IconButton(
                onPressed: () {
                  if (_isRecording) {
                    _controller.stopVideoRecording();
                    _isRecording = false;
                  } else {
                    _controller.startVideoRecording();
                    _isRecording = true;
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
                  String nextEffect = _getNextEffect();
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

  /// Add effects which are rendered via DeepAR sdk
  void _initEffects() {

    // Either get all effects 
    _getEffectsFromAssets(context).then((values) {
      _effectsList.clear();
      _effectsList.addAll(values);
    });

    // OR

    // Only add specific effects
    // _effectsList.add(ASSET_PATH+'burning_effect.deepar');
    // _effectsList.add(ASSET_PATH+'flower_face.deepar');
    // _effectsList.add(ASSET_PATH+'Hope.deepar');
    // _effectsList.add(ASSET_PATH+'viking_helmet.deepar');
  }

  /// Get all deepar effects from assets
  ///
  Future<List<String>> _getEffectsFromAssets(BuildContext context) async {
    final manifestContent =
        await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final filePaths = manifestMap.keys
        .where((path) => path.startsWith(_assetEffectsPath))
        .toList();
    return filePaths;
  }

  /// Get next effect
  String _getNextEffect() {
    _effectIndex < _effectsList.length ? _effectIndex++ : _effectIndex = 0;
    return _effectsList[_effectIndex];
  }

  /// Get previous effect
  String _getPrevEffect() {
    _effectIndex > 0 ? _effectIndex-- : _effectIndex = _effectsList.length;
    return _effectsList[_effectIndex];
  }
}
