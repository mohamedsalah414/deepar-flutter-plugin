import 'package:flutter/material.dart';
import 'package:deep_ar/deep_ar.dart';
import 'dart:convert';

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
  String version = '';

  final List<String> _effectsList = [];
  int _effectIndex = 0;

  final String _assetEffectsPath = 'assets/effects/';

  @override
  void initState() {
    _controller = DeepArController();
    _controller
        .initialize(
          androidLicenseKey:
              "53de9b68021fd5be051ddd80c8d1aee5653eda7cabcd58776c1a96e5027f4a8c78d4946795ccd944",
          iosLicenseKey:
              "38c170bb360fff2913731fdb0bb17a6257d85e6240d53aeb53a997886698ab4cb13a8b90736684ae",
          resolution: Resolution.high,
        )
        .then((value) => setState(() {}));
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _initEffects();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _controller.isInitialized
            ? DeepArPreview(_controller)
            : const Center(
                child: Text("Loading..."),
              ),
        Positioned(
            top: 10,
            right: 10,
            child: IconButton(
                onPressed: () async {
                  await _controller.toggleFlash();
                  setState(() {});
                },
                color: Colors.white70,
                iconSize: 40,
                icon: Icon(_controller.flashState
                    ? Icons.flash_on
                    : Icons.flash_off))),
        Positioned(
          top: 10,
          left: 10,
          child: IconButton(
              onPressed: () {
                _controller.flipCamera();
              },
              iconSize: 50,
              color: Colors.white70,
              icon: const Icon(Icons.cameraswitch)),
        ),
        _mediaOptions(),
      ],
    );
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
                onPressed: () async {
                  if (_controller.isRecording) {
                    await _controller.stopVideoRecording();
                  } else {
                    _controller.startVideoRecording();
                  }

                  setState(() {});
                },
                iconSize: 50,
                color: Colors.white70,
                icon: Icon(_controller.isRecording
                    ? Icons.videocam_sharp
                    : Icons.videocam_outlined)),
            const SizedBox(width: 20),
            IconButton(
                onPressed: () {
                  _controller.takeScreenshot();
                },
                color: Colors.white70,
                iconSize: 40,
                icon: const Icon(Icons.photo_camera)),
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
