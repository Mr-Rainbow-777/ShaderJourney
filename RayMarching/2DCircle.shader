Shader "Hidden/2DCircle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            #pragma target 5.0
            #include "UnityCG.cginc"
            #include  "DistanceFunctions.cginc"


            uniform float uvScale;
            uniform float3 Color;
            uniform float StepParam;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

            float2 random2(float2 p) {
                return frac(sin(float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)))) * 43758.5453);
            }

            float DistanceField(float2 p)
            {
                return sdCircle(p-fixed2(0.5,0.5), 0.4);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 st = i.uv.xy;
                float3 color = Color;

                // Scale
                st *= uvScale;

                // Tile the space
                float2 i_st = floor(st);
                float2 f_st = frac(st);

                float m_dist = 1.;  // minimum distance
                for (int j = -1; j <= 1; j++) {
                    for (int i = -1; i <= 1; i++) {
                        // Neighbor place in the grid
                        float2 neighbor = float2(float(i),float(j));

                        // Random position from current + neighbor place in the grid
                        float2 offset = random2(i_st + neighbor);

                        // Animate the offset
                        offset = 0.5 + 0.5 * sin(_Time.y + 6.2831 * offset);

                        // Position of the cell
                        float2 pos = neighbor + offset - f_st;

                        // Cell distance
                        float dist = length(pos);

                        // Metaball it!
                        m_dist = min(m_dist, m_dist * dist);
                        //总的来说就是拿到周围九个点的最短距离
                    }
                }

                // Draw cells
                color += step(0.060, m_dist);

                return fixed4(color, 1);
            }
            ENDCG
        }
    }
}
