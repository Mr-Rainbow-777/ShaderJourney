Shader "MyShader/ParallaxMapping"
{
    Properties
    {
            _MainTex("Diffuse map (RGB)", 2D) = "white" {}
			[Toggle(_NORMAL_MAP)] _NormalMapToggle ("Normal Map", Float) = 0
			_NormalMap("Normal map (RGB)", 2D) = "bump" {}
            _HeightMap("Height map (G)", 2D) = "white" {}
            _BumpScale("Bump scale", Range(0,1)) = 0.5
            _Parallax("Height scale", Range(0.005, 0.1)) = 0.08
            _ParallaxSamples("Parallax samples", Range(10, 100)) = 40
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }


		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			#include "AutoLight.cginc"
			#include "UnityCG.cginc"
			#include "UnityPBSLighting.cginc"
			sampler2D _MainTex;
			sampler2D _NormalMap;
			#pragma shader_feature _NORMAL_MAP

			sampler2D _HeightMap;
			float _Parallax;
			float _ParallaxSamples;

			float _BumpScale;
  			#define PARALLAX_RAYMARCHING_SEARCH_STEPS 3
			#define PARALLAX_RAYMARCHING_STEPS 10
			struct vertexInput
			{
				float4 vertex: POSITION;
				float3 normal: NORMAL;
				float2 texcoord: TEXCOORD0;
				float4 tangent  : TANGENT;
			};

			struct vertexOutput
			{
				float4 pos: SV_POSITION;
				float4 uv: TEXCOORD0;
				float4 posWorld: TEXCOORD1;
				float3 tSpace0 : TEXCOORD2;
				float3 tSpace1 : TEXCOORD3;
				float3 tSpace2 : TEXCOORD4;
				float3 normal  : TEXCOORD5;
				float4 tangent  : TEXCOORD6;
				float3 tangentViewDir  : TEXCOORD7;


			};

			float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
				return cross(normal, tangent.xyz) *
					(binormalSign * unity_WorldTransformParams.w);
			}

			float3 GetTangentSpaceNormal (vertexOutput i) {
				float3 normal = float3(0, 0, 1);
				normal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);			
				return normal;
			}

			void InitializeFragmentNormal(inout vertexOutput i) {
				float3 tangentSpaceNormal = GetTangentSpaceNormal(i);
				float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);			
				i.normal = normalize(
					tangentSpaceNormal.x * i.tangent +
					tangentSpaceNormal.y * binormal +
					tangentSpaceNormal.z * i.normal
				);
			}

			float GetParallaxHeight (float2 uv) {
				return tex2D(_HeightMap, uv).g;
			}

			float2 ParallaxOffset (float2 uv, float2 viewDir) {
				float height = GetParallaxHeight(uv);
				height -= 0.5;
				height *= _Parallax;
				return viewDir * height;
			}
				



			float2 ParallaxRaymarching (float2 uv, float2 viewDir) {
				#if !defined(PARALLAX_RAYMARCHING_STEPS)
						#define PARALLAX_RAYMARCHING_STEPS 30
					#endif
					float2 uvOffset = 0;
					float stepSize = 1.0 / PARALLAX_RAYMARCHING_STEPS;
					float2 uvDelta = viewDir * (stepSize * _Parallax);

					float stepHeight = 1;
					float surfaceHeight = GetParallaxHeight(uv);

					float2 prevUVOffset = uvOffset;
					float prevStepHeight = stepHeight;
					float prevSurfaceHeight = surfaceHeight;

					for (
						int i = 1;
						i < PARALLAX_RAYMARCHING_STEPS && stepHeight > surfaceHeight;
						i++
					) {
						prevUVOffset = uvOffset;
						prevStepHeight = stepHeight;
						prevSurfaceHeight = surfaceHeight;
						
						uvOffset -= uvDelta;
						stepHeight -= stepSize;
						surfaceHeight = GetParallaxHeight(uv + uvOffset);
					}

					#if !defined(PARALLAX_RAYMARCHING_SEARCH_STEPS)
						#define PARALLAX_RAYMARCHING_SEARCH_STEPS 0
					#endif
					#if PARALLAX_RAYMARCHING_SEARCH_STEPS > 0
						for (int i = 0; i < PARALLAX_RAYMARCHING_SEARCH_STEPS; i++) {
							uvDelta *= 0.5;
							stepSize *= 0.5;

							if (stepHeight < surfaceHeight) {
								uvOffset += uvDelta;
								stepHeight += stepSize;
							}
							else {
								uvOffset -= uvDelta;
								stepHeight -= stepSize;
							}
							surfaceHeight = GetParallaxHeight(uv + uvOffset);
						}
					#elif defined(PARALLAX_RAYMARCHING_INTERPOLATE)
						float prevDifference = prevStepHeight - prevSurfaceHeight;
						float difference = surfaceHeight - stepHeight;
						float t = prevDifference / (prevDifference + difference);
						uvOffset = prevUVOffset - uvDelta * t;
					#endif

					return uvOffset;
			}


			void ApplyParallax(inout vertexOutput i) {
				i.tangentViewDir = normalize(i.tangentViewDir);
				#if !defined(PARALLAX_OFFSET_LIMITING)
					#if !defined(PARALLAX_BIAS)
						#define PARALLAX_BIAS 0.42
					#endif
				i.tangentViewDir.xy /= (i.tangentViewDir.z + PARALLAX_BIAS);
				#endif
				float2 uvOffset = ParallaxRaymarching(i.uv.xy, i.tangentViewDir.xy);
				i.uv.xy += uvOffset;
				//i.uv.zw += uvOffset * (_DetailTex_ST.xy / _MainTex_ST.xy);
			}

			vertexOutput vertex_shader(vertexInput v)
			{
				vertexOutput o;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				//�õ�TBN����
				fixed3 worldNormal = mul(v.normal.xyz, (float3x3)unity_WorldToObject);
				fixed3 worldTangent = normalize(mul((float3x3)unity_ObjectToWorld,v.tangent.xyz));
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
				o.tSpace0 = float3(worldTangent.x, worldBinormal.x, worldNormal.x);
				o.tSpace1 = float3(worldTangent.y, worldBinormal.y, worldNormal.y);
				o.tSpace2 = float3(worldTangent.z, worldBinormal.z, worldNormal.z);

				o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.texcoord;
				o.normal = v.normal;
				return o;
			}

			float4 pixel_shader(vertexOutput i) : SV_TARGET
			{	

				fixed3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);

				fixed3 viewDir = i.tSpace0.xyz * worldViewDir.x + i.tSpace1.xyz * worldViewDir.y + i.tSpace2.xyz * worldViewDir.z;
				i.tangentViewDir=viewDir;

				ApplyParallax(i);
				InitializeFragmentNormal(i);		






				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 diffuseReflection =  saturate(dot(i.normal, lightDirection));
				float3 color = diffuseReflection + UNITY_LIGHTMODEL_AMBIENT.rgb;
				float4 tex = tex2D(_MainTex, i.uv.xy);
				return float4(tex.xyz * color , 1.0);
			}
			ENDCG
		}
			}
}