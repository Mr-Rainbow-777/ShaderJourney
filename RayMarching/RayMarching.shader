Shader "Ray/RayMarching"
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
            #include "DistanceFunctions.cginc"

            sampler2D _MainTex;
            uniform sampler2D _CameraDepthTexture;
            uniform float4x4 _camfrustum;
            uniform float4x4 _camToWorld;
            uniform float max_Distance;
            uniform float3 lightDir, _LightCol;
            uniform float4 _ShadingColor;
            uniform float4 _sphere1;
            uniform float4 _sphere2;
            uniform float4 _cube;

            uniform float _LightIntensity;
            uniform float _boxround;
            uniform float box_sphere_smooth;
            uniform float _sphereIntersectSmooth;

            //shadow
            uniform float2 _ShadowDistance;
            uniform float _ShdowIntensity;
            uniform float _ShadowPenumbra;

            
            uniform int MaxIteration;
            uniform float Accuracy;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray:TEXCOORD1;
            };



            float SphereBox(float3 p)
            {
                float sphere1 = sdSphere(p - _sphere1.xyz, _sphere1.w);
                float box = sdRoundBox(p - _cube.xyz, _cube.www, _boxround);
                float combine1 = opSS(sphere1, box, box_sphere_smooth);

                float sphere2 = sdSphere(p - _sphere2.xyz, _sphere2.w);
                float combine = opIS(sphere2, combine1, _sphereIntersectSmooth);

                return combine;
            }


            float DistanceField(float3 p)
            {
                float plane = sdPlane(p, float3(0, 1, 0), -0.1);
                float combine = SphereBox(p);
                return opUS(plane, combine,0.2);
            }

            float3 getNormal(float3 p)
            {
                const float2 offset = float2(0.001, 0.0);
                float3 normal = float3(
                    DistanceField(p + offset.xyy) - DistanceField(p - offset.xyy),
                    DistanceField(p + offset.yxy) - DistanceField(p - offset.yxy),
                    DistanceField(p + offset.yyx) - DistanceField(p - offset.yyx)
                    );
                return normalize(normal);
            }

            float hardshadow(float3 ro,float3 rd,float mint,float maxt)
            {
                for (float t = mint; t < maxt;)
                {
                    float h = DistanceField(ro + rd * t);
                    if (h < 0.001)
                    {
                        return 0.0;
                    }
                    t += h;
                }
                return 1.0;
            }

            float softshadow(float3 ro, float3 rd, float mint, float maxt,float k)
            {
                float result = 1.0;
                for (float t = mint; t < maxt;)
                {
                    float h = DistanceField(ro + rd * t);
                    if (h < 0.001)
                    {
                        return 0.0;
                    }
                    result = min(result, k * h / t);
                    t += h;
                }
                return result;
            }

            //AO
            uniform float AOstepSize;
            uniform int AOIteration;
            uniform float AOIntensity;

            float AmbientOcclusion(float3 p, float3 n)
            {
                float step = AOstepSize;
                float ao = 0.0;
                float dist=0;
                for (int i = 1; i < AOIteration; i++)
                {
                    dist = step * i;
                    ao += max(0, (dist-DistanceField(p+n*dist))/dist);
                }
                return (1.0 - ao * AOIntensity);
            }


            float3 Shading(float3 p,float3 normal)
            {
                float3 result;

                //Diffuse
                float3 color = _ShadingColor.xyz;
                //Directional Light
                float3 light = (_LightCol*dot(-lightDir, normal) * 0.5 + 0.5 )*_LightIntensity;
                //shadows
                float shadow = softshadow(p, -lightDir, _ShadowDistance.x, _ShadowDistance.y,_ShadowPenumbra)*0.5+0.5;
                shadow = max(0,pow(shadow, _ShdowIntensity));
                //AO
                float ao = AmbientOcclusion(p, normal);

                result = light* shadow*color*ao;


                return result;
            }


            fixed4 rayMarching(float3 origin,float3 dir,float depth)
            {
                fixed4 result = fixed4(1, 1, 1, 1);
                const int max_iteration = MaxIteration;
                float t = 0;  //经过的总距离
                for (int i = 0; i < max_iteration; i++)
                {
                    if (t > max_Distance||t>=depth)
                    {
                        result = fixed4(1,1,1,0);
                        break;
                    }
                    float3 p = origin + dir * t;

                    float d = DistanceField(p);
                    if (d < Accuracy)//hit
                    {
                        //shading
                        float3 normal = getNormal(p);
                        float3 s = Shading(p, normal);
                        result = fixed4(s,1);

                        break;
                    }
                    t += d;
                }
                return result;
            }


            v2f vert (appdata v)
            {
                v2f o;
                half index = v.vertex.z;
                o.ray = _camfrustum[(int)index].xyz;
                //z方向的归一化   ABS确保归一化正确
                o.ray /= abs(o.ray.z);
                o.ray = mul(_camToWorld, o.ray);
                v.vertex.z = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }



            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 col = tex2D(_MainTex,i.uv);
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv));
                depth *= length(i.ray);
                float3 rayDir = normalize(i.ray);
                float3 RayOrigin = _WorldSpaceCameraPos;
                fixed4 result = rayMarching(RayOrigin, rayDir,depth);
                return fixed4(col * (1 - result.w) + result.xyz * result.w , 1.0);
            }
            ENDCG
        }
    }
}
