using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class Planet : MonoBehaviour
{
    private Vector3[] _Directions = new Vector3[]
    {
        Vector3.up,
        Vector3.down,
        Vector3.right,
        Vector3.left,
        Vector3.forward,
        Vector3.back
    };
    [SerializeField]
    [Range(2,256)]
    private int _resolution=2;
    public ShapeSetting _shapeSetting;
    public ColorSetting _colorSetting;


    private ShapeGenerate _shapeGenerate=new ShapeGenerate();
    private ColorGenerate _colorGenerate=new ColorGenerate();   



    [HideInInspector]
    public bool ColorSettingFoldout;
    [HideInInspector]
    public bool ShapeSettingFoldout;

    public bool AutoUpdate = true;

    [SerializeField,HideInInspector]
    MeshFilter[] _filters;
    TerrianFace[] _faces;

    public enum RenderFaceMask
    {
        All,
        Front,
        Back,
        Right,
        Left,
        Up,
        Down,

    }
    public RenderFaceMask _renderFace;


    private void Initialize()
    {
        _shapeGenerate.UpdateInfo(_shapeSetting);
        _colorGenerate.UpdateInfo(_colorSetting);

        if (_filters == null || _filters.Length == 0)
        {
            _filters = new MeshFilter[6];
        }
        _faces = new TerrianFace[6];   
        
        for (int i = 0; i < 6; i++)
        {
            if (_filters[i] == null)
            {
                GameObject meshObj = new GameObject("Mesh");
                meshObj.transform.parent = transform;
                meshObj.AddComponent<MeshRenderer>();
                _filters[i] = meshObj.AddComponent<MeshFilter>();
                _filters[i].sharedMesh = new Mesh();
            }
            _filters[i].GetComponent<MeshRenderer>().sharedMaterial = _colorSetting.PlanetMaterial;

            _faces[i] = new TerrianFace(_shapeGenerate,_filters[i].sharedMesh, _resolution, _Directions[i]);
            bool renderface = _renderFace == RenderFaceMask.All || (int)_renderFace - 1 == i;
            _filters[i].gameObject.SetActive(renderface);
        }
    }

    public void GeneratePlanet()
    {
        Initialize();
        GenerateMesh();
        GenerateColor();
    }

    /// <summary>
    /// 生成程序网格
    /// </summary>
    public void GenerateMesh()
    {
        for (int i = 0; i < 6; i++)
        {
            if (_filters[i].gameObject.activeSelf)
            {
                _faces[i].ConstructMesh();
            }
        }
        //更新材质信息
        _colorGenerate.UpdateEvevation(_shapeGenerate.evalutionMinMax);
    }


    public void UpdateColor()
    {
        if (AutoUpdate) { 
        Initialize();
        GenerateColor();
        }
    }

    public void UpdateShape()
    {
        if (AutoUpdate)
        {
            Initialize();
            GenerateMesh();
        }
    }

    private void GenerateColor()
    {
        _colorGenerate.UpdateColors();
        for (int i = 0; i < 6; i++)
        {
            if (_filters[i].gameObject.activeSelf)
            {
                _faces[i].UpdateUV(_colorGenerate);
            }
        }
    }

     
}
