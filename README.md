This plugin is the official SDK for [DeepAR](http://deepar.ai). Platforms supported: android & iOS. 

The current version of plugin supports: 
1. Realtime AR previews
2. Capture photos
3. Record Videos
4. Flip camera
5. Toggle Flash

| Support |Android  | iOS|
|--|--|--|
|  |SDK 21+  |iOS 11.0+|


## Installation
Please visit our [developer website](https://developer.deepar.ai) to create a project and generate your separate licence keys for both platforms. 

Once done, please add the latest `deep_ar` dependency to your pubspec.yaml. 

**Android**: 
Please download the native android dependencies from our [downloads](https://developer.deepar.ai/downloads) section and save it to your project as: `android/libs/deepar.aar`.

**iOS:**


**Flutter:**

1. Initialise  `DeepArController` by passing in your license keys for both platforms.
```
final  DeepArController _controller = DeepArController();
_controller.initialize(
	androidLicenseKey:"---android key---",
	iosLicenseKey:"---iOS key---",
	resolution: Resolution.high);
```
2. Place the DeepArPreview widget in your widget tree to display the preview. 
```
@override

Widget  build(BuildContext  context) {
return  _controller.isInitialized
		? DeepArPreview(_controller)
		: const  Center(
			child: Text("Loading Preview")
		);
}
```
       
3.  Load effect of your choice by passing the asset file to it in `switchPreview`
```
_controller.switchEffect(effect);
```
4. To take a picture, use `takeScreenshot()` which return the picture as file.
```
final File file = await _controller.takeScreenshot();
```
5. To record a video, please use : 
```
if (_controller.isRecording) {
_controller.stopVideoRecording();
} else {
final File videoFile = _controller.startVideoRecording();
}
```

For more info, please visit: [Developer Help](https://help.deepar.ai/en/).
