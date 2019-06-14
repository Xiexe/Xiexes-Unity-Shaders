using UnityEngine;
using UnityEditor;
using System.Collections;
using System.IO;

public class XSGradientEditor : EditorWindow
{

    public Gradient[] gradients;
    public int gradientAmount = 1;
    public Texture2D tex;

    private string finalFilePath;

	private bool isLinear = false;
    private bool manualMaterial = false;
    private enum Resolutions
    {
        Tiny64x8 = 64,
        Small128x8 = 128,
        Medium256x8 = 256,
        Large512x8 = 512
    }
    private Resolutions res = Resolutions.Tiny64x8;
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
        if (gradients == null) {
            gradients = new Gradient[1];
        }

        if (focusedMat != null && gradients != null)
        {
            XSStyles.ShurikenHeader("Current Material: " + focusedMat.name);
        }
        else
        {
            XSStyles.ShurikenHeader("Current Material: None");
        }

        SerializedObject serializedGradients = new SerializedObject(this);
        SerializedProperty colorGradients = serializedGradients.FindProperty("gradients");
        for (int i = gradientAmount-1; i > -1; i--)
        {
            EditorGUILayout.PropertyField(colorGradients.GetArrayElementAtIndex(i), new GUIContent("Gradient " + Mathf.Abs(i-gradientAmount)), true, null);
        }
        bool changed = serializedGradients.ApplyModifiedProperties();

        GUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();
        GUI.enabled = gradientAmount > 1;
        bool minusGrads = GUILayout.Button("-", GUILayout.ExpandWidth(false));
        GUI.enabled = gradientAmount < 5;
        bool addGrads = GUILayout.Button("+", GUILayout.ExpandWidth(false));
        GUI.enabled = true;
        GUILayout.EndHorizontal();

        if (minusGrads) {
            int new_ga = Mathf.Clamp(gradientAmount-1, 1, 5);
            if (new_ga < gradientAmount) {
                gradientAmount = new_ga;
                Gradient[] grads = new Gradient[gradientAmount];
                for (int i = 0; i < grads.Length; i++)
                {
                    grads[i] = gradients[i];
                }
                gradients = grads;
                changed = true;
            }
        }
        if (addGrads) {
            int new_ga = Mathf.Clamp(gradientAmount+1, 1, 5);
            if (new_ga > gradientAmount) {
                gradientAmount = new_ga;
                gradientAmount = new_ga;
                Gradient[] grads = new Gradient[gradientAmount];
                for (int i = 0; i < gradients.Length; i++)
                {
                    grads[i] = gradients[i];
                }
                gradients = grads;
                changed = true;
            }
        }

        // bool changed = !CompareGradients(oldGradient, gradient);

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

        Resolutions oldRes = res;
        res = (Resolutions)EditorGUILayout.EnumPopup("Resolution: ", res);
        if (oldRes != res) changed = true;

        int width = (int)res;
        int height = 25;
        height *= 5;

        isLinear = GUILayout.Toggle(isLinear, "Make Linear Texture");
        manualMaterial = GUILayout.Toggle(manualMaterial, "Manual Material");

        if(manualMaterial)
        {
            focusedMat = (Material)EditorGUILayout.ObjectField(new GUIContent("", ""), focusedMat, typeof(Material), true);
        }

        if (changed) {
            tex = new Texture2D(width, height, TextureFormat.RGBA32, false);
            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    // int wtf = (height-y)-1;
                    int wtf = y;
                    int gradNum = Mathf.FloorToInt(wtf/25f);
                    if (gradNum >= gradientAmount) {
                        tex.SetPixel(x, y, Color.white);
                    } else {
                        if (gradients[gradNum] != null) {
                            if (false) { // Vertical Blurring
                                float time = (float)x / (float)width;
                                Color grad0 = gradients[Mathf.Min(gradientAmount-1, gradNum+1)].Evaluate(time);
                                Color grad1 = gradients[gradNum].Evaluate(time);
                                Color grad2 = gradients[Mathf.Max(0, gradNum-1)].Evaluate(time);
                                int o = 25*gradNum;
                                o+=13;
                                Color col1 = Color.Lerp(grad1, grad2, (o-(y+6))/25f);
                                o = 25*(gradNum+1);
                                o-=6;
                                Color fincol = Color.Lerp(col1, grad0, ((y+6)-o)/25f);
                                tex.SetPixel(x, y, fincol);
                            } else {
                                tex.SetPixel(x, y, gradients[gradNum].Evaluate((float)x / (float)width));
                            }
                        } else {
                            tex.SetPixel(x, y, Color.magenta);
                        }
                    }
                    // tex.SetPixel(x, y, Color.Lerp(Color.black, Color.red, (float)x/width)+Color.Lerp(Color.black, Color.green, (float)y/height));
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
        tex.Apply(false, false);
        Rect r = EditorGUILayout.GetControlRect();
        r.height = 125f;
        r.width = 512f;
        GUI.DrawTexture(r, tex);
        // XSStyles.HelpBox("You can use this to create a custom shadow ramp in realtime. \nIf you do not save, the ramp will be reverted back to what it was previously. \n\n - Click the Gradient box. \n - Choose resolution of the texture. \n - Save.", MessageType.Info);
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

    bool GenTexture(Texture2D tex, string path)
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

    bool ChangeImportSettings(string path)
    {

        string s = path.Substring(path.LastIndexOf("Assets"));
        TextureImporter texture = (TextureImporter)TextureImporter.GetAtPath(s);
        if (texture != null)
        {
            texture.wrapMode = TextureWrapMode.Clamp;
            texture.maxTextureSize = 512;
            texture.mipmapEnabled = false;
            texture.textureCompression = TextureImporterCompression.Uncompressed;

            texture.sRGBTexture = !isLinear;

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