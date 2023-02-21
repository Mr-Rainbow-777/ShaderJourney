#ifndef MyPBR_INCLUDED
#define MyPBR_INCLUDED


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"

#include "../ShaderLibrary/BRDF.hlsl" 
#include "MyLighting.hlsl" 

#define PI 3.1415926


struct Attributes
{
	float3 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float2 baseUV : TEXCOORD0;
};

struct Varyings
{
	float2 baseUV : TEXCOORD0;
	float4 positionCS : SV_POSITION;
	float3 positionWS : VAR_POSITION;
	float3 normalWS : VAR_NORMAL;
};

TEXTURE2D(_Albedo);
SAMPLER(sampler_Albedo);

TEXTURE2D(_MetallicMap);
SAMPLER(sampler_MetallicMap);

TEXTURECUBE(_IBL_Spec);
SAMPLER(sampler_IBL_Spec);

TEXTURE2D(_BRDFLUT);
SAMPLER(sampler_BRDFLUT);


CBUFFER_START(UnityPerMaterial)
half4 _Color;
float _Roughness;
float _Metallic;
float4 _Albedo_ST;
CBUFFER_END


Varyings VertLitpass(Attributes input)
{
	Varyings output;

	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	output.baseUV=TRANSFORM_TEX(input.baseUV, _Albedo);
	return output;
}

half4 FragLitpass(Varyings input) : SV_Target
{
	half3 normalWS = normalize(input.normalWS);
    half3 positionWS=input.positionWS;
    half3 view = normalize(_WorldSpaceCameraPos-positionWS);

    //对albedo和金属贴图采样
    half4 albedo=SAMPLE_TEXTURE2D(_Albedo,sampler_Albedo,input.baseUV);
    half4 MetallicInfo=SAMPLE_TEXTURE2D(_MetallicMap,sampler_MetallicMap,input.baseUV);


    //计算直接光
    half roughness=1-MetallicInfo.a*(1-_Roughness);  //物体越光滑   Alpha通道的值越大
    MyBRDFData _BRDFData;
    InitializeBRDFData((albedo*_Color).rgb,MetallicInfo.r*_Metallic,roughness,_BRDFData);
    //拿到光源信息
	Light light = GetMainLight();
	half NoL = saturate(dot(normalWS, light.direction));
	half3 irradiance = PI*NoL * light.color;
    half3 color=DirectBRDF(_BRDFData,normalWS,light.direction,view)*irradiance;

	
	//间接光的漫反射部分
	half NoV=saturate(dot(normalWS,view));
	half3 indirectColor=0;
	half3 indirectDiffuse=SampleSH(normalWS)*albedo*_Color;
	half3 ks=FresnelTerm_Roughness(_BRDFData.f0,NoV,_BRDFData.roughness);
	half3 kd=(1-ks)*(1-_BRDFData.metallic);
	indirectColor+=kd*indirectDiffuse;

	/*
	half NoV=saturate(dot(normalWS,view));
	float3 indirectDiff = SAMPLE_TEXTURECUBE(_IBL_Spec,sampler_IBL_Spec,float4(normalWS,_BRDFData.perceptualRoughness*12)) * albedo * RCP_PI;
	half3 indirectColor=0;
	half3 ks=FresnelTerm_Roughness(_BRDFData.f0,NoV,_BRDFData.roughness);
	half3 kd = (1 - ks)*(1 - _BRDFData.metallic);
	indirectColor += kd * indirectDiff;
	*/

	//间接光镜面反射部分
	float3 reflectDir=reflect(-view,normalWS);
	float3 prefilteredColor=SAMPLE_TEXTURECUBE_BIAS(_IBL_Spec,sampler_IBL_Spec,reflectDir,_BRDFData.perceptualRoughness*17).rgb;
	float4 scaleBias=SAMPLE_TEXTURE2D(_BRDFLUT,sampler_BRDFLUT,float2(NoV,_BRDFData.perceptualRoughness));
	half3 indirectSpec=BRDFIBLSpec(_BRDFData,scaleBias.xy)*prefilteredColor;
	indirectColor+=indirectSpec;

	color+=indirectColor;

	return half4(color,1);
}












#endif

