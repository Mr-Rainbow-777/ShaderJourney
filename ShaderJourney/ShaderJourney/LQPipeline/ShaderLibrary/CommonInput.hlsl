#ifndef _CUSTOM_COMMON_INPUT_FILE_
#define _CUSTOM_COMMON_INPUT_FILE_


//Unity内置变量
float4x4 unity_MatrixVP;


CBUFFER_START(unityPerDraw)
float4x4 unity_ObjectToWorld;
float4x4 unity_WorldToObject;
CBUFFER_END







#endif