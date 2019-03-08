using UnityEngine;
using UnityEditor;
using System.Collections;
using System.IO;

public class XSGradientEditor : EditorWindow
{

    public Gradient gradient;
    // resolution presets
    public static Texture shadowRamp;
    public string finalFilePath;
    public enum resolutions
    {
        Tiny64x8,
        Small128x8,
        Medium256x8,
        Large512x8
    }
    public resolutions res;

    [MenuItem("Tools/Xiexe/XSToon/Gradient Editor")]
    // Use this for initialization
    static public void Init()
    {
        XSGradientEditor window = EditorWindow.GetWindow<XSGradientEditor>(false, "XSToon: Gradient Editor", true);
        window.minSize = new Vector2(300, 170);
        window.maxSize = new Vector2(301, 171);
    }

    public void OnGUI()
    {



        if (gradient == null)
        {
            gradient = new Gradient();
        }
        EditorGUI.BeginChangeCheck();
        SerializedObject serializedGradient = new SerializedObject(this);
        SerializedProperty colorGradient = serializedGradient.FindProperty("gradient");
        EditorGUILayout.PropertyField(colorGradient, true, null);
        serializedGradient.ApplyModifiedProperties();

        int width = 128;
        int height = 8;

        res = (resolutions)EditorGUILayout.EnumPopup("Resolution: ", res);

        switch (res)
        {
            case resolutions.Large512x8:
                width = 512;
                break;

            case resolutions.Medium256x8:
                width = 256;
                break;

            case resolutions.Small128x8:
                width = 128;
                break;

            case resolutions.Tiny64x8:
                width = 64;
                break;
        }

        if (gradient != null)
        {

            Texture2D tex = new Texture2D(width, height, TextureFormat.RGBA32, false);


            for (int y = 0; y < tex.height; y++)
            {
                for (int x = 0; x < tex.width; x++)
                {
                    tex.SetPixel(x, y, gradient.Evaluate((float)x / (float)width));
                }
            }


            XSStyles.Separator();
            if (GUILayout.Button("Save Ramp"))
            {
                XSStyles.findAssetPath(finalFilePath);
                string path = EditorUtility.SaveFilePanel("Save Ramp as PNG", finalFilePath + "/Textures/Shadow Ramps/Generated", "gradient.png", "png");
                if (path.Length != 0)
                {
                    GenTexture(tex, path);
                }
            }
        }

        XSStyles.HelpBox("You can use this to create a custom shadow ramp. \nYou must save the asset with the save button to apply changes. \n\n - Click the Gradient box. \n - Choose resolution. \n - Save. \n - Drag texture into slot.", MessageType.Info);
    }

    static void GenTexture(Texture2D tex, string path)
    {
        var pngData = tex.EncodeToPNG();
        if (pngData != null)
        {
            File.WriteAllBytes(path, pngData);
            AssetDatabase.Refresh();
            ChangeImportSettings(path);
        }

    }
    static void ChangeImportSettings(string path)
    {

        string s = path.Substring(path.LastIndexOf("Assets"));
        TextureImporter texture = (TextureImporter)TextureImporter.GetAtPath(s);
        if (texture != null)
        {
            texture.wrapMode = TextureWrapMode.Clamp;
            texture.maxTextureSize = 512;
            texture.mipmapEnabled = false;
            texture.textureCompression = TextureImporterCompression.Uncompressed;
            texture.sRGBTexture = false;

            texture.SaveAndReimport();
            AssetDatabase.Refresh();

            // shadowRamp = (Texture)Resources.Load(path);
            // Debug.LogWarning(shadowRamp.ToString());
        }
        else
        {
            Debug.Log("Asset Path is Null, can't set to Clamped.\n You'll need to do it manually.");
        }
    }
}