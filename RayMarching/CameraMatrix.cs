using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class CameraMatrix : SceneViewFilter
{
    private Camera camera;
    private Camera m_Camera
    {
        get { if (camera == null)
            {
                camera = GetComponent<Camera>();
            }
        return camera;
         }
        set { m_Camera = value; }
    }
    [SerializeField]
    private Shader _shader;
    private Material _Material;
    public Material _RaymarchingMat
    {
        get
        {
            if(_Material == null)
            {
                _Material = new Material(_shader);
                _Material.hideFlags = HideFlags.HideAndDontSave;
            }
            return _Material;
        }
        private set
        {
            _Material = value;
        }
    }

    [SerializeField]
    private float Max_Distance;
    [SerializeField]
    private Transform LightPos;
    [SerializeField]
    private Vector4 _sphere1;
    [SerializeField]
    private Vector4 _sphere2;
    [SerializeField]
    private Vector4 cube;
    [SerializeField]
    private float _boxround;
    [SerializeField]
    private float box_sphere_smooth;
    [SerializeField]
    private float _sphereIntersectSmooth;
    [SerializeField]
    private Color32 _color;
    [SerializeField]
    private Light light;
    [SerializeField]
    private float _ShdowIntensity;
    [SerializeField]
    private Vector2 _ShadowDistance;
    [SerializeField]
    private float _ShadowPenumbra;

    [SerializeField]
    private int MaxIteration=256;
    [SerializeField]
    private float Accuracy=0.1f;


    [Header("AO")]
    [Range(0,10)]
    public float AOstepSize;
    [Range(0,10)]
    public int AOIteration;
    [Range(0, 0.5f)]
    public float AOIntensity;


    float[] p=new float[512];

    //noise
    float[] permutation = {
    151, 160, 137,  91,  90,  15, 131,  13, 201,  95,  96,  53, 194, 233,   7, 225,
    140,  36, 103,  30,  69, 142,   8,  99,  37, 240,  21,  10,  23, 190,   6, 148,
    247, 120, 234,  75,   0,  26, 197,  62,  94, 252, 219, 203, 117,  35,  11,  32,
     57, 177,  33,  88, 237, 149,  56,  87, 174,  20, 125, 136, 171, 168,  68, 175,
     74, 165,  71, 134, 139,  48,  27, 166,  77, 146, 158, 231,  83, 111, 229, 122,
     60, 211, 133, 230, 220, 105,  92,  41,  55,  46, 245,  40, 244, 102, 143,  54,
     65,  25,  63, 161,   1, 216,  80,  73, 209,  76, 132, 187, 208,  89,  18, 169,
    200, 196, 135, 130, 116, 188, 159,  86, 164, 100, 109, 198, 173, 186,   3,  64,
     52, 217, 226, 250, 124, 123,   5, 202,  38, 147, 118, 126, 255,  82,  85, 212,
    207, 206,  59, 227,  47,  16,  58,  17, 182, 189,  28,  42, 223, 183, 170, 213,
    119, 248, 152,   2,  44, 154, 163,  70, 221, 153, 101, 155, 167,  43, 172,   9,
    129,  22,  39, 253,  19,  98, 108, 110,  79, 113, 224, 232, 178, 185, 112, 104,
    218, 246,  97, 228, 251,  34, 242, 193, 238, 210, 144,  12, 191, 179, 162, 241,
     81,  51, 145, 235, 249,  14, 239, 107,  49, 192, 214,  31, 181, 199, 106, 157,
    184,  84, 204, 176, 115, 121,  50,  45, 127,   4, 150, 254, 138, 236, 205,  93,
    222, 114,  67,  29,  24,  72, 243, 141, 128, 195,  78,  66, 215,  61, 156, 180
};
    public float AlphaTest;

    private void Awake()
    {
        InitP();
    }


    private void InitP()
    {
        for (int i = 0; i < 256; i++)
            p[256 + i] = p[i] = permutation[i];
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_RaymarchingMat == null)
        {
            Graphics.Blit(source, destination);
            return;
        }
        _RaymarchingMat.SetMatrix("_camfrustum", Camfrustum(m_Camera));
        _RaymarchingMat.SetMatrix("_camToWorld", m_Camera.cameraToWorldMatrix);
        _RaymarchingMat.SetFloat("max_Distance", Max_Distance);
        _RaymarchingMat.SetVector("lightDir", LightPos.forward);
        _RaymarchingMat.SetTexture("_MainTex", source);
        _RaymarchingMat.SetVector("_sphere1", _sphere1);
        _RaymarchingMat.SetVector("_sphere2", _sphere2);
        _RaymarchingMat.SetVector("_cube", cube);
        _RaymarchingMat.SetFloat("_boxround",_boxround);
        _RaymarchingMat.SetFloat("box_sphere_smooth", box_sphere_smooth);
        _RaymarchingMat.SetFloat("_sphereIntersectSmooth", _sphereIntersectSmooth);
        _RaymarchingMat.SetColor("_ShadingColor",_color);
        _RaymarchingMat.SetColor("_LightCol",light.color);
        _RaymarchingMat.SetFloat("_LightIntensity", light.intensity);
        _RaymarchingMat.SetFloat("_ShdowIntensity", _ShdowIntensity);
        _RaymarchingMat.SetVector("_ShadowDistance", _ShadowDistance);
        _RaymarchingMat.SetFloat("_ShadowPenumbra", _ShadowPenumbra);
        _RaymarchingMat.SetFloat("Accuracy", Accuracy);
        _RaymarchingMat.SetInt("MaxIteration", MaxIteration);
        _RaymarchingMat.SetFloat("AOstepSize", AOstepSize);
        _RaymarchingMat.SetInt("AOIteration",AOIteration);
        _RaymarchingMat.SetFloat("AOIntensity", AOIntensity);
        _RaymarchingMat.SetFloatArray("permutation", permutation);
        _RaymarchingMat.SetFloatArray("p", p);
        _RaymarchingMat.SetFloat("_AlphaTest",AlphaTest);

        RenderTexture.active = destination;
        
        GL.PushMatrix();
        GL.LoadOrtho();
        _RaymarchingMat.SetPass(0);
        GL.Begin(GL.QUADS);

        //TL
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);
        //TR
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);
        //BR
        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f);
        //BL
        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f);

        GL.End();
        GL.PopMatrix();
    }

    /// <summary>
    /// 创建视锥体矩阵
    /// </summary>
    /// <returns></returns>
    private Matrix4x4 Camfrustum(Camera camera)
    {
        Matrix4x4 matrix = new Matrix4x4();
        //fov    t/n
        float fov=Mathf.Tan((camera.fieldOfView*0.5f) * Mathf.Deg2Rad);

        //计算四个张角
        Vector3 Up = Vector3.up * fov;
        Vector3 Right = Vector3.right * fov * camera.aspect;

        Vector3 TL = (-Vector3.forward - Right + Up);
        Vector3 TR = (-Vector3.forward + Right + Up);
        Vector3 BR = (-Vector3.forward + Right - Up);
        Vector3 BL = (-Vector3.forward - Right - Up);

        matrix.SetRow(0, TL);
        matrix.SetRow(1, TR);
        matrix.SetRow(2, BR);
        matrix.SetRow(3, BL);
        return matrix;
    }

    
}
