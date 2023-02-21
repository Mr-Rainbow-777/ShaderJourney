using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShapeGenerate
{
    private ShapeSetting _shapesetting;
    private INoiseFilter[] _noiseFilters;


    public MinMax evalutionMinMax;

    public void UpdateInfo(ShapeSetting setting)
    {
        this.evalutionMinMax = new MinMax();
        this._shapesetting = setting;
        _noiseFilters = new INoiseFilter[setting.NoiseLayers.Length];

        for (int i = 0; i < setting.NoiseLayers.Length; i++)
        {
            _noiseFilters[i] = NoiseFilterFactory.CreateNoiseFilter(setting.NoiseLayers[i].noiseSetting);
        }
    }

    public float CaluculateUnscaledElevation(Vector3 UnitSphere)
    {
        float value = 0;
        float FirstLayerValue = 0;

        if(_noiseFilters.Length>0)
        {
            FirstLayerValue = _noiseFilters[0].Evalute(UnitSphere);
            if (_shapesetting.NoiseLayers[0].enable)
            {
                value = FirstLayerValue;
            }
        }
        for (int i = 1; i < _noiseFilters.Length; i++)
        {
            if (_shapesetting.NoiseLayers[i].enable)
            { 
                float mask = _shapesetting.NoiseLayers[i].UseFirstLayerAsMask?FirstLayerValue:1;
                value += _noiseFilters[i].Evalute(UnitSphere)*mask;
            }
        }
        evalutionMinMax.AddValue(value);
        return value ;
    }

    public float GetScaledElevation(float UnscaledElevation)
    {
        float elevation = Mathf.Max(0,UnscaledElevation);
        elevation = _shapesetting.Radius * (1 + elevation);
        return elevation;
    }


}
