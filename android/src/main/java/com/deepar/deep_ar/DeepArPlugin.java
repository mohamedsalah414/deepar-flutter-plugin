package com.deepar.deep_ar;

import androidx.annotation.NonNull;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.SurfaceTexture;
import android.media.Image;
import android.os.AsyncTask;
import android.util.Log;
import android.view.Surface;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.Map;

import ai.deepar.ar.ARErrorType;
import ai.deepar.ar.AREventListener;
import ai.deepar.ar.DeepARImageFormat;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryCodec;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import io.flutter.plugin.common.StandardMethodCodec;
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

  private ByteBuffer[] buffers;
  //private ByteBuffer buffer;
  private int currentBuffer = 0;
  private static final int NUMBER_OF_BUFFERS=2;

  private Context context;
  private String TAG = "DEEP_AR_LOGS";
  ArrayList<String> effects;
  ByteBuffer emptyBuffer = ByteBuffer.allocateDirect(1);

  private void initializeFilters() {
    effects = new ArrayList<>();
    effects.add("none");
    effects.add("viking_helmet.deepar");
    effects.add("MakeupLook.deepar");
    effects.add("Split_View_Look.deepar");
    effects.add("Emotions_Exaggerator.deepar");
    effects.add("Emotion_Meter.deepar");
    effects.add("Stallone.deepar");
    effects.add("flower_face.deepar");
    effects.add("galaxy_background.deepar");
    effects.add("Humanoid.deepar");
    effects.add("Neon_Devil_Horns.deepar");
    effects.add("Ping_Pong.deepar");
    effects.add("Pixel_Hearts.deepar");
    effects.add("Snail.deepar");
    effects.add("Hope.deepar");
    effects.add("Vendetta_Mask.deepar");
    effects.add("Fire_Effect.deepar");
    effects.add("burning_effect.deepar");
    effects.add("Elephant_Trunk.deepar");
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    this.textures = flutterPluginBinding.getTextureRegistry();
   context = flutterPluginBinding.getApplicationContext();
   channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "deep_ar");
   channel.setMethodCallHandler(this);
    final BasicMessageChannel<ByteBuffer> framesChannel =
            new BasicMessageChannel<>(flutterPluginBinding.getBinaryMessenger(), "deep_ar/frames", BinaryCodec.INSTANCE);
    framesChannel.setMessageHandler((byteBuffer, reply) -> {
      Log.v(TAG, "Received message from Dart...");
      buffers[currentBuffer].put(byteBuffer);
      buffers[currentBuffer].position(0);
      try {
        deepAR.receiveFrame(buffers[currentBuffer] , 1280 , 720, 270, true, DeepARImageFormat.YUV_420_888, 2);
      }catch (Exception e){
        Log.e("ERROR", e.getMessage());
      }
      currentBuffer = (currentBuffer + 1) % NUMBER_OF_BUFFERS;

      Log.v(TAG, "Writing response back to Dart...");
      reply.reply(emptyBuffer);
    });
  }


  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    Map<String, Object> arguments = (Map<String, Object>) call.arguments;
    if (call.method.equals("switch_effect")) {
      int effect = ((Number) arguments.get("effect")).intValue();
      Log.d(TAG, "onMethodCall: switch_effect = "+effect);
      deepAR.switchEffect("effect", getFilterPath(effects.get(effect)));
      result.success("Effect Changed" );

    }
    else if (call.method.equals("getPlatformVersion")) {

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

      initializeFilters(); // all deepAR filters

      deepAR.changeLiveMode(true);

      // initialise buffer to be used to render frames
      buffers = new ByteBuffer[NUMBER_OF_BUFFERS];
      for (int i = 0; i < NUMBER_OF_BUFFERS; i++) {
        buffers[i] = ByteBuffer.allocateDirect(1080 * 1920 * 3);
        buffers[i].order(ByteOrder.nativeOrder());
        buffers[i].position(0);
      }
      return true;
    } catch (Exception e) {
      Log.e(TAG, "ERROR" + e);
      return false;
    }

  }

  private String getFilterPath(String filterName) {
    if (filterName.equals("none")) {
      return null;
    }
    return "file:///android_asset/" + filterName;
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
    Log.d(TAG, "frameAvailable: "+image.getHeight());
  }

  @Override
  public void error(ARErrorType arErrorType, String s) {

  }

  @Override
  public void effectSwitched(String s) {

  }
}
