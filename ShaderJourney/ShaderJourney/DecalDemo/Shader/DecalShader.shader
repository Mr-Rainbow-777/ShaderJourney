Shader "My Shader/DecalShader"
{
    Properties
    {
        _BaseMap("Project Texture", 2D) = "white" {}
    }
        SubShader
    {
        Tags {  "RenderPipeline" = "UniversalPipeline"
                "RenderType" = "Transparent" 
                "Queue" = "Transparent-400" 
                "DisableBatching" = "True"}

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float3 posWS : TEXCOOED1;
                float4 posNDC : TEXCOOED2;
                float4 posCS : SV_POSITION;
                float3 ray : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            CBUFFER_END


            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);


            float3 getProjectedObjectPos(float2 screenPos, float3 worldRay) {
                //get depth from depth texture
                float depth = SampleSceneDepth(screenPos);
                depth = Linear01Depth(depth, _ZBufferParams) * _ProjectionParams.z;
                //get a ray thats 1 long on the axis from the camera away (because thats how depth is defined)
                worldRay = normalize(worldRay);
                //the 3rd row of the view matrix has the camera forward vector encoded, so a dot product with that will give the inverse distance in that direction
                worldRay /= dot(worldRay, -UNITY_MATRIX_V[2].xyz);
                //with that reconstruct world and object space positions 
                float3 worldPos = _WorldSpaceCameraPos + worldRay * depth;
                float3 objectPos = mul(unity_WorldToObject, float4(worldPos, 1)).xyz;
                //discard pixels where any component is beyond +-0.5
                clip(0.5 - abs(objectPos));
                //get -0.5|0.5 space to 0|1 for nice texture stuff if thats what we want
                objectPos += 0.5;
                return objectPos;
            }



            Varyings vert(Attributes v)
            {
                Varyings o;
                VertexPositionInputs input = GetVertexPositionInputs(v.posOS);
                o.posWS = input.positionWS;
                o.posCS = input.positionCS;
                o.posNDC = input.positionNDC;
                o.ray = input.positionWS - _WorldSpaceCameraPos;
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float2 Screenuv = i.posNDC.xy / i.posNDC.w;
                //float3 ray = i.posWS - _WorldSpaceCameraPos;
                float2 uv = getProjectedObjectPos(Screenuv, i.ray).xz;
                //read the texture color at the uv coordinate
                half4 col = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);

                return col;
            }
            ENDHLSL
        }
    }
}
