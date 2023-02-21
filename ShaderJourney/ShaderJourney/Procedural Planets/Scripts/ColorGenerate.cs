using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ColorGenerate
{
    public ColorSetting colorSetting;
    const int TextureResolution = 50;
    Texture2D Tex;
    INoiseFilter noiseFilter;

    public void UpdateInfo(ColorSetting setting)
    {
        this.colorSetting = setting;
        if (Tex == null || Tex.height!= setting.biomeSetting.Biomes.Length)
        {
            Tex = new Texture2D(TextureResolution*2, setting.biomeSetting.Biomes.Length,TextureFormat.RGBA32,false);
        }
        noiseFilter = NoiseFilterFactory.CreateNoiseFilter(setting.biomeSetting.noise);
    }

    public void UpdateEvevation(MinMax minmax)
    {
        colorSetting.PlanetMaterial.SetVector("_EvalutionMinMax", new Vector4(minmax.Min, minmax.Max));
    }


    public float BiomePercentFromPoint(Vector3 UnitSphere)
    {
        float heightPercent = (UnitSphere.y + 1) / 2;
        heightPercent += noiseFilter.Evalute(UnitSphere) - colorSetting.biomeSetting.noiseOffset * colorSetting.biomeSetting.noiseStrength;
        float BlendRange = colorSetting.biomeSetting.BlendAmount / 2f + 0.001f;
        float biomeIndex = 0;
        int numBiomes = colorSetting.biomeSetting.Biomes.Length;

        for (int i = 0; i < numBiomes; i++)
        {
            if (!colorSetting.biomeSetting.Biomes[i].enable) { continue; }
            float dst = heightPercent - colorSetting.biomeSetting.Biomes[i].startHeight;
            float weight = Mathf.InverseLerp(-BlendRange, BlendRange, dst);
            biomeIndex *= (1 - weight);
            biomeIndex += i * weight;
        }

        return biomeIndex / Mathf.Max(1, numBiomes - 1);
    }

    public void UpdateColors()
    {
        Color[] colors = new Color[Tex.width*Tex.height];
        int colorIndex = 0;
        foreach (var biome in colorSetting.biomeSetting.Biomes)
        {
            if (!biome.enable) { continue; }
            for (int i = 0; i < TextureResolution*2; i++)
            {
                Color gradientColor; 
                if(i<TextureResolution)
                {
                    gradientColor = colorSetting.oceanColor.Evaluate(i / (TextureResolution - 1f));
                }
                else
                {
                    gradientColor = biome.gradient.Evaluate((i - TextureResolution) / (TextureResolution - 1f));
                }
                Color tintColor = biome.tint;
                colors[colorIndex++] = gradientColor * (1 - biome.tintPercent) + tintColor * biome.tintPercent;
            }
        }
        Tex.SetPixels(colors);
        Tex.Apply();
        colorSetting.PlanetMaterial.SetTexture("_Texture", Tex);
    }

}
