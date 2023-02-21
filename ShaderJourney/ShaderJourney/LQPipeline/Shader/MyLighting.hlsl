#ifndef _PBR_LIGHTING_FILE_
#define _PBR_LIGHTING_FILE_



static float RCP_PI=rcp(3.141592654);


float4 SHCoefficients[9]=
{
    float4(0.302530,0.259531,0.235033,3.544921),
    float4 (-0.038835,-0.039388,-0.040695,0.000000),
    float4 (-0.026369, -0.012100,-0.012399,0.000000),
    float4(-0.151382, -0.137018, -0.128331,0.009399),
    float4(0.013492, 0.015854, 0.017712, 0.000000),
    float4(-0.003879,-0.008172,-0.007177, 0.000000),
    float4(0.031031,0.031704,0.035607,0.015537),
    float4(-0.021719,-0.028778, -0.028867, 0.000000),
    float4 (0.086761,0.078513, 0.072939,0.008920)
};




//l=0,m=0
float GetY00(float3 p)
{
    return 0.5*sqrt(RCP_PI);
}

//l=1,m=0
float GetY10(float3 p)
{
    return 0.5*sqrt(3*RCP_PI)*p.z;
}
//l=1,m=1
float GetY1p1(float3 p)
{
    return 0.5*sqrt(3*RCP_PI)*p.x;
}

//l=1,m=-1
float GetY1n1(float3 p)
{
    return 0.5*sqrt(3*RCP_PI)*p.y;
}

//l=2,m=0
float GetY20(float3 p)
{
    return 0.25*sqrt(5*RCP_PI)*(2*p.z*p.z-p.x*p.x-p.y*p.y);
}

//l=2,m=1
float GetY2n1(float3 p)
{
    return 0.5*sqrt(15*RCP_PI)*p.z*p.y;
}

//l=2,m=1
float GetY2p1(float3 p)
{
    return 0.5*sqrt(15*RCP_PI)*p.z*p.x;
}

//l=2,m=2
float GetY2p2(float3 p)
{
    return 0.25*sqrt(15*RCP_PI)*(p.x*p.x-p.y*p.y);
}

//l=2,m=-2
float GetY2n2(float3 p)
{
    return 0.5*sqrt(15*RCP_PI)*p.x*p.y;
}


half4 SampleSH9(half3 normalWS)
{
    float3 d=float3(normalWS.x,normalWS.z,normalWS.y);
    half4 color=
            SHCoefficients[0]*GetY00(d)+
            SHCoefficients[1]*GetY1n1(d)+
            SHCoefficients[2]*GetY10(d)+
            SHCoefficients[3]*GetY1p1(d)+
            SHCoefficients[4]*GetY2n2(d)+
            SHCoefficients[5]*GetY2n1(d)+
            SHCoefficients[6]*GetY20(d)+
            SHCoefficients[7]*GetY2p1(d)+
            SHCoefficients[8]*GetY2p2(d);

    return color;
}






#endif