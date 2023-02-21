using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
public class BokehBlurFeature : ScriptableRendererFeature
{
    BokehBlurPass bokehBlurPass;

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        bokehBlurPass.SetUp(renderer.cameraColorTarget);
        //把这个Pass扔进渲染队列
        renderer.EnqueuePass(bokehBlurPass);

    }

    public override void Create()
    {
        bokehBlurPass = new BokehBlurPass(RenderPassEvent.BeforeRenderingPostProcessing);
    }


    public class BokehBlurPass : ScriptableRenderPass
    {
        private readonly string Shader_Tag = "BokehBlur";
        private readonly int GoldRot = Shader.PropertyToID("_GoldenRot");
        private readonly int Params = Shader.PropertyToID("_Params");
        internal readonly int BufferRT1 = Shader.PropertyToID("_BufferRT1");
        private Vector4 GoldenRot=new Vector4();



        private BokehBlur Setting;


        private Material BokehBlurMaterial;
        private RenderTargetIdentifier TargetTxture;
        public BokehBlurPass(RenderPassEvent evt)
        {
            this.renderPassEvent = evt;
            Shader shader = Shader.Find("Blur/BokehBlur");
            if (shader==null)
            {

                Debug.LogError("未找到该Shader");
                return;
            }
            BokehBlurMaterial = CoreUtils.CreateEngineMaterial(shader);
        }


        public void SetUp(in RenderTargetIdentifier targetTexture)
        {

            this.TargetTxture = targetTexture;
            float c = Mathf.Cos(2.39996323f);
            float s = Mathf.Sin(2.39996323f);
            GoldenRot.Set(c, s, -s, c);
        }




        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (BokehBlurMaterial == null)
            {
                Debug.LogError("Material not created.");
                return;
            }
            if (!renderingData.cameraData.postProcessEnabled) return;

            //怎么拿到Setting
            var stack = VolumeManager.instance.stack;
            Setting = stack.GetComponent<BokehBlur>();
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

            int RTwidth = (int)(screenWidth / Setting.RTDownScaling.value);
            int RTheight = (int)(screenHeight / Setting.RTDownScaling.value);

            cmd.GetTemporaryRT(BufferRT1, RTwidth, RTheight, 0, FilterMode.Bilinear);
            cmd.Blit(source, BufferRT1);
            //模糊赋值
            BokehBlurMaterial.SetVector(Params, new Vector4(Setting.BlurRadius.value, Setting.Iteration.value, 1/screenWidth, 1/screenHeight));
            BokehBlurMaterial.SetVector(GoldRot, GoldenRot);
            cmd.Blit(BufferRT1, source, BokehBlurMaterial);




        }

    }
}
