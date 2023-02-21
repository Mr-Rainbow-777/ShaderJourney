#ifndef _CUSTOM_BRDF_FILE_
#define _CUSTOM_BRDF_FILE_


#define kDieletricSpec half4(0.04,0.04,0.04,1.0-0.04)  //TOD 
#define INV_PI 0.3183098916   //1/PI   尽量避免除法


struct MyBRDFData
{
    half perceptualRoughness;    //感性粗糙度
    half metallic;               //金属度
    half3 albedo;                //反照率
    half roughness;              //粗糙度=perceptualRoughness^2
    half roughness2;             //roughness^2
    half f0;                     //菲涅尔项f0
};


half PerceputalRoughness2Roughness(half perceptualRoughness)
{
    return perceptualRoughness*perceptualRoughness;
}

//初始化BRDF数据
void InitializeBRDFData(half3 albedo,half metallic, half roughness,out MyBRDFData _BRDFData)
{
    _BRDFData.perceptualRoughness = roughness;
    _BRDFData.metallic=metallic;
    _BRDFData.albedo=albedo;
    _BRDFData.roughness=PerceputalRoughness2Roughness(roughness);
    _BRDFData.roughness2=_BRDFData.roughness*_BRDFData.roughness;
    _BRDFData.f0=lerp(kDieletricSpec.rgb,albedo,metallic);
    
}


//利用法线分布函数得到D项
half DistributionTerm(half NoH,half roughness)
{
    half a2=roughness*roughness;
    half nh2=NoH*NoH;
    half d=nh2*(a2-1)+1.00001f;
    return a2*INV_PI/(d*d);
}

//几何遮蔽，采用UE的方案Schlick-GGX
half GeometryTerm(half roughness,half NoL,half NoV)
{
    half k=pow(roughness+1,2)/8;
    half G1=NoL/lerp(NoL,1,k);
    half G2=NoV/lerp(NoV,1,k);
    half G=G1+G2;
    return G;
}

//菲涅尔项使用Schlick
half3 FresnelTerm(half3 f0,half VoH)
{
    return f0+(1-f0)*pow(1-VoH,5);
}

//IBL漫反射部分使用的F项
half3 FresnelTerm_Roughness(half3 f0,half VoH,half roughness)
{
    return f0+(max(1-roughness,f0)-f0)*pow(1-VoH,5);
}

//直接计算BRDF直接光部分（漫反射+镜面反射）
half3 DirectBRDF(MyBRDFData _BRDFData,half3 normalWS,half3 LightDirectionWS,half3 viewWS)
{
    half3 halfDir=normalize(LightDirectionWS+viewWS);
    half NoH=max(saturate(dot(normalWS,halfDir)),0.000001);
    half LoH=max(saturate(dot(LightDirectionWS,halfDir)),0.000001);
    half NoL=max(saturate(dot(normalWS,LightDirectionWS)),0.01);
    half NoV=max(saturate(dot(normalWS,viewWS)),0.01);
    half VoH=max(saturate(dot(viewWS,halfDir)),0.000001);   

    half D=DistributionTerm(NoH,_BRDFData.roughness);
    half G=GeometryTerm(_BRDFData.roughness,NoL,NoV);
    half3 F=FresnelTerm(_BRDFData.f0,VoH);

    //qustion？？？  为什么会出现漏光   需要调整NoL和NoV的具体数值
    half3 speculaerTerm=(D*G*F)/(4*NoL*NoV);
    half3 ks=F;
    half3 kd=(1-ks)*(1-_BRDFData.metallic);  //乘上1-metallic是因为金属不产生任何漫反射

    return kd*INV_PI*_BRDFData.albedo+speculaerTerm*ks;


}

//间接光镜面反射BRDF部分
half3 BRDFIBLSpec(MyBRDFData _BRDFData,float2 scaleBias)
{
    return _BRDFData.f0*scaleBias.x+scaleBias.y;
}


#endif