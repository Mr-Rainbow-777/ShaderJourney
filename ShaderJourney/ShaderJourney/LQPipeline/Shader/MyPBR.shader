Shader "PBRLearning/MyPBR"
{
Properties
    {
        _Albedo ("Albedo", 2D) = "white" {}
        _MetallicMap ("metallicmap", 2D) = "white" {}
        _Metallic("metallicValue",Range(0.01,1))=0.5
        _IBL_Spec("Specular Cube",Cube)="black"{}
        _BRDFLUT("LUT",2D)="White"{}
        _Color("Color Options",Color) = (1,1,1,1)
        _Roughness("Roughness",Range(0.01,0.99))=0.5


    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}


        Pass
        {
            HLSLPROGRAM
            #include "MyPBR.hlsl"

            #pragma vertex VertLitpass
            #pragma fragment FragLitpass
            ENDHLSL
        }
    }
}
