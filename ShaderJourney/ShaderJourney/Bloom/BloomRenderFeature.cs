using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine;
using System;

public class BloomRenderFeature : ScriptableRendererFeature
{
    BloomPass bloomPass;

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var source = renderer.cameraColorTarget;
        bloomPass.SetUp(source);
        renderer.EnqueuePass(bloomPass);
    }

    public override void Create()
    {
        bloomPass = new BloomPass(RenderPassEvent.BeforeRenderingPostProcessing);
    }

    class BloomPass : ScriptableRenderPass
    {
        //拿到所有需要传输到Shader的数据
        static readonly string k_RenderTag = "Render Bloom Effects";
        static readonly int MainTexId = Shader.PropertyToID("_MainTex");
        static readonly int BloomId = Shader.PropertyToID("_BloomTex");

        internal static readonly int BlurSize = Shader.PropertyToID("_BlurSize");

        internal static readonly int luminanceThreshold = Shader.PropertyToID("_luminanceThreshold");
        internal static readonly int Original = Shader.PropertyToID("Original");
        internal static readonly int BufferRT1 = Shader.PropertyToID("_BufferRT1");
        internal static readonly int BufferRT2 = Shader.PropertyToID("_BufferRT2");

        BloomSetting Setting;
        Material BloomMaterial;
        RenderTargetIdentifier currentTarget;

        public BloomPass(RenderPassEvent evt)
        {
            renderPassEvent = evt;
            var shader = Shader.Find("Effects/Bloom"); //这个可以改进
            if (shader == null)
            {
                Debug.LogError("Shader not found.");
                return;
            }
            BloomMaterial = CoreUtils.CreateEngineMaterial(shader); //设置Material
        }


        public void SetUp(in RenderTargetIdentifier source)
        {
            this.currentTarget = source;
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (BloomMaterial == null)
            {
                Debug.LogError("Material not created.");
                return;
            }

            if (!renderingData.cameraData.postProcessEnabled) return;

            //怎么拿到Setting
            var stack = VolumeManager.instance.stack;
            Setting = stack.GetComponent<BloomSetting>();
            if (Setting == null) { return; }
            if (!Setting.IsActive()) { return; }

            var cmd = CommandBufferPool.Get(k_RenderTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd); //把CommandBuffer放进后处理栈
            CommandBufferPool.Release(cmd); //释放资源
        }

        private void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            //拿到相机的Data
            var cameraData = renderingData.cameraData;
            var source = this.currentTarget;

            int screenWidth = cameraData.camera.scaledPixelWidth;
            int screenHeight = cameraData.camera.scaledPixelHeight;

            int RTwidth = (int)(screenWidth / Setting.RTDownScaling.value);
            int RTheight = (int)(screenHeight / Setting.RTDownScaling.value);

            cmd.GetTemporaryRT(BufferRT1, RTwidth, RTheight, 0, FilterMode.Bilinear);
            cmd.GetTemporaryRT(BufferRT2, RTwidth, RTheight, 0, FilterMode.Bilinear);
            cmd.GetTemporaryRT(Original, screenWidth, screenHeight, 0, FilterMode.Bilinear);

            cmd.SetGlobalTexture(MainTexId, source);
            BloomMaterial.SetFloat(luminanceThreshold, Setting.luminanceThreshold.value);
             cmd.Blit(source, BufferRT1,BloomMaterial,0);
             cmd.Blit(source, Original);
            BloomMaterial.SetFloat(BlurSize, Setting.BlurSize.value);
            //迭代
            for (int i = 0; i < Setting.Iteration.value; i++)
            {
                // horizontal blur            
                cmd.Blit(BufferRT1, BufferRT2, BloomMaterial, 1);
                // vertical blur
                cmd.Blit(BufferRT2, BufferRT1, BloomMaterial, 2);
            }
            cmd.SetGlobalTexture(BloomId, BufferRT1);
            cmd.Blit(Original, source, BloomMaterial, 3);
        }
    }

}
