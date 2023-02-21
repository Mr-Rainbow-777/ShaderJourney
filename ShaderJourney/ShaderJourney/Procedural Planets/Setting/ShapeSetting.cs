using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName ="Shape Setting",menuName ="Planet Setting/Shape")]
public class ShapeSetting : ScriptableObject
{
    [Range(1,256)]
    public float Radius;
    public NoiseLayer[] NoiseLayers;


    [System.Serializable]
    public class NoiseLayer
    {
        public bool enable=true;
        public bool UseFirstLayerAsMask = false;
        public NoiseSetting noiseSetting;
    }
}
