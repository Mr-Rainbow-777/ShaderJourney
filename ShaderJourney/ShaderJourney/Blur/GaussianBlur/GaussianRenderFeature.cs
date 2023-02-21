using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GaussianRenderFeature : ScriptableRendererFeature
{
    GaussianBlurPass gaussianPass;

    public override void Create()
    {
        gaussianPass = new GaussianBlurPass(RenderPassEvent.BeforeRenderingPostProcessing);

    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        gaussianPass.Setup(renderer.cameraColorTarget);
        //�����Pass�ӽ���Ⱦ����
        renderer.EnqueuePass(gaussianPass);
        
    }





    class GaussianBlurPass : ScriptableRenderPass
    {
        //�õ�������Ҫ���䵽Shader������
        static readonly string k_RenderTag = "Render GaussianBlur Effects";
        static readonly int MainTexId = Shader.PropertyToID("_MainTex");
        internal static readonly int BlurRadius = Shader.PropertyToID("_BlurOffset");
        internal static readonly int BufferRT1 = Shader.PropertyToID("_BufferRT1");
        internal static readonly int BufferRT2 = Shader.PropertyToID("_BufferRT2");

        GaussianBlur Setting;
        Material gaussianBlurMaterial;
        RenderTargetIdentifier currentTarget;

        public GaussianBlurPass(RenderPassEvent evt)
        {
            renderPassEvent = evt;
            var shader = Shader.Find("Blur/GaussianBlur"); //������ԸĽ�
            if (shader == null)
            {
                Debug.LogError("Shader not found.");
                return;
            }
            gaussianBlurMaterial = CoreUtils.CreateEngineMaterial(shader); //����Material
        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (gaussianBlurMaterial == null)
            {
                Debug.LogError("Material not created.");
                return;
            }

            if (!renderingData.cameraData.postProcessEnabled) return;

            //��ô�õ�Setting
            var stack = VolumeManager.instance.stack;
            Setting = stack.GetComponent<GaussianBlur>();
            if (Setting == null) { return; }
            if (!Setting.IsActive()) { return; }
            var cmd = CommandBufferPool.Get(k_RenderTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd); //��CommandBuffer�Ž�����ջ
            CommandBufferPool.Release(cmd); //�ͷ���Դ
        }

        public void Setup(in RenderTargetIdentifier currentTarget)
        {
            this.currentTarget = currentTarget;
        }

        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var cameraData=renderingData.cameraData;
            var source=this.currentTarget;

            int screenWidth = cameraData.camera.scaledPixelWidth;
            int screenHeight = cameraData.camera.scaledPixelHeight;

            int RTwidth = (int)(screenWidth / Setting.RTDownScaling.value);
            int RTheight = (int)(screenHeight / Setting.RTDownScaling.value);
            cmd.GetTemporaryRT(BufferRT1, RTwidth, RTheight, 0, FilterMode.Bilinear);
            cmd.GetTemporaryRT(BufferRT2, RTwidth, RTheight, 0, FilterMode.Bilinear);
            cmd.SetGlobalTexture(MainTexId, source);
            cmd.Blit(source, BufferRT1);

            //����
            for (int i = 0; i < Setting.Iteration.value; i++)
            {
                // horizontal blur
                gaussianBlurMaterial.SetVector(BlurRadius, new Vector4(Setting.BlurRadius.value / screenWidth, 0, Setting.BlurRadius.value / screenWidth, 0));
                cmd.Blit(BufferRT1, BufferRT2, gaussianBlurMaterial);

                // vertical blur
                gaussianBlurMaterial.SetVector(BlurRadius, new Vector4(0,Setting.BlurRadius.value / screenWidth,0, Setting.BlurRadius.value));
                cmd.Blit(BufferRT2, BufferRT1, gaussianBlurMaterial);
            }

            cmd.Blit(BufferRT1, source);



        }

    }
}


