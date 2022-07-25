package com.deepar.ai;

import ai.deepar.ar.CameraResolutionPreset;

public class DeepArResolution {

    static CameraResolutionPreset getResolutionPreset(String resolution){
        switch (resolution){
            case "low":
                return CameraResolutionPreset.P640x360;
            case "medium":
                return CameraResolutionPreset.P640x480;
            case "high":
                return CameraResolutionPreset.P1280x720;
            case "veryHigh":
                return CameraResolutionPreset.P1920x1080;
        }
        return null;
    }
}
