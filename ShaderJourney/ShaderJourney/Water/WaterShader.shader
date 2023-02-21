Shader "MyShader/URP/Water Shader"
{
    Properties
    {
        _Color("Color(RGB)",Color) = (1,1,1,1)
        _BaseMap("MainTex",2D) = "gary"{}
        [Toggle(_NORMALMAP)] _NormalMapToggle("Use Flow Map", Float) = 0
        _FlowMap("FlowMap",2D) = "White"{}
        _Tess("Tessellation", Range(1, 32)) = 20
        _MaxTessDistance("Max Tess Distance", Range(1, 32)) = 20
        _MinTessDistance("Min Tess Distance", Range(1, 32)) = 1
        _Specular("Specular",Range(0,1)) = 0.4
        _SmoothNess("SmoothNess",Range(0,1)) = 0.3
        _WaveA("Wave A (dir, steepness, wavelength)", Vector) = (1,0,0.5,10)
    }
        SubShader
        {
            Tags
            {
                "RenderPipeline" = "UniversalPipeline"
                "RenderType" = "Transparent"
                "Queue" = "Geometry"
            }

            Pass
            {
                Name "Pass"
                Tags
                {

                }

                // Render State
                Blend One Zero, One Zero
                ZTest LEqual
                ZWrite On

                HLSLPROGRAM

                #pragma require tessellation
                #pragma require geometry

                #pragma vertex BeforeTessVertProgram
                #pragma hull HullProgram
                #pragma domain DomainProgram
                #pragma fragment frag

                #pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x
                #pragma target 4.6

            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            //#include "Assets/LQPipeline/Shader/pbrSurface.hlsl"
            //#include "Assets/LQPipeline/Shader/PBRInput.hlsl"

            #pragma shader_feature_local _NORMALMAP


            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            float _Tess;
            float _MaxTessDistance;
            float _MinTessDistance;
            float4 _BaseMap_ST;
            float _Specular;
            float _SmoothNess;
            float4 _WaveA;
            CBUFFER_END
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_FlowMap);
            SAMPLER(sampler_FlowMap);
            #define PI 3.14159265


            // ������ɫ��������
            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                #ifdef _NORMALMAP
                    float4 Tangent  : TANGENT;
                #endif
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float3 posWS : TEXCOOED1;
                float3 posOS : TEXCOOED2;
                float4 posCS : SV_POSITION;
                float4 color		: COLOR;
                #ifdef _NORMALMAP
                         half4 normalWS					: TEXCOORD3;    // xyz: normal, w: viewDir.x
                         half4 tangentWS			    : TEXCOORD4;    // xyz: tangent, w: viewDir.y
                         half4 bitangentWS				: TEXCOORD5;    // xyz: bitangent, w: viewDir.z
                #else
                         half3 normalWS					: TEXCOORD3;
                #endif
                float3 viewDir : TEXCOORD6;

            };


            float3 GerstnerWave(
                float4 wave, float3 p, inout float3 tangent, inout float3 binormal
            ) {
                float steepness = wave.z;
                float wavelength = wave.w;
                float k = 2 * PI / wavelength;
                float c = sqrt(9.8 / k);
                float2 d = normalize(wave.xy);
                float f = k * (dot(d, p.xz) - c * _Time.y);
                float a = steepness / k;


                tangent += float3(
                    -d.x * d.x * (steepness * sin(f)),
                    d.x * (steepness * cos(f)),
                    -d.x * d.y * (steepness * sin(f))
                    );
                binormal += float3(
                    -d.x * d.y * (steepness * sin(f)),
                    d.y * (steepness * cos(f)),
                    -d.y * d.y * (steepness * sin(f))
                    );
                return float3(
                    d.x * (a * cos(f)),
                    a * sin(f),
                    d.y * (a * cos(f))
                    );
            }



            // Ϊ��ȷ�����ϸ�������Σ�GPUʹ�����ĸ�ϸ�����ӡ���������Ƭ��ÿ����Ե����һ��������
            // �����ε��ڲ�Ҳ��һ�����ء�������Ե����������Ϊ����SV_TessFactor�����float���鴫�ݡ�
            // �ڲ�����ʹ��SV_InsideTessFactor����
            struct TessellationFactors
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            // �ýṹ�����ಿ����Attributes��ͬ��ֻ��ʹ��INTERNALTESSPOS����POSITION���⣬����������ᱨλ�����������
            struct ControlPoint
            {
                float4 vertex : INTERNALTESSPOS;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                float3 normal : NORMAL;
                #ifdef _NORMALMAP
                    float4 Tangent  : TANGENT;
                #endif
            };


            //ԭ�������
            Varyings AfterTessVertProgram(Attributes v)
            {
                Varyings o;
                float3 p = v.vertex;
                float3 tangent = float3(1, 0, 0);
                float3 binormal = float3(0, 0, 1);
                p += GerstnerWave(_WaveA, v.vertex, tangent, binormal);
                float3 normal = normalize(cross(binormal, tangent));

                VertexPositionInputs input = GetVertexPositionInputs(p);
                o.posWS = input.positionWS;
                o.posCS = input.positionCS;
                o.posOS = p;

                //������������
                #ifdef _NORMALMAP
                VertexNormalInputs normalInputs = GetVertexNormalInputs(float4(normal,1), float4(tangent,1));
                #else
                VertexNormalInputs normalInputs = GetVertexNormalInputs(float4(normal, 1));
                #endif
                //����ƫ������
                half3 viewDirWS = GetWorldSpaceViewDir(p);

                #ifdef _NORMALMAP
                o.normalWS = half4(normalInputs.normalWS, viewDirWS.x);
                o.tangentWS = half4(normalInputs.tangentWS, viewDirWS.y);
                o.bitangentWS = half4(normalInputs.bitangentWS, viewDirWS.z);
                #else
                o.normalWS = NormalizeNormalPerVertex(normalInputs.normalWS);
                #endif
                o.viewDir = viewDirWS;
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.color = v.color;
                return o;
            }


            // ������ɫ������ʱֻ�ǽ�Attributes������ݵݽ�������ϸ�ֽ׶�
            ControlPoint BeforeTessVertProgram(Attributes v)
            {
                ControlPoint p;

                p.vertex = v.vertex;
                p.uv = v.uv;
                p.normal = v.normal;
                p.color = v.color;
                #ifdef _NORMALMAP
                p.Tangent = v.Tangent;
                #endif
                return p;
            }

            // ���ž�����ľ������ϸ����
            float CalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tess)
            {
                float3 worldPosition = TransformObjectToWorld(vertex.xyz);
                float dist = distance(worldPosition,  GetCameraPositionWS());
                float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
                return (f);
            }

            // Patch Constant Function����Patch�����������ϸ�ֵġ�����ζ����ÿ��Patch��������һ�Σ�
            // ������ÿ�����Ƶ㱻����һ�Ρ������Ϊʲô������Ϊ����������������Patch�ж��ǳ�����ԭ��
            // ʵ���ϣ��˹�������HullProgram�������е��ӽ׶Ρ�
            // ��������Ƭ��ϸ�ַ�ʽ����ϸ�����ӿ��ơ�������MyPatchConstantFunction��ȷ����Щ���ء�
            // ��ǰ�����Ǹ�������������λ��������ϸ������
            TessellationFactors MyPatchConstantFunction(InputPatch<ControlPoint, 3> patch)
            {
                float minDist = _MinTessDistance;
                float maxDist = _MaxTessDistance;

                TessellationFactors f;

                float edge0 = CalcDistanceTessFactor(patch[0].vertex, minDist, maxDist, _Tess);
                float edge1 = CalcDistanceTessFactor(patch[1].vertex, minDist, maxDist, _Tess);
                float edge2 = CalcDistanceTessFactor(patch[2].vertex, minDist, maxDist, _Tess);

                // make sure there are no gaps between different tessellated distances, by averaging the edges out.
                f.edge[0] = (edge1 + edge2) / 2;
                f.edge[1] = (edge2 + edge0) / 2;
                f.edge[2] = (edge0 + edge1) / 2;
                f.inside = (edge0 + edge1 + edge2) / 3;
                return f;
            }

            //ϸ�ֽ׶ηǳ������Դ��������Σ��ı��λ��ֵ�ߡ����Ǳ������������ʹ��ʲô���沢�ṩ��Ҫ�����ݡ�
            //���� hull ����Ĺ�����Hull ���������油�������У������油����Ϊ�������ݸ�����
            //���Ǳ������һ��InputPatch��������ʵ����һ�㡣Patch�����񶥵�ļ��ϡ�����ָ����������ݸ�ʽ��
            //���ڣ����ǽ�ʹ��ControlPoint�ṹ���ڴ���������ʱ��ÿ�������������������㡣����������ָ��ΪInputPatch�ĵڶ���ģ�����
            //Hull����Ĺ����ǽ�����Ķ������ݴ��ݵ�ϸ�ֽ׶Ρ����������ṩ������������
            //���ú���һ�ν�Ӧ���һ�����㡣�����е�ÿ�����㶼�����һ������������һ�����Ӳ�����
            //�ò���ָ��Ӧ��ʹ���ĸ����Ƶ㣨���㣩���ò����Ǿ���SV_OutputControlPointID������޷���������
            [domain("tri")]//��ȷ�ظ��߱��������ڴ��������Σ�����ѡ�
            [outputcontrolpoints(3)]//��ȷ�ظ��߱�����ÿ����������������Ƶ�
            [outputtopology("triangle_cw")]//��GPU������������ʱ������Ҫ֪�������Ƿ�Ҫ��˳ʱ�����ʱ�붨������
            [partitioning("fractional_odd")]//��֪GPUӦ����ηָ�������ڣ���ʹ������ģʽ
            [patchconstantfunc("MyPatchConstantFunction")]//GPU������֪��Ӧ�������гɶ��ٲ��֡��ⲻ��һ���㶨ֵ��ÿ����������������ͬ�������ṩһ��������ֵ�ĺ�������Ϊ��������������Patch Constant Functions��
            ControlPoint HullProgram(InputPatch<ControlPoint, 3> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }


            //HUll��ɫ��ֻ��ʹ����ϸ�ֹ��������һ���֡�һ��ϸ�ֽ׶�ȷ����Ӧ���ϸ�ֲ�����
            //����Domain��ɫ��������������������������εĶ��㡣
            //Domain���򽫻��ʹ�õ�ϸ�������Լ�ԭʼ��������Ϣ��ԭʼ���������������ΪOutputPatch���͡�
            //ϸ�ֽ׶�ȷ��������ϸ�ַ�ʽʱ����������κ��µĶ��㡣�෴������Ϊ��Щ�����ṩ�������ꡣ
            //ʹ����Щ�������������ն���ȡ��������ɫ����Ϊ��ʹ֮��Ϊ���ܣ�ÿ�����㶼�����һ����������Ϊ���ṩ�������ꡣ
            //���Ǿ���SV_DomainLocation���塣
            //��Demain�������棬���Ǳ����������յĶ������ݡ�
            [domain("tri")]//Hull��ɫ����Domain��ɫ������������ͬ���򣬼������Ρ�����ͨ��domain�����ٴη����ź�
            Varyings DomainProgram(TessellationFactors factors, OutputPatch<ControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
            {
                Attributes v;

                //Ϊ���ҵ��ö����λ�ã����Ǳ���ʹ������������ԭʼ�����η�Χ�ڽ��в�ֵ��
                //X��Y��Z����ȷ����һ���ڶ��͵������Ƶ��Ȩ�ء�
                //����ͬ�ķ�ʽ��ֵ���ж������ݡ�������Ϊ�˶���һ������ĺ꣬�ú����������ʸ����С��
                #define DomainInterpolate(fieldName) v.fieldName = \
                        patch[0].fieldName * barycentricCoordinates.x + \
                        patch[1].fieldName * barycentricCoordinates.y + \
                        patch[2].fieldName * barycentricCoordinates.z;

                    //��λ�á���ɫ��UV�����ߵȽ��в�ֵ
                    DomainInterpolate(vertex)
                    DomainInterpolate(uv)
                    DomainInterpolate(color)
                    DomainInterpolate(normal)
                    #ifdef _NORMALMAP
                    DomainInterpolate(Tangent)
                    #endif
                        //���ڣ���������һ���µĶ��㣬�ö��㽫�ڴ˽׶�֮���͵����γ�����ֵ����
                        //������Щ������ҪVaryings���ݣ�������Attributes��Ϊ�˽��������⣬
                        //����������ɫ���ӹ���ԭʼ��������ְ��
                        //����ͨ���������е�AfterTessVertProgram���������κκ���һ������������������ɵġ�
                        return AfterTessVertProgram(v);
            }


            half4 frag(Varyings i) : SV_Target
            {
                float4 ambident = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv);
                #ifdef _NORMALMAP
                half4 n = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, i.uv);
                float3 normalTS = UnpackNormal(n);
                float3 normalWS = mul(normalTS,half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz));
                #else
                float3 normalWS = i.normalWS.xyz;
                #endif

                Light mainLight = GetMainLight();
                half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);

                // Diffuse
                half3 shading = LightingLambert(attenuatedLightColor, mainLight.direction, normalWS);
                half4 DiffuseColor = ambident * _Color * i.color;

                //BlinnPhong
                half3 SpecularColor = LightingSpecular(mainLight.color, mainLight.direction, normalWS, i.viewDir, _Specular, _SmoothNess);
                return half4(DiffuseColor.rgb * shading+SpecularColor, DiffuseColor.a);

            }

            ENDHLSL
        }
        }
}