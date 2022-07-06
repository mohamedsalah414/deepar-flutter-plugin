package com.deepar.deep_ar;

import java.util.ArrayList;

public class DeepArEffects {

    public DeepArEffects() {
        initializeEffects();
    }

    private ArrayList<String> effects;
    private void initializeEffects() {
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

    public String getFilterPath(int effectIndex) {
        String effect = effects.get(effectIndex);
        if (effect.equals("none")) {
            return null;
        }
        return "file:///android_asset/" + effect;
    }
}
