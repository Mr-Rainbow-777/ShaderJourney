using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class NoiseFilterFactory
{
    

    public static INoiseFilter CreateNoiseFilter(NoiseSetting setting)
    {
        switch (setting.noiseFilterType)
        {
            case NoiseSetting.NoiseFilterType.SimpleNoiseFilter:
                return new SimpleNoiseFilter(setting.simpleNoiseSetting);
            case NoiseSetting.NoiseFilterType.RigidNoiseFilter:
                return new RigidNoiseFilter(setting.rigidNoiseSetting);
            default:
                return null;
        }
    }
}
