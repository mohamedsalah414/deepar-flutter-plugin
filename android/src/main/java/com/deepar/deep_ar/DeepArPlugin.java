package com.deepar.deep_ar;

import androidx.annotation.NonNull;

import android.graphics.SurfaceTexture;
import android.view.Surface;

import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import io.flutter.view.TextureRegistry;

/** DeepArPlugin */
public class DeepArPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private TextureRegistry textures;

  private SurfaceTexture surfaceTexture;
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "deep_ar");
    this.textures = flutterPluginBinding.getTextureRegistry();
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    Map<String, Number> arguments = (Map<String, Number>) call.arguments;
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    }if(call.method.equals("buildPreview")){
      TextureRegistry.SurfaceTextureEntry entry = textures.createSurfaceTexture();

       surfaceTexture = entry.surfaceTexture();
      int width = arguments.get("width").intValue();
      int height = arguments.get("height").intValue();
      surfaceTexture.setDefaultBufferSize(width, height);
              result.success(entry.id());

    } else if (call.method.equals("dispose")) {
      long textureId = arguments.get("textureId").longValue();
      surfaceTexture.release();
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
