using System;
using UnityEngine;
[Serializable]
public class NoiseSetting
{
    public enum NoiseFilterType
    {
        SimpleNoiseFilter,
        RigidNoiseFilter,

    }
    public NoiseFilterType noiseFilterType;

    [ConditionalHide("noiseFilterType",0)]
    public SimpleNoiseSetting simpleNoiseSetting;
    [ConditionalHide("noiseFilterType", 1)]
    public RigidNoiseSetting rigidNoiseSetting;


    [Serializable]
    public class SimpleNoiseSetting
    { 
        public float Strength;
        [Range(1,5)]
        public int numLayers = 4;
        public float roughness=2;
        public float baseroughness=1;
        public float persistence = .5f;
        public Vector3 centre;
        public float MinValue=0;
    }

    [Serializable]
    public class RigidNoiseSetting : SimpleNoiseSetting
    {
        public float WeightMultipler = .8f;
    }
}
