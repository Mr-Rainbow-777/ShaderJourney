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


            // 顶点着色器的输入
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



            // 为了确定如何细分三角形，GPU使用了四个细分因子。三角形面片的每个边缘都有一个因数。
            // 三角形的内部也有一个因素。三个边缘向量必须作为具有SV_TessFactor语义的float数组传递。
            // 内部因素使用SV_InsideTessFactor语义
            struct TessellationFactors
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            // 该结构的其余部分与Attributes相同，只是使用INTERNALTESSPOS代替POSITION语意，否则编译器会报位置语义的重用
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


            //原顶点程序
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

                //输入修正法线
                #ifdef _NORMALMAP
                VertexNormalInputs normalInputs = GetVertexNormalInputs(float4(normal,1), float4(tangent,1));
                #else
                VertexNormalInputs normalInputs = GetVertexNormalInputs(float4(normal, 1));
                #endif
                //采用偏移坐标
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


            // 顶点着色器，此时只是将Attributes里的数据递交给曲面细分阶段
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

            // 随着距相机的距离减少细分数
            float CalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tess)
            {
                float3 worldPosition = TransformObjectToWorld(vertex.xyz);
                float dist = distance(worldPosition,  GetCameraPositionWS());
                float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
                return (f);
            }

            // Patch Constant Function决定Patch的属性是如何细分的。这意味着它每个Patch仅被调用一次，
            // 而不是每个控制点被调用一次。这就是为什么它被称为常量函数，在整个Patch中都是常量的原因。
            // 实际上，此功能是与HullProgram并行运行的子阶段。
            // 三角形面片的细分方式由其细分因子控制。我们在MyPatchConstantFunction中确定这些因素。
            // 当前，我们根据其距离相机的位置来设置细分因子
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

            //细分阶段非常灵活，可以处理三角形，四边形或等值线。我们必须告诉它必须使用什么表面并提供必要的数据。
            //这是 hull 程序的工作。Hull 程序在曲面补丁上运行，该曲面补丁作为参数传递给它。
            //我们必须添加一个InputPatch参数才能实现这一点。Patch是网格顶点的集合。必须指定顶点的数据格式。
            //现在，我们将使用ControlPoint结构。在处理三角形时，每个补丁将包含三个顶点。此数量必须指定为InputPatch的第二个模板参数
            //Hull程序的工作是将所需的顶点数据传递到细分阶段。尽管向其提供了整个补丁，
            //但该函数一次仅应输出一个顶点。补丁中的每个顶点都会调用一次它，并带有一个附加参数，
            //该参数指定应该使用哪个控制点（顶点）。该参数是具有SV_OutputControlPointID语义的无符号整数。
            [domain("tri")]//明确地告诉编译器正在处理三角形，其他选项：
            [outputcontrolpoints(3)]//明确地告诉编译器每个补丁输出三个控制点
            [outputtopology("triangle_cw")]//当GPU创建新三角形时，它需要知道我们是否要按顺时针或逆时针定义它们
            [partitioning("fractional_odd")]//告知GPU应该如何分割补丁，现在，仅使用整数模式
            [patchconstantfunc("MyPatchConstantFunction")]//GPU还必须知道应将补丁切成多少部分。这不是一个恒定值，每个补丁可能有所不同。必须提供一个评估此值的函数，称为补丁常数函数（Patch Constant Functions）
            ControlPoint HullProgram(InputPatch<ControlPoint, 3> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }


            //HUll着色器只是使曲面细分工作所需的一部分。一旦细分阶段确定了应如何细分补丁，
            //则由Domain着色器来评估结果并生成最终三角形的顶点。
            //Domain程序将获得使用的细分因子以及原始补丁的信息，原始补丁在这种情况下为OutputPatch类型。
            //细分阶段确定补丁的细分方式时，不会产生任何新的顶点。相反，它会为这些顶点提供重心坐标。
            //使用这些坐标来导出最终顶点取决于域着色器。为了使之成为可能，每个顶点都会调用一次域函数，并为其提供重心坐标。
            //它们具有SV_DomainLocation语义。
            //在Demain函数里面，我们必须生成最终的顶点数据。
            [domain("tri")]//Hull着色器和Domain着色器都作用于相同的域，即三角形。我们通过domain属性再次发出信号
            Varyings DomainProgram(TessellationFactors factors, OutputPatch<ControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
            {
                Attributes v;

                //为了找到该顶点的位置，我们必须使用重心坐标在原始三角形范围内进行插值。
                //X，Y和Z坐标确定第一，第二和第三控制点的权重。
                //以相同的方式插值所有顶点数据。让我们为此定义一个方便的宏，该宏可用于所有矢量大小。
                #define DomainInterpolate(fieldName) v.fieldName = \
                        patch[0].fieldName * barycentricCoordinates.x + \
                        patch[1].fieldName * barycentricCoordinates.y + \
                        patch[2].fieldName * barycentricCoordinates.z;

                    //对位置、颜色、UV、法线等进行插值
                    DomainInterpolate(vertex)
                    DomainInterpolate(uv)
                    DomainInterpolate(color)
                    DomainInterpolate(normal)
                    #ifdef _NORMALMAP
                    DomainInterpolate(Tangent)
                    #endif
                        //现在，我们有了一个新的顶点，该顶点将在此阶段之后发送到几何程序或插值器。
                        //但是这些程序需要Varyings数据，而不是Attributes。为了解决这个问题，
                        //我们让域着色器接管了原始顶点程序的职责。
                        //这是通过调用其中的AfterTessVertProgram（与其他任何函数一样）并返回其结果来完成的。
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