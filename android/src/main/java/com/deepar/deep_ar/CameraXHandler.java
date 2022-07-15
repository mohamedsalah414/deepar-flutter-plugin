package com.deepar.deep_ar;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.Size;
import android.view.Surface;

import androidx.annotation.NonNull;
import androidx.camera.core.Camera;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageProxy;
import androidx.camera.core.TorchState;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.core.content.ContextCompat;
import androidx.lifecycle.LifecycleOwner;

import com.google.common.util.concurrent.ListenableFuture;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executor;

import ai.deepar.ar.CameraResolutionPreset;
import ai.deepar.ar.DeepAR;
import ai.deepar.ar.DeepARImageFormat;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class CameraXHandler implements MethodChannel.MethodCallHandler {
    CameraXHandler(Activity activity, long textureId, DeepAR deepAR, CameraResolutionPreset cameraResolutionPreset) {
        this.activity = activity;
        this.deepAR = deepAR;
        this.textureId = textureId;
        this.resolutionPreset = cameraResolutionPreset;
    }

    final private Activity activity;
    final private DeepAR deepAR;
    private final long textureId;
    private ProcessCameraProvider processCameraProvider;
    private ListenableFuture<ProcessCameraProvider> future;
    private ByteBuffer[] buffers;
    private int currentBuffer = 0;
    private static final int NUMBER_OF_BUFFERS = 2;
    private final CameraResolutionPreset resolutionPreset;

    private int defaultLensFacing = CameraSelector.LENS_FACING_FRONT;
    private int lensFacing = defaultLensFacing;
    private Camera camera;


    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {

        switch (call.method) {
            case MethodStrings.startCamera:
                startNative(result);
                break;
            case "flip_camera":
                flipCamera();
            case "toggle_flash":
                try {
                    if (camera != null && camera.getCameraInfo().hasFlashUnit()) {
                        // TorchState.OFF = 0; TorchState.ON = 1
                        boolean isFlashOn = camera.getCameraInfo().getTorchState().getValue() == TorchState.ON;

                        camera.getCameraControl().enableTorch(!isFlashOn);


                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }


                break;
        }
    }

    private void flipCamera() {
        lensFacing = lensFacing == CameraSelector.LENS_FACING_FRONT ? CameraSelector.LENS_FACING_BACK : CameraSelector.LENS_FACING_FRONT;
        //unbind immediately to avoid mirrored frame.
        ProcessCameraProvider cameraProvider = null;
        try {
            cameraProvider = future.get();
            cameraProvider.unbindAll();
        } catch (ExecutionException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        startNative(null);
    }

    int numberOfTimes = 0;

    private void startNative(MethodChannel.Result result) {
        future = ProcessCameraProvider.getInstance(activity);
        Executor executor = ContextCompat.getMainExecutor(activity);

        int width;
        int height;
        int orientation = getScreenOrientation();
        if (orientation == ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE || orientation == ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE) {
            width = resolutionPreset.getWidth();
            height = resolutionPreset.getHeight();
        } else {
            width = resolutionPreset.getHeight();
            height = resolutionPreset.getWidth();
        }
        buffers = new ByteBuffer[NUMBER_OF_BUFFERS];
        for (int i = 0; i < NUMBER_OF_BUFFERS; i++) {
            buffers[i] = ByteBuffer.allocateDirect
                    (CameraResolutionPreset.P1920x1080.getWidth()
                            * CameraResolutionPreset.P1920x1080.getHeight() * 3);
            buffers[i].order(ByteOrder.nativeOrder());
            buffers[i].position(0);
        }

        future.addListener(new Runnable() {
            @Override
            public void run() {
                try {
                    processCameraProvider = future.get();
                    Size cameraResolution = new Size(width, height);
                    ImageAnalysis.Analyzer analyzer = new ImageAnalysis.Analyzer() {
                        @Override
                        public void analyze(@NonNull ImageProxy image) {
                            byte[] byteData;
                            ByteBuffer yBuffer = image.getPlanes()[0].getBuffer();
                            ByteBuffer uBuffer = image.getPlanes()[1].getBuffer();
                            ByteBuffer vBuffer = image.getPlanes()[2].getBuffer();

                            int ySize = yBuffer.remaining();
                            int uSize = uBuffer.remaining();
                            int vSize = vBuffer.remaining();

                            byteData = new byte[ySize + uSize + vSize];

                            //U and V are swapped
                            yBuffer.get(byteData, 0, ySize);
                            vBuffer.get(byteData, ySize, vSize);
                            uBuffer.get(byteData, ySize + vSize, uSize);

                            buffers[currentBuffer].put(byteData);
                            buffers[currentBuffer].position(0);
                            if (deepAR != null) {

                                try {
                                    numberOfTimes++;
                                    Log.d("", "NUMBER_TIMES " + numberOfTimes);
                                    long startTime = System.nanoTime();
                                    deepAR.receiveFrame(buffers[currentBuffer],
                                            image.getWidth(), image.getHeight(),
                                            image.getImageInfo().getRotationDegrees(),
                                            lensFacing == CameraSelector.LENS_FACING_FRONT,
                                            DeepARImageFormat.YUV_420_888,
                                            image.getPlanes()[1].getPixelStride()
                                    );
                                    Log.e("Measure", "TASK took_ : " + numberOfTimes + " => " + ((System.nanoTime() - startTime) / 1000000) + "mS\n");
                                } catch (Exception e) {
                                    e.printStackTrace();
                                    Log.e("ERRRR", "" + e);
                                }

                            }
                            currentBuffer = (currentBuffer + 1) % NUMBER_OF_BUFFERS;
                            image.close();
                        }
                    };

                    CameraSelector cameraSelector = new CameraSelector.Builder().requireLensFacing(lensFacing).build();

                    ImageAnalysis imageAnalysis = new ImageAnalysis.Builder()
                            .setTargetResolution(cameraResolution)
                            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                            .build();

                    imageAnalysis.setAnalyzer(executor, analyzer);

                    processCameraProvider.unbindAll();

                    camera = processCameraProvider.bindToLifecycle((LifecycleOwner) activity,
                            cameraSelector, imageAnalysis);

                    if (result != null) {
                        result.success(textureId);
                    }

                } catch (ExecutionException e) {
                    e.printStackTrace();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }

            }
        }, executor);

    }

    private int getScreenOrientation() {

        int rotation = activity.getWindowManager().getDefaultDisplay().getRotation();
        DisplayMetrics dm = new DisplayMetrics();
        activity.getWindowManager().getDefaultDisplay().getMetrics(dm);
        int width = dm.widthPixels;
        int height = dm.heightPixels;
        int orientation;
        // if the device's natural orientation is portrait:
        if ((rotation == Surface.ROTATION_0
                || rotation == Surface.ROTATION_180) && height > width ||
                (rotation == Surface.ROTATION_90
                        || rotation == Surface.ROTATION_270) && width > height) {
            switch (rotation) {
                case Surface.ROTATION_0:
                    orientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
                    break;
                case Surface.ROTATION_90:
                    orientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
                    break;
                case Surface.ROTATION_180:
                    orientation =
                            ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT;
                    break;
                case Surface.ROTATION_270:
                    orientation =
                            ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE;
                    break;
                default:
                    orientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
                    break;
            }
        }
        // if the device's natural orientation is landscape or if the device
        // is square:
        else {
            switch (rotation) {
                case Surface.ROTATION_0:
                    orientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
                    break;
                case Surface.ROTATION_90:
                    orientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
                    break;
                case Surface.ROTATION_180:
                    orientation =
                            ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE;
                    break;
                case Surface.ROTATION_270:
                    orientation =
                            ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT;
                    break;
                default:
                    orientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
                    break;
            }
        }

        return orientation;
    }
}
