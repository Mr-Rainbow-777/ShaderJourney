using UnityEngine.Rendering;
using UnityEngine;

public class BaseRP : RenderPipeline
{
    private CameraRender render = new CameraRender();
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        foreach (var camera in cameras)
        {
            render.Render(context, camera);
        }
    }
}
