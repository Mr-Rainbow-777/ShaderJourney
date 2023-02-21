Shader "Effects/Bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    CGINCLUDE

    #include "UnityCG.cginc"
    float _luminanceThreshold;
    sampler2D _MainTex;
    half4 _MainTex_TexelSize;
    sampler2D _BloomTex;
    float _BlurSize;

    struct a2v
    {
        float4 vertex:POSITION;
        float2 texcoord:TEXCOORD0;
    };

    struct v2f
    {
        float4 pos:SV_POSITION;
        float2 uv:TEXCOORD0;

    };

    v2f vertExtractBright(appdata_img v)
    {
        v2f o;
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv = v.texcoord;
        return o;
    }

    float luminace(fixed4 color)
    {
        return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
    }

    fixed4 fragExtractBright(v2f i) : SV_Target{
        fixed4 color = tex2D(_MainTex, i.uv);
        fixed val = clamp(luminace(color) - _luminanceThreshold,0.0, 1.0);
        return color * val;
    } 

struct v2fGaussian{
    float4 pos: SV_POSITION;
    half2 uv[5]: TEXCOORD0;
};

v2fGaussian vertBlurVertical(a2v v)
{
    v2fGaussian o;
    o.pos = UnityObjectToClipPos(v.vertex);
    half2 uv = v.texcoord;

    o.uv[0]=uv;
    o.uv[1]=uv+float2(0.0, _MainTex_TexelSize.y*1.0)*_BlurSize;
    o.uv[2]=uv-float2(0.0, _MainTex_TexelSize.y*1.0)*_BlurSize;
    o.uv[3]=uv+float2(0.0, _MainTex_TexelSize.y*2.0)*_BlurSize;
    o.uv[4]=uv-float2(0.0, _MainTex_TexelSize.y*2.0)*_BlurSize;

    return o;
}
v2fGaussian vertBlurHorizontal(a2v v)
{
    v2fGaussian o;
    o.pos = UnityObjectToClipPos(v.vertex);
    half2 uv = v.texcoord;
    o.uv[0]=uv;
    o.uv[1]=uv+float2(_MainTex_TexelSize.x*1.0, 0.0)*_BlurSize;
    o.uv[2]=uv-float2(_MainTex_TexelSize.x*1.0, 0.0)*_BlurSize;
    o.uv[3]=uv+float2(_MainTex_TexelSize.x*2.0, 0.0)*_BlurSize;
    o.uv[4]=uv-float2(_MainTex_TexelSize.x*2.0, 0.0)*_BlurSize;

    return o;
}

fixed4 fragBlur(v2fGaussian i):SV_Target{

    float weight[3]={0.4026, 0.2442, 0.0545};
    fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];

    for(int it=1; it<3; it++)
    {
        sum+=tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
        sum+=tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
    }
    return fixed4(sum, 1.0);
} 

struct v2fBloom
{
    float4 pos:SV_POSITION;
    half4 uv:TEXCOORD0;
};


v2fBloom vertBloom(appdata_img v){
    v2fBloom o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv.xy = v.texcoord;
    o.uv.zw = v.texcoord;

    #if UNITY_UV_STARTS_AT_TOP
    if(_MainTex_TexelSize.y<0)
    {
        o.uv.w = 1.0 - o.uv.w;
    }
    #endif
    return o;
}

fixed4 fragBloom(v2fBloom i):SV_Target
{
    fixed4 color = tex2D(_MainTex,i.uv.xy)+tex2D(_BloomTex,i.uv.zw);
    return color;
} 



    ENDCG

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        pass
        {
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright
            ENDCG
        }
        pass
        {
            CGPROGRAM
            #pragma vertex vertBlurVertical
            #pragma fragment fragBlur
            ENDCG
        }
        pass
        {
            CGPROGRAM
            #pragma vertex vertBlurHorizontal
            #pragma fragment fragBlur
            ENDCG
        }
        pass
        {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            ENDCG
        }
    }
}
