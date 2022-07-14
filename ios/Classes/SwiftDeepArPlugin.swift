import Flutter
import UIKit
import DeepAR
import AVFoundation
import Photos
public class SwiftDeepArPlugin: NSObject, FlutterPlugin, FlutterTexture,  DeepARDelegate ,AVAudioRecorderDelegate{
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "deep_ar", binaryMessenger: registrar.messenger())
        let instance = SwiftDeepArPlugin(registrar.textures())
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.registrar = registrar
    }
    
    var registrar: FlutterPluginRegistrar? = nil
    let registry: FlutterTextureRegistry
    var textureId: Int64!
    var latestBuffer: CVImageBuffer!
    var deepAR: DeepAR!
    var session: AVCaptureSession?
    let videoOutput = AVCaptureVideoDataOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    var audioRecorder: AVAudioRecorder!
    private var arView: ARView!
    
    private var cameraController: CameraController!
    private var frameCount:Int = 0;
    private var startTime:DispatchTime?;
    
    
    init(_ registry: FlutterTextureRegistry) {
        self.registry = registry
        super.init()
    }
    
    
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
            _captureState = _CaptureState.start;
            result("Starting to record");
        case "stop_recording_video":
            _captureState = _CaptureState.end;
            result("stopping recording");
            
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
    
    private func setupDeepARCamera(licenseKey: String) {
        self.deepAR = DeepAR();
        self.deepAR.setLicenseKey(licenseKey)
        self.deepAR.delegate = self
        self.deepAR.changeLiveMode(true);
        
        //self.deepAR.initializeOffscreen(withWidth: 720, height: 1280);
        
        cameraController = CameraController()
        cameraController.preset = AVCaptureSession.Preset.hd1280x720
        cameraController.videoOrientation = .portrait;
        cameraController.startAudio();
        
        cameraController.deepAR = self.deepAR
        self.deepAR.videoRecordingWarmupEnabled = false;
        
        self.arView = self.deepAR.createARView(withFrame: CGRect(x: 0, y: 0, width: 720, height: 1280)) as? ARView
        
        cameraController.startCamera()
    }
    

    
    
    public func didInitialize() {
        print("DEEPAR INIT")

        deepAR.startCapture(withOutputWidth: 720, outputHeight: 1280, subframe: CGRect(x: 0, y: 0, width: 1, height: 1))
    }
   
    
    ///Frames available should be triggered when enque camera frames are available
    public func frameAvailable(_ sampleBuffer: CMSampleBuffer!) {
        latestBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        recordVideoFromFrames(didOutput: sampleBuffer);
        
        ///update preview in flutter
        registry.textureFrameAvailable(textureId)
    }
    
    
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if latestBuffer == nil {
            return nil
        }
        return Unmanaged<CVPixelBuffer>.passRetained(latestBuffer)
    }

    private enum _CaptureState {
           case idle, start, capturing, end
       }
    private var _assetWriter: AVAssetWriter?
    private var _assetWriterInput: AVAssetWriterInput?
    private var _adpater: AVAssetWriterInputPixelBufferAdaptor?
    private var _captureState = _CaptureState.idle
    private var _filename = ""
    private var _time: Double = 0

    
    func recordVideoFromFrames( didOutput sampleBuffer: CMSampleBuffer) {
          switch _captureState {
          case .start:
              let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
              // Set up recorder
              _filename = UUID().uuidString
              let videoPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(_filename).mov")
              let writer = try! AVAssetWriter(outputURL: videoPath, fileType: .mov)
             
              let settings = AVCaptureVideoDataOutput().recommendedVideoSettingsForAssetWriter(writingTo: .mp4)
              let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings) // [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 1920, AVVideoHeightKey: 1080])
              input.mediaTimeScale = CMTimeScale(bitPattern: 600)
              input.expectsMediaDataInRealTime = true
//              input.transform = CGAffineTransform(rotationAngle: .pi/2)
              let adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
              if writer.canAdd(input) {
                  writer.add(input)
              }
              writer.startWriting()
              writer.startSession(atSourceTime: .zero)
              _assetWriter = writer
              _assetWriterInput = input
              _adpater = adapter
              _captureState = .capturing
              _time = timestamp
          case .capturing:
              print("appending frame");
              let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
              if _assetWriterInput?.isReadyForMoreMediaData == true {
                  let time = CMTime(seconds: timestamp - _time, preferredTimescale: CMTimeScale(600))
                  _adpater?.append(CMSampleBufferGetImageBuffer(sampleBuffer)!, withPresentationTime: time)
              }
              break
          case .end:
              guard _assetWriterInput?.isReadyForMoreMediaData == true, _assetWriter!.status != .failed else { break }
              let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(_filename).mov")
              _assetWriterInput?.markAsFinished()
              _assetWriter?.finishWriting { [weak self] in
                  self?._captureState = .idle
                  self?._assetWriter = nil
                  self?._assetWriterInput = nil
                  DispatchQueue.main.async {
                      let status = PHPhotoLibrary.authorizationStatus()

                         //no access granted yet
                         if status == .notDetermined || status == .denied{
                             PHPhotoLibrary.requestAuthorization({auth in
                                 if auth == .authorized{
                                     self?.saveInPhotoLibrary(url)
                                 }else{
                                     print("user denied access to photo Library")
                                 }
                             })

                         //access granted by user already
                         }else{
                             self?.saveInPhotoLibrary(url)
                         }
                  }
              }
          default:
              break
          }
      }
    private func saveInPhotoLibrary(_ url:URL){
        PHPhotoLibrary.shared().performChanges({

            //add video to PhotoLibrary here
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { completed, error in
            if completed {
                print("save complete! path : " + url.absoluteString)
            }else{
                print("save failed")
            }
        }
    }
    private func setUpCamera(result: @escaping FlutterResult){
        let size = ["width": 720.0, "height": 1280.0]
        let answer: [String : Any?] = ["textureId": textureId, "size": size]
        result(answer)
        
    }
}
