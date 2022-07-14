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
            let isGranted:Bool = checkCameraPermission()
            result(isGranted)
        default:
            result("Failed to call iOS platform method")
        }
    }
    
    private func checkCameraPermission() -> Bool{
        var isGranted:Bool = false
        switch AVCaptureDevice.authorizationStatus(for: .video){
            
        case .notDetermined:
            // Request Permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else {
                    return
                }
                
                isGranted = true
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            isGranted = true
        @unknown default:
            break
        }
        
        return isGranted
    }
       
}
