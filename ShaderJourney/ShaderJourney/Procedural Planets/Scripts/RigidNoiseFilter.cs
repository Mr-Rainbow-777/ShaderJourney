using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RigidNoiseFilter : INoiseFilter
{
    Noise noise = new Noise();
    NoiseSetting.RigidNoiseSetting _noisesetting;

    public RigidNoiseFilter(NoiseSetting.RigidNoiseSetting noisesetting)
    {
        _noisesetting = noisesetting;
    }

    public float Evalute(Vector3 point)
    {
        float NoiseValue = 0;
        float frequency = _noisesetting.baseroughness;
        float amplitude = 1;
        float weight = 1;
        for (int i = 0; i < _noisesetting.numLayers; i++)
        {
            float value = 1 - Mathf.Abs(noise.Evaluate(point * frequency + _noisesetting.centre));
            value *= value;
            value *= weight;
            weight = Mathf.Clamp01(value*_noisesetting.WeightMultipler);

            NoiseValue += value* amplitude;
            frequency *= _noisesetting.roughness;
            amplitude *= _noisesetting.persistence;
        }
        NoiseValue = NoiseValue - _noisesetting.MinValue;
        return NoiseValue * _noisesetting.Strength;
    }
}
