using UnityEngine;
using UnityEditor;
using System.Collections;
using System.IO;

public class XSGradientEditor : EditorWindow
{

    public Gradient gradient;
    public Gradient oldGradient;
    // resolution presets
    public static Texture shadowRamp;
    public string finalFilePath;

	static public bool isLinear = true;
    public enum Resolutions
    {
        Tiny64x8 = 64,
        Small128x8 = 128,
        Medium256x8 = 256,
        Large512x8 = 512
    }
    public Resolutions res = Resolutions.Tiny64x8;
    public static Material focusedMat;
    private Material oldFocusedMat;
    private Texture oldTexture;

    [MenuItem("Tools/Xiexe/XSToon/Gradient Editor")]
    // Use this for initialization
    static public void Init()
    {
        XSGradientEditor window = EditorWindow.GetWindow<XSGradientEditor>(false, "XSToon: Gradient Editor", true);
        window.minSize = new Vector2(375, 195);
        // window.maxSize = new Vector2(311, 181);
    }

    public void OnGUI()
    {


        if (gradient == null)
        {
            gradient = new Gradient();
        }
        if (oldGradient == null)
        {
            oldGradient = new Gradient();
        }

        if (focusedMat != null && gradient != null)
        {
            XSStyles.ShurikenHeader("Current Material: " + focusedMat.name);
        }
        else
        {
            XSStyles.ShurikenHeader("Current Material: None");
        }

        SerializedObject serializedGradient = new SerializedObject(this);
        SerializedProperty colorGradient = serializedGradient.FindProperty("gradient");
        EditorGUILayout.PropertyField(colorGradient, true, null);
        serializedGradient.ApplyModifiedProperties();

        bool changed = !CompareGradients(oldGradient, gradient);

        if (oldFocusedMat != focusedMat)
        {
            changed = true;
            if (this.oldTexture != null)
            {
                if (this.oldTexture == EditorGUIUtility.whiteTexture) this.oldTexture = null;
                oldFocusedMat.SetTexture("_Ramp", this.oldTexture);
                this.oldTexture = null;
            }
            oldFocusedMat = focusedMat;
        }

        if (changed)
        {
            oldGradient.SetKeys(gradient.colorKeys, gradient.alphaKeys);
            oldGradient.mode = gradient.mode;
        }

        Resolutions oldRes = res;
        res = (Resolutions)EditorGUILayout.EnumPopup("Resolution: ", res);
        if (oldRes != res) changed = true;

        int width = (int)res;
        int height = 8;

        isLinear = GUILayout.Toggle(isLinear, "Make Linear Texture");

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

            if (focusedMat != null)
            {
                if (changed)
                {
                    if (focusedMat.HasProperty("_Ramp"))
                    {
                        if (this.oldTexture == null)
                        {
                            if (focusedMat.GetTexture("_Ramp") == null)
                            {
                                this.oldTexture = EditorGUIUtility.whiteTexture;
                            } else {
                                this.oldTexture = focusedMat.GetTexture("_Ramp");
                            }
                        }
                        tex.wrapMode = TextureWrapMode.Clamp;
                        tex.Apply(false);
                        focusedMat.SetTexture("_Ramp", tex);
                    }
                }
            }

            XSStyles.Separator();
            if (GUILayout.Button("Save Ramp"))
            {
                finalFilePath = XSStyles.findAssetPath(finalFilePath);
                string path = EditorUtility.SaveFilePanel("Save Ramp as PNG", finalFilePath + "/Textures/Shadow Ramps/Generated", "gradient.png", "png");
                if (path.Length != 0)
                {
                    bool success = GenTexture(tex, path);
                    if (success)
                    {
                        if (focusedMat != null)
                        {
                            string s = path.Substring(path.IndexOf("Assets"));
                            Texture ramp = AssetDatabase.LoadAssetAtPath<Texture>(s);
                            if (ramp != null)
                            {
                                focusedMat.SetTexture("_Ramp", ramp);
                                this.oldTexture = null;
                            }
                        }
                    }
                }
            }
        }

        XSStyles.HelpBox("You can use this to create a custom shadow ramp in realtime. \nIf you do not save, the ramp will be reverted back to what it was previously. \n\n - Click the Gradient box. \n - Choose resolution of the texture. \n - Save.", MessageType.Info);
    }

    void OnDestroy()
    {
        if (focusedMat != null)
        {
            if (this.oldTexture != null)
            {
                if (this.oldTexture == EditorGUIUtility.whiteTexture)
                {
                    this.oldTexture = null;
                }
                focusedMat.SetTexture("_Ramp", this.oldTexture);
                this.oldTexture = null;
            }
            focusedMat = null;
        }
    }

    static bool GenTexture(Texture2D tex, string path)
    {
        var pngData = tex.EncodeToPNG();
        if (pngData != null)
        {
            File.WriteAllBytes(path, pngData);
            AssetDatabase.Refresh();
            return ChangeImportSettings(path);
        }
        return false;
    }

    static bool ChangeImportSettings(string path)
    {

        string s = path.Substring(path.LastIndexOf("Assets"));
        TextureImporter texture = (TextureImporter)TextureImporter.GetAtPath(s);
        if (texture != null)
        {
            texture.wrapMode = TextureWrapMode.Clamp;
            texture.maxTextureSize = 512;
            texture.mipmapEnabled = false;
            texture.textureCompression = TextureImporterCompression.Uncompressed;

            texture.sRGBTexture = isLinear;

            texture.SaveAndReimport();
            AssetDatabase.Refresh();
            return true;

            // shadowRamp = (Texture)Resources.Load(path);
            // Debug.LogWarning(shadowRamp.ToString());
        }
        else
        {
            Debug.Log("Asset Path is Null, can't set to Clamped.\n You'll need to do it manually.");
        }
        return false;
    }

    // From https://answers.unity.com/questions/621366/how-to-check-if-a-gradient-in-editor-has-been-chan.html
    public static bool CompareGradients(Gradient gradient, Gradient otherGradient)
    {
        if (otherGradient.mode != gradient.mode)
        {
            return false;
        }
        // Compare the lengths before checking actual colors and alpha components
        if (gradient.colorKeys.Length != otherGradient.colorKeys.Length ||
            gradient.alphaKeys.Length != otherGradient.alphaKeys.Length)
        {
            return false;
        }
        
        // Compare all the colors
        for (int i = 0; i < gradient.colorKeys.Length; i++)
        {
            // Test if the color and alpha is the same
            GradientColorKey key = gradient.colorKeys[i];
            GradientColorKey otherKey = otherGradient.colorKeys[i];
            if (key.color != otherKey.color || key.time != otherKey.time)
            {
                return false;
            }
        }
        
        // Compare all the alphas
        for (int i = 0; i < gradient.alphaKeys.Length; i++)
        {
            // Test if the color and alpha is the same
            GradientAlphaKey key = gradient.alphaKeys[i];
            GradientAlphaKey otherKey = otherGradient.alphaKeys[i];
            if (key.alpha != otherKey.alpha || key.time != otherKey.time)
            {
                return false;
            }
        }
        
        // They're the same
        return true;
     }
}