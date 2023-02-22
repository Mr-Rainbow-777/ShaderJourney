using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DrawCircle : MonoBehaviour
{
    private Material material;
    public Material CircleMaterial
    {
        get
        {
            if(material == null)
            {
                material = new Material(_shader);
                material.hideFlags = HideFlags.HideAndDontSave;
            }
            return material;
        }
    }
    public Shader _shader;


    public float uvScale;
    public Color color;
    public float StepParam;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        CircleMaterial.SetFloat("uvScale", uvScale);
        CircleMaterial.SetColor("Color", color);
        CircleMaterial.SetFloat("StepParam", StepParam);




        Graphics.Blit(source, destination,CircleMaterial);
    }
}
