//
//  DeepArCamera.swift
//  deep_ar
//
//  Created by Samyak Jain on 14/07/22.
//
import DeepAR
import Foundation
import AVKit

enum PictureQuality: String {
    case low   = "low"
    case medium   = "medium"
    case high = "high"
    case veryHigh = "veryHigh"
}

enum DeepArResponse: String {
    case videoStarted   = "videoStarted"
    case videoCompleted   = "videoCompleted"
    case videoError = "videoError"
}

class DeepARCameraFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var registrar: FlutterPluginRegistrar
    
    init(messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar) {
        self.messenger = messenger
        self.registrar = registrar;
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return DeepARCameraView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger,registrar: registrar)
    }
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}


class DeepARCameraView: NSObject, FlutterPlatformView, DeepARDelegate {
    private var isRecordingInProcess: Bool = false
    
    private var deepAR: DeepAR!
    private var cameraController: CameraController!
    private var arView: ARView!
    private var frame:CGRect!
    
    
    private var pictureQuality:PictureQuality!
    private var licenseKey:String!
    private var videoFilePath:String!
    
    private var channel:FlutterMethodChannel!
    private var registrar: FlutterPluginRegistrar!
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?,
        registrar: FlutterPluginRegistrar
    ) {
        print("new native view");
        super.init()
        print("0");
        self.frame = frame;
        self.registrar = registrar
        print("1");
        if let dict = args as? [String: Any] {
            print("license key");
            print(dict["license_key"] as? String ?? "");
            self.licenseKey = (dict["license_key"] as? String ?? "")
            self.pictureQuality = PictureQuality.init(rawValue: dict["resolution"] as? String ?? "medium")
        }
        print("2");
        channel = FlutterMethodChannel(name: "deep_ar/view/" + String(viewId), binaryMessenger: messenger!);
        channel.setMethodCallHandler(methodHandler);
        print("3");
        createNativeView()
        print("4");
        
        
        
    }
    
    func methodHandler(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        let args = call.arguments as? [String : Any]
        switch call.method{
        case "switch_effect":
            let effect:String = args?["effect"] as! String
            let key = registrar?.lookupKey(forAsset: effect)
            let path = Bundle.main.path(forResource: key, ofType: nil)
            deepAR.switchEffect(withSlot: "effect", path: path)
            
        case "switch_face_mask":
            let mask:String = args?["effect"] as! String
            let key = registrar?.lookupKey(forAsset: mask)
            let path = Bundle.main.path(forResource: key, ofType: nil)
            deepAR.switchEffect(withSlot: "mask", path: path)
            
        case "switch_filter":
            let filter:String = args?["effect"] as! String
            let key = registrar?.lookupKey(forAsset: filter)
            let path = Bundle.main.path(forResource: key, ofType: nil)
            deepAR.switchEffect(withSlot: "filters", path: path)
            
        case "start_recording_video":
            startRecordingVideo();
            ///TODO: Send confirmation when callback received
            result("Starting to record");
        case "stop_recording_video":
            finishRecordingVideo();
            ///TODO: Send confirmation when callback received
            result("stopping recording");
        case "get_resolution":
            //            let width: Int32 = Int32(deepAR.renderingResolution.width)
            //            let height: Int32 =  Int32(deepAR.renderingResolution.height)
            result(String(1280) + " " + String(720));
        case "take_screenshot":
            deepAR.takeScreenshot()
            result("Screenshot called");
        case "flip_camera":
            cameraController.position = cameraController.position == .back ? .front : .back
            result(true);
        case "toggle_flash":
            let isFlash:Bool = toggleFlash()
            result(isFlash);
        default:
            result("No platform method found")
        }
        
    }
    
    func view() -> UIView {
        return arView
    }
    
    func createNativeView(){
        self.deepAR = DeepAR()
        self.deepAR.delegate = self
        self.deepAR.setLicenseKey(licenseKey)
        
        cameraController = CameraController()
        
        cameraController.preset = presetForPictureQuality(pictureQuality: pictureQuality);
        cameraController.videoOrientation = .portrait;
        cameraController.deepAR = self.deepAR
        self.deepAR.videoRecordingWarmupEnabled = false;
        
        
        deepAR.changeLiveMode(true);
        
        self.arView = self.deepAR.createARView(withFrame: self.frame) as? ARView
        cameraController.startCamera()
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    func toggleFlash() -> Bool {
        if cameraController.position == .front {
            // Prevent flash when front camera is on
            return false
        }
        
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            return false
        }
        
        if captureDevice.hasTorch {
            do {
                let _: () = try captureDevice.lockForConfiguration()
            } catch {
                print("error 1")
            }
            
            if captureDevice.isTorchActive {
                captureDevice.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                
                do {
                    let _ = try captureDevice.setTorchModeOn(level: 1.0)
                    return true // flash ON
                } catch {
                    print("error 2")
                }
            }
            
            captureDevice.unlockForConfiguration()
        }
        
        return false // flash OFF
    }
    
    
    func startRecordingVideo(){
        let width: Int32 = Int32(deepAR.renderingResolution.width)
        let height: Int32 =  Int32(deepAR.renderingResolution.height)
        
        deepAR.startVideoRecording(withOutputWidth: width, outputHeight: height)
        isRecordingInProcess = true
    }
    
    func finishRecordingVideo(){
        deepAR.finishVideoRecording();
    }
    
    func didFinishPreparingForVideoRecording() {
        NSLog("didFinishPreparingForVideoRecording!!!!!")
    }
    
    func didStartVideoRecording() {
        NSLog("didStartVideoRecording!!!!!")
        videoResult(callerResponse: DeepArResponse.videoStarted, message: "video started")
    }
    
    func recordingFailedWithError(_ error: Error!) {
        NSLog("recordingFailedWithError!!!!!")
        videoResult(callerResponse: DeepArResponse.videoError, message: "video error")
    }
    
    func didFinishVideoRecording(_ videoFilePath: String!) {
        
        NSLog("didFinishVideoRecording!!!!!")
        
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let components = videoFilePath.components(separatedBy: "/")
        guard let last = components.last else { return }
        
        self.videoFilePath = videoFilePath
//        let destination = URL(fileURLWithPath: String(format: "%@/%@", documentsDirectory, last))
//        
//        let playerController = AVPlayerViewController()
//        let player = AVPlayer(url: destination)
//        playerController.player = player
//        UIApplication.shared.keyWindow?.rootViewController?.present(playerController, animated: true) {
//            player.play()
//        }
        
        videoResult(callerResponse: DeepArResponse.videoCompleted, message: "video completed")
    }
    
    func didTakeScreenshot(_ screenshot: UIImage!) {
        UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil)
    }
    
    func presetForPictureQuality(pictureQuality: PictureQuality) -> AVCaptureSession.Preset {
        switch pictureQuality {
        case .low:
            return AVCaptureSession.Preset.vga640x480;
        case .medium:
            return AVCaptureSession.Preset.vga640x480;
        case .high:
            return AVCaptureSession.Preset.hd1280x720
        case .veryHigh:
            return AVCaptureSession.Preset.hd1920x1080;
        }
    }
    
    func resolutionForPictureQuality (pictureQuality: PictureQuality) -> CGSize {
        switch pictureQuality {
        case .low:
            return CGSize(width: 640, height: 480);
        case .medium:
            return CGSize(width: 640, height: 480);
        case .high:
            return CGSize(width: 1280, height: 720);
        case .veryHigh:
            return CGSize(width: 1920, height: 1080);
        }
    }
    
    func videoResult(callerResponse: DeepArResponse, message: String) {
        var map = [String : String]()
        map["caller"] = callerResponse.rawValue
        map["message"] = message
        if callerResponse == DeepArResponse.videoCompleted {
            map["file_path"] = videoFilePath
        }
        
        channel.invokeMethod("on_video_result", arguments: map)
    }
    
    @objc
    private func orientationDidChange() {
        guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else { return }
        switch orientation {
        case .landscapeLeft:
            cameraController.videoOrientation = .landscapeLeft
            break
        case .landscapeRight:
            cameraController.videoOrientation = .landscapeRight
            break
        case .portrait:
            cameraController.videoOrientation = .portrait
            break
        case .portraitUpsideDown:
            cameraController.videoOrientation = .portraitUpsideDown
        default:
            break
        }
        
    }
}
