using UnityEngine.Rendering;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class BloomSetting : VolumeComponent, IPostProcessComponent
{

    [Range(0.0f, 2.0f)]
    public FloatParameter luminanceThreshold = new FloatParameter(0);

    [Range(0f, 5f)]
    public FloatParameter BlurSize = new FloatParameter(0f);

    [Range(1, 15)]
    public IntParameter Iteration = new IntParameter(6);

    [Range(1, 8)]
    public FloatParameter RTDownScaling = new FloatParameter(2f);



    public bool IsActive()
    {
        return luminanceThreshold.value > 0;
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
