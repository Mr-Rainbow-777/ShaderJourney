using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
public class Pixel_FilterRenderFeature : ScriptableRendererFeature
{
    PixelFilterPass _PixelFilterPass;

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        _PixelFilterPass.SetUp(renderer.cameraColorTarget);
        //把这个Pass扔进渲染队列
        renderer.EnqueuePass(_PixelFilterPass);

    }

    public override void Create()
    {
        _PixelFilterPass = new PixelFilterPass(RenderPassEvent.BeforeRenderingPostProcessing);
    }


    public class PixelFilterPass : ScriptableRenderPass
    {
        private readonly string Shader_Tag = "_PixelFilter_Tag";
        private readonly int PixelSizeID = Shader.PropertyToID("_PixelSize");
        internal readonly int BufferRT1 = Shader.PropertyToID("_BufferRT1");



        private Pixel_Filter Setting;


        private Material PixelFilterMaterial;
        private RenderTargetIdentifier TargetTxture;
        public PixelFilterPass(RenderPassEvent evt)
        {
            this.renderPassEvent = evt;
            Shader shader = Shader.Find("Blur/Pixel_filter");
            if (shader == null)
            {

                Debug.LogError("未找到该Shader");
                return;
            }
            PixelFilterMaterial = CoreUtils.CreateEngineMaterial(shader);
        }


        public void SetUp(in RenderTargetIdentifier targetTexture)
        {
            this.TargetTxture = targetTexture;
        }




        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (PixelFilterMaterial == null)
            {
                Debug.LogError("Material not created.");
                return;
            }
            if (!renderingData.cameraData.postProcessEnabled) return;

            //怎么拿到Setting
            var stack = VolumeManager.instance.stack;
            Setting = stack.GetComponent<Pixel_Filter>();
            if (Setting == null) { return; }
            if (!Setting.IsActive()) { return; }

            var cmd = CommandBufferPool.Get(Shader_Tag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd); //把CommandBuffer放进后处理栈
            CommandBufferPool.Release(cmd); //释放资源
        }



        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var cameraData = renderingData.cameraData;
            var source = this.TargetTxture;

            int screenWidth = cameraData.camera.scaledPixelWidth;
            int screenHeight = cameraData.camera.scaledPixelHeight;

            cmd.GetTemporaryRT(BufferRT1, screenWidth, screenHeight, 0, FilterMode.Bilinear);
            cmd.Blit(source, BufferRT1);
            //模糊赋值
            PixelFilterMaterial.SetFloat(PixelSizeID,Setting.PixelSize.value);
            cmd.Blit(BufferRT1, source,PixelFilterMaterial);




        }
    }
}
