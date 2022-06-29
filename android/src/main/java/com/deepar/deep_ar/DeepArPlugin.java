package com.deepar.deep_ar;

import androidx.annotation.NonNull;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.SurfaceTexture;
import android.media.Image;
import android.util.Log;
import android.view.Surface;

import java.nio.ByteBuffer;
import java.util.Map;

import ai.deepar.ar.ARErrorType;
import ai.deepar.ar.AREventListener;
import ai.deepar.ar.DeepARImageFormat;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import io.flutter.view.TextureRegistry;
import ai.deepar.ar.DeepAR;
/** DeepArPlugin */
public class DeepArPlugin implements FlutterPlugin, MethodCallHandler, AREventListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private DeepAR deepAR;

  private TextureRegistry textures;
  private SurfaceTexture surfaceTexture;

  private Context context;
  private String TAG = "DEEP_AR_LOGS";
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    this.textures = flutterPluginBinding.getTextureRegistry();
    context = flutterPluginBinding.getApplicationContext();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "deep_ar");
    channel.setMethodCallHandler(this);


  }


  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    Map<String, Object> arguments = (Map<String, Object>) call.arguments;
    if (call.method.equals(MethodStrings.receiveFrame)) {
      Log.d(TAG, "MethodStrings.receiveFramesInNative Begin");
      final ByteBuffer yBuffer = ByteBuffer.wrap((byte[]) arguments.get("y_plane")) ;
      final ByteBuffer uBuffer = ByteBuffer.wrap((byte[]) arguments.get("u_plane")) ;
      final ByteBuffer vBuffer = ByteBuffer.wrap((byte[]) arguments.get("v_plane")) ;
      int imageHeight = (int) arguments.get("image_height");
      int imageWidth = (int) arguments.get("image_width");
      int pixelStride = (int) arguments.get("pixel_stride");

      int ySize = yBuffer.remaining();
      int uSize = uBuffer.remaining();
      int vSize = vBuffer.remaining();
      byte[] byteData;
      byteData = new byte[ySize + uSize + vSize];

      //U and V are swapped
      yBuffer.get(byteData, 0, ySize);
      vBuffer.get(byteData, ySize, vSize);
      uBuffer.get(byteData, ySize + vSize, uSize);
      try {
        ByteBuffer buffer = ByteBuffer.wrap(byteData);
        deepAR.receiveFrame(buffer, imageWidth , imageHeight, 0, false, DeepARImageFormat.YUV_420_888, pixelStride);
      }catch (Exception e){
        Log.e("ERROR", e.getMessage());
      }
      Log.d(TAG, "MethodStrings.receiveFramesInNative End");
      result.success(1);
    }else if (call.method.equals("getPlatformVersion")) {

      result.success("Android " + android.os.Build.VERSION.RELEASE);

    }else if(call.method.equals(MethodStrings.initalize)){

      final boolean resp  = initializeDeepAR();
      result.success(resp);

    } else if(call.method.equals(MethodStrings.buildPreview)){
      
      TextureRegistry.SurfaceTextureEntry entry = textures.createSurfaceTexture();

      surfaceTexture = entry.surfaceTexture();

      int width = ((Number) arguments.get("width")).intValue();
      int height =((Number) arguments.get("height")).intValue();

      surfaceTexture.setDefaultBufferSize(width, height);
      deepAR.setRenderSurface(new Surface(surfaceTexture), width, height);
      result.success(entry.id());

    } else if (call.method.equals(MethodStrings.dispose)) {
      surfaceTexture.release();
      result.success(true);
    } else {
      result.notImplemented();
    }
  }

  private boolean initializeDeepAR() {
    try {
      deepAR = new DeepAR(context);
      deepAR.setLicenseKey("53de9b68021fd5be051ddd80c8d1aee5653eda7cabcd58776c1a96e5027f4a8c78d4946795ccd944");
      deepAR.initialize(context, this);
      return true;
    } catch (Exception e) {
      Log.e(TAG, "ERROR" + e);
      return false;
    }

  }


  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void screenshotTaken(Bitmap bitmap) {

  }

  @Override
  public void videoRecordingStarted() {

  }

  @Override
  public void videoRecordingFinished() {

  }

  @Override
  public void videoRecordingFailed() {

  }

  @Override
  public void videoRecordingPrepared() {

  }

  @Override
  public void shutdownFinished() {

  }

  @Override
  public void initialized() {

  }

  @Override
  public void faceVisibilityChanged(boolean b) {

  }

  @Override
  public void imageVisibilityChanged(String s, boolean b) {

  }

  @Override
  public void frameAvailable(Image image) {

  }

  @Override
  public void error(ARErrorType arErrorType, String s) {

  }

  @Override
  public void effectSwitched(String s) {

  }
}
