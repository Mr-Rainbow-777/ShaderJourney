using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

public class GaussianBlur : VolumeComponent, IPostProcessComponent
{
    [Range(0f, 5f)]
    public FloatParameter BlurRadius = new FloatParameter(0f);

    [Range(1, 15)]
    public IntParameter Iteration = new IntParameter(6);

    [Range(1, 8)]
    public FloatParameter RTDownScaling = new FloatParameter(2f);


    public bool IsActive() => BlurRadius.value > 0f;

    public bool IsTileCompatible() => false;
}
