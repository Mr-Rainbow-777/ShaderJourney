using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
public class Pixel_Filter : VolumeComponent, IPostProcessComponent
{
    [Range(1f, 64f)]
    public FloatParameter PixelSize = new FloatParameter(0);




    public bool IsActive() => PixelSize.value > 0;

    public bool IsTileCompatible()
    {
        return false;
    }
}
