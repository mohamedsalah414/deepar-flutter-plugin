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
        case "initialize":
            let licenseKey: String = args?["license_key"] as! String
            setupDeepARCamera(licenseKey: licenseKey)
            result("Initialized")
            
        case "start_camera":
            textureId = registry.register(self)
            setUpCamera(result: result)
        case "switch_effect":
            let effect:String = args?["effect"] as! String
            let key = registrar?.lookupKey(forAsset: effect)
            let topPath = Bundle.main.path(forResource: key, ofType: nil)
            deepAR.switchEffect(withSlot: "effect", path: topPath)
        case "start_recording_video":
            arView.startVideoRecording(withOutputWidth: 720, outputHeight: 1280)
            deepAR.startVideoRecording(withOutputWidth: 720, outputHeight: 1280)
        case "stop_recording_video":
            deepAR.finishVideoRecording()
        case "flip_camera":
            cameraController.position = cameraController.position == .back ? .front : .back
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
