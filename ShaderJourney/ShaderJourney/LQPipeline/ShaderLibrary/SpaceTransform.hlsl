#ifndef _CUSTOM_TRANSFORM_MATRIX_FILE_
#define _CUSTOM_TRANSFORM_MATRIX_FILE_


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

//模型空间到世界空间
float3 TransformObjectToWorld(float3 positionOS)
{
    return mul(UNITY_MATRIX_M, float4(positionOS, 1.0)).xyz;
}

//世界空间到裁剪空间
float4 TransformWorldToHClip(float3 positionWS)
{
    return mul(UNITY_MATRIX_VP, float4(positionWS, 1.0));
}

//法线转换到世界空间，注意要乘以逆转置矩阵
float3 TransformObjectToWorldNormal(float3 normalOS, bool doNormalize = true)
{
    float3 normalWS = mul(normalOS, (float3x3)UNITY_MATRIX_I_M);
    if (doNormalize)
        return normalize(normalWS);

    return normalWS;
}



#endif