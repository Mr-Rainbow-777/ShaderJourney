using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SimpleNoiseFilter :INoiseFilter
{
    Noise noise = new Noise();
    NoiseSetting.SimpleNoiseSetting _noisesetting;

    public SimpleNoiseFilter(NoiseSetting.SimpleNoiseSetting noisesetting)
    {
        _noisesetting = noisesetting;
    }

    public float Evalute(Vector3 point)
    {
        float NoiseValue = 0;
        float frequency = _noisesetting.baseroughness;
        float amplitude = 1;
        for (int i = 0; i < _noisesetting.numLayers; i++)
        {
            float value = noise.Evaluate(point * frequency + _noisesetting.centre);
            NoiseValue += (value + 1) * .5f * amplitude;
            frequency *= _noisesetting.roughness;
            amplitude *= _noisesetting.persistence;
        }
        NoiseValue = NoiseValue - _noisesetting.MinValue;
        return NoiseValue*_noisesetting.Strength;
    }
}
