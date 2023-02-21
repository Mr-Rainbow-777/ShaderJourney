using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "Color Setting", menuName = "Planet Setting/Color")]
public class ColorSetting : ScriptableObject
{
    public BiomeColorSetting biomeSetting;
    public Material PlanetMaterial;
    public Gradient oceanColor;

    [System.Serializable]
    public class BiomeColorSetting
    {
        public Biome[] Biomes;
        public NoiseSetting noise;
        public float noiseOffset;
        public float noiseStrength;
        [Range(0,1)]
        public float BlendAmount;

        [System.Serializable]
        public class Biome
        {
            public bool enable = true;
            public Gradient gradient;
            public Color tint;
            [Range(0,1)]
            public float startHeight;
            [Range(0,1)]
            public float tintPercent;

        }
    }


}
