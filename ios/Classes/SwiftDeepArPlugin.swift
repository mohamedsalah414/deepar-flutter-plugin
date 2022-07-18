import Flutter
import UIKit
import DeepAR
import AVFoundation
import Photos
public class SwiftDeepArPlugin: NSObject, FlutterPlugin{
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "deep_ar", binaryMessenger: registrar.messenger())
        let instance = SwiftDeepArPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.registrar = registrar
        
        let factory = DeepARCameraFactory(messenger: registrar.messenger(), registrar: registrar);
        registrar.register(factory, withId: "deep_ar_view");
    }
}
