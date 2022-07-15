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
    
    var registrar: FlutterPluginRegistrar? = nil
    
    
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        let args = call.arguments as? [String : Any]
        
        switch call.method {
        case "check_all_permission":
            result(isMediaPermissionGranted())
        default:
            result("Failed to call iOS platform method")
        }
    }
    
    private func isMediaPermissionGranted() -> Bool{
        return (AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized) && (AVCaptureDevice.authorizationStatus(for: .audio) ==  .authorized)
    }
    
}
