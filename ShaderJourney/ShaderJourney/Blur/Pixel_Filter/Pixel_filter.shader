Shader "Blur/Pixel_filter"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _PixelSize("PixelSize",Range(1,100))=16
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float _PixelSize;


            half2 Calculateuv(half2 uv)
            {
                float2 DownSampleScreen = _ScreenParams.xy / _PixelSize;
                half2 res = floor((uv + half2(0.5, 0.5)) * DownSampleScreen) / DownSampleScreen - half2(0.5, 0.5);
                return res;
            }


            fixed4 frag (v2f i) : SV_Target
            {
               
                fixed4 col = tex2D(_MainTex, Calculateuv(i.uv));
                return col;
            }
            ENDCG
        }
    }
}
