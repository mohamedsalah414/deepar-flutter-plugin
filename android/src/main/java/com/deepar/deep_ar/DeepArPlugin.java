package com.deepar.deep_ar;

import androidx.annotation.NonNull;
import android.util.Log;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;




import io.flutter.plugin.common.PluginRegistry;


/**
 * DeepArPlugin
 */
public class DeepArPlugin implements FlutterPlugin, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity


    private FlutterPluginBinding flutterPlugin;
    private DeepArHandler deepArHandler;


    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        onActivityAttached(binding);
    }



    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onActivityAttached(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        flutterPlugin = null;
    }


    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        flutterPlugin = flutterPluginBinding;
    }


    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        deepArHandler.clearChannerls();
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        Log.d("permission", "onRequestPermissionsResult: "+requestCode);
        return false;
    }
    private void onActivityAttached(@NonNull ActivityPluginBinding binding) {
        deepArHandler = new DeepArHandler(flutterPlugin, binding.getActivity());
        binding.addRequestPermissionsResultListener(this);
    }


}
