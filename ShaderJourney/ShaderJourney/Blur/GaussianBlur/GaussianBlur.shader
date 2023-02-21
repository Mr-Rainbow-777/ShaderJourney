Shader "Blur/GaussianBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    
    half4 _BlurOffset;
	float4 _MainTex_ST;
	TEXTURE2D(_MainTex);
	SAMPLER(sampler_MainTex);


    struct a2v
    {
        float4 vertex:POSITION;
        float2 texcoord:TEXCOORD0;
    };
    
    struct v2f
    {
        float4 pos:POSITION;
        float2 uv:TEXCOORD0;
        float4 uv01:TEXCOORD1;
        float4 uv23:TEXCOORD2;
        float4 uv45:TEXCOORD3;

    };


    v2f vertGaussianBlur(a2v v)
    {
        v2f o;
        o.pos = TransformObjectToHClip(v.vertex);
        o.uv.xy = v.texcoord.xy;
        //存6个向外扩散的坐标

        o.uv01=o.uv.xyxy+_BlurOffset.xyxy*float4(1,1,-1,-1);
        o.uv23=o.uv.xyxy+_BlurOffset.xyxy*float4(1,1,-1,-1)*2.0;
        o.uv45=o.uv.xyxy+_BlurOffset.xyxy*float4(1,1,-1,-1)*3.0;

        return o;
    }



    float4 FragGaussianBlur(v2f i):SV_Target
    {
        half4 color=float4(0,0,0,0);

        color+=0.40*SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
        color+=0.15*SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv01.xy);
        color+=0.15*SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv01.zw);
        color+=0.10*SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv23.xy);
        color+=0.10*SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv23.zw);
        color+=0.05*SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv45.xy);
        color+=0.05*SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv45.zw);

        return color;
    }


    ENDHLSL



	SubShader
	{        
        Cull Off ZWrite Off ZTest Always
        Tags
	    {
		    //转到URP后，所有的sub tag中都要像下面这样指定URP渲染
		    "RenderPipeline" = "UniversalPipeline"
	    }

        pass
        {
            HLSLPROGRAM

            #pragma vertex vertGaussianBlur
            #pragma fragment FragGaussianBlur

            ENDHLSL
            
        }
    }
}
