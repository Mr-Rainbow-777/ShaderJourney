using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;




[CreateAssetMenu(menuName ="PBRLearn/PipelineAsset")]
public class LQRPPinelineAsset : RenderPipelineAsset
{
    protected override RenderPipeline CreatePipeline()
    {
        return new BaseRP();
    }
}
