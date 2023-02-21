Shader "Blur/BokehBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		half4 _GoldenRot;
		half4 _Params;


		TEXTURE2D(_MainTex);
		float4 _MainTex_ST;
		SAMPLER(sampler_MainTex);

		#define _Iteration _Params.y
		#define _Radius _Params.x
		#define _PixelSize _Params.zw


		struct a2v
		{
			float4 vertex:POSITION;
			float2 texcoord:TEXCOORD0;
		};

		struct v2f
		{
			float4 pos:POSITION;
			float2 uv:TEXCOORD0;

		};


		v2f vert(a2v v)
		{
			v2f o;
			o.pos = TransformObjectToHClip(v.vertex);
			o.uv.xy = v.texcoord.xy;
			return o;
		}


		half4 BokehBlur(v2f i)
		{
			half2x2 rot = half2x2(_GoldenRot);
			half4 accumulator = 0.0;
			half4 divisor = 0.0;

			half r = 1.0;
			half2 angle = half2(0.0, _Radius);

			for (int j = 0; j < _Iteration; j++)
			{
				r += 1.0 / r;
				angle = mul(rot, angle);
				half4 bokeh = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv + 1/_ScreenParams.xy * (r - 1.0) * angle));
				accumulator += bokeh;
				divisor++;
			}
			return accumulator/ _Iteration;
		}

		half4 Frag(v2f i) : SV_Target
		{
			return BokehBlur(i);
		}

		ENDHLSL

		SubShader
		{
			Cull Off ZWrite Off ZTest Always

			Pass
			{
				Tags{"RenderPipeline" = "UniversalPipeline"}
				
			HLSLPROGRAM

				#pragma vertex vert
				#pragma fragment Frag

			ENDHLSL

			}
		}
}

