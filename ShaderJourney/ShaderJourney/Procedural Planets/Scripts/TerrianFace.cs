using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TerrianFace
{
    private Mesh _mesh;
    private int _Resolution;
    private Vector3 _FaceVector;
    private Vector3 _axixA;
    private Vector3 _axixB;
    private ShapeGenerate _ShapeGenerate;

    public TerrianFace(ShapeGenerate shapeGenerate,Mesh mesh, int resolution, Vector3 faceVector)
    {
        _mesh = mesh;
        _Resolution = resolution;
        _FaceVector = faceVector;
        this._ShapeGenerate = shapeGenerate;
        _axixA = new Vector3(_FaceVector.y,_FaceVector.z,_FaceVector.x);
        _axixB = Vector3.Cross(_FaceVector,_axixA);
    }


    public void ConstructMesh()
    {
        Vector3[] vertexs = new Vector3[_Resolution * _Resolution];
        Vector2[] uv = (_mesh.uv.Length==vertexs.Length)?_mesh.uv:new Vector2[vertexs.Length];
        int[] Triangles = new int[(_Resolution-1)*(_Resolution-1)*6];
        int TriIndex = 0;

        for (int x = 0; x < _Resolution; x++)
        {
            for (int y = 0; y < _Resolution; y++)
            {
                int i = x + y * _Resolution;
                Vector2 percent = new Vector2(x, y) / (_Resolution-1);

                //计算局部坐标
                Vector3 UnitCube = _FaceVector + (percent.x - .5f) * 2 * _axixA + (percent.y - .5f) * 2 * _axixB;
                //将顶点的长度拉到1 即得到球面
                Vector3 UnitSphere = UnitCube.normalized;
                float UnscaledElevation = _ShapeGenerate.CaluculateUnscaledElevation(UnitSphere);
                vertexs[i] = UnitSphere * _ShapeGenerate.GetScaledElevation(UnscaledElevation);
                uv[i].y = UnscaledElevation;


                //添加三角形序列号
                if(x!=_Resolution-1&&y!=_Resolution-1)
                {
                    Triangles[TriIndex] = i;
                    Triangles[TriIndex + 1] = i + _Resolution + 1;
                    Triangles[TriIndex + 2] = i + _Resolution;

                    Triangles[TriIndex + 3] = i;
                    Triangles[TriIndex + 4] = i + 1;
                    Triangles[TriIndex + 5] = i + 1 + _Resolution;

                    TriIndex += 6;
                }
            }
        }
        //构造网格
        _mesh.Clear();
        _mesh.SetVertices(vertexs);
        _mesh.SetTriangles(Triangles,0);
        _mesh.RecalculateNormals();
        _mesh.uv = uv;

    }


    public void UpdateUV(ColorGenerate colorGenerate)
    {
        Vector2[] uv = _mesh.uv;
        for (int x = 0; x < _Resolution; x++)
        {
            for (int y = 0; y < _Resolution; y++)
            {
                int i = x + y * _Resolution;
                Vector2 percent = new Vector2(x, y) / (_Resolution - 1);

                //计算局部坐标
                Vector3 UnitCube = _FaceVector + (percent.x - .5f) * 2 * _axixA + (percent.y - .5f) * 2 * _axixB;
                //将顶点的长度拉到1 即得到球面
                Vector3 UnitSphere = UnitCube.normalized;

                uv[i].x = colorGenerate.BiomePercentFromPoint(UnitSphere);
            }
        }
        _mesh.uv = uv;
    }
}
