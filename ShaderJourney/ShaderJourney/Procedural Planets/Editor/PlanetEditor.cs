using UnityEditor;
using UnityEngine;
using System;
using Object = UnityEngine.Object;
[CustomEditor(typeof(Planet))]
public class PlanetEditor : Editor
{
    Planet planet;
    Editor colorEditor;
    Editor shapeEditor;

    public override void OnInspectorGUI()
    { 
        using (var check = new EditorGUI.ChangeCheckScope())
        {
            base.OnInspectorGUI();
            if(check.changed)
            {
                planet.GeneratePlanet();
            }
        }
        if(GUILayout.Button("Generate Planet"))
        {
            planet.GeneratePlanet(); 
        }
        DrawSettingEditor(planet._colorSetting, planet.UpdateColor,ref planet.ColorSettingFoldout,ref colorEditor);
        DrawSettingEditor(planet._shapeSetting, planet.UpdateShape,ref planet.ShapeSettingFoldout,ref shapeEditor);
    }

    private void DrawSettingEditor(Object setting,Action drawSettingAction,ref bool foldout,ref Editor editor)
    {
        foldout = EditorGUILayout.InspectorTitlebar(foldout, setting);
        using (var check=new EditorGUI.ChangeCheckScope())
        {
            if(foldout)
            {
                CreateCachedEditor(setting, null, ref editor);
                editor.OnInspectorGUI();
            
                if(check.changed)
                {
                    drawSettingAction?.Invoke();
                }

            }
        }
    }


    private void OnEnable()
    {
        planet = (Planet)target;
    }
}
