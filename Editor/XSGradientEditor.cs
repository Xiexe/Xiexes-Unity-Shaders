using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System;
using UnityEditorInternal;

public class XSGradientEditor : EditorWindow
{
    public List<int> gradients_index = new List<int>(new int[1] { 0 });
    public List<Gradient> gradients = new List<Gradient>(5);
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
    private string rampProperty = "_Ramp";
    private ReorderableList grad_index_reorderable;
    private bool reorder;
    private static GUIContent iconToolbarPlus;
    private static GUIContent iconToolbarMinus;
    private static GUIStyle preButton;
    private static GUIStyle buttonBackground;
    private bool changed;
    private int loadGradIndex;
    private XSMultiGradient xsmg;
    private Vector2 scrollPos;

    private bool dHelpText = false;
    private bool dAdvanced = false;

    [MenuItem("Tools/Xiexe/XSToon/Gradient Editor")]
    static public void Init()
    {
        XSGradientEditor window = EditorWindow.GetWindow<XSGradientEditor>(false, "XSToon: Gradient Editor", true);
        window.minSize = new Vector2(450, 390);
    }

    public void OnGUI()
    {
        changed = false;
        if (focusedMat != null)
        {
            XSStyles.ShurikenHeader("Current Material: " + focusedMat.name);
        }
        else
        {
            XSStyles.ShurikenHeader("Current Material: None");
        }

        if (preButton == null)
        {
            iconToolbarPlus = EditorGUIUtility.IconContent("Toolbar Plus", "Add Gradient");
            iconToolbarMinus = EditorGUIUtility.IconContent("Toolbar Minus", "Remove Gradient");
            preButton = new GUIStyle("RL FooterButton");
            buttonBackground = new GUIStyle("RL Header");
        }

        if (gradients.Count == 0)
        {
            gradients.Add(new Gradient());
            gradients.Add(new Gradient());
            gradients.Add(new Gradient());
            gradients.Add(new Gradient());
            gradients.Add(new Gradient());
        }

        if (grad_index_reorderable == null)
        {
            makeReorderedList();
        }

        GUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();
        Rect r = EditorGUILayout.GetControlRect();
        float rightEdge = r.xMax;
        float leftEdge = rightEdge - 48f;
        r = new Rect(leftEdge, r.y, rightEdge - leftEdge, r.height);
        if (Event.current.type == EventType.Repaint) buttonBackground.Draw(r, false, false, false, false);
        leftEdge += 18f;
        EditorGUI.BeginDisabledGroup(gradients_index.Count == 5);
        bool addE = GUI.Button(new Rect(leftEdge + 4, r.y, 25, 13), iconToolbarPlus, preButton);
        EditorGUI.EndDisabledGroup();
        EditorGUI.BeginDisabledGroup(gradients_index.Count == 1);
        bool removeE = GUI.Button(new Rect(leftEdge - 19, r.y, 25, 13), iconToolbarMinus, preButton);
        EditorGUI.EndDisabledGroup();

        if (addE)
        {
            grad_index_reorderable.index++;
            int wat = 0;
            for (int i = 0; i < 5; i++)
            {
                if (!gradients_index.Contains(i))
                {
                    wat = i;
                    break;
                }
            }
            gradients_index.Add(wat);
            changed = true;
        }
        if (removeE)
        {
            gradients_index.Remove(gradients_index[gradients_index.Count - 1]);
            grad_index_reorderable.index--;
            changed = true;
        }

        GUIStyle button = new GUIStyle(EditorStyles.miniButton);
        button.normal = !reorder ? EditorStyles.miniButton.normal : EditorStyles.miniButton.onNormal;
        if (GUILayout.Button(new GUIContent("Reorder", "Don't use Reorder if you want to undo a gradient change"), button, GUILayout.ExpandWidth(false)))
        {
            reorder = !reorder;
        }
        GUILayout.EndHorizontal();

        SerializedObject serializedObject = new SerializedObject(this);
        if (reorder)
        {
            grad_index_reorderable.DoLayoutList();
        }
        else
        {
            SerializedProperty colorGradients = serializedObject.FindProperty("gradients");
            if (colorGradients.arraySize == 5)
            {
                for (int i = 0; i < gradients_index.Count; i++)
                {
                    Rect _r = EditorGUILayout.GetControlRect();
                    _r.x += 16f;
                    _r.width -= 2f + 16f;
                    _r.height += 5f;
                    _r.y += 2f + (3f * i);
                    EditorGUI.PropertyField(_r, colorGradients.GetArrayElementAtIndex(gradients_index[i]), new GUIContent(""));
                }
                GUILayout.Space(Mathf.Lerp(9f, 24f, gradients_index.Count / 5f));
            }
        }
        if (serializedObject.ApplyModifiedProperties()) changed = true;

        if (oldFocusedMat != focusedMat)
        {
            changed = true;
            if (this.oldTexture != null)
            {
                if (this.oldTexture == EditorGUIUtility.whiteTexture) this.oldTexture = null;
                oldFocusedMat.SetTexture(rampProperty, this.oldTexture);
                this.oldTexture = null;
            }
            oldFocusedMat = focusedMat;
        }

        Resolutions oldRes = res;
        res = (Resolutions)EditorGUILayout.EnumPopup("Resolution: ", res);
        if (oldRes != res) changed = true;

        int width = (int)res;
        int height = 30;
        if (gradients_index.Count == 1)
        {
            height = 8;
        }
        else
        {
            height = 150;
        }
        if (tex == null)
        {
            tex = new Texture2D(width, height, TextureFormat.RGBA32, false);
        }

        bool old_isLinear = isLinear;
        drawAdvancedOptions();
        if (old_isLinear != isLinear)
        {
            changed = true;
        }

        if (manualMaterial)
        {
            focusedMat = (Material)EditorGUILayout.ObjectField(new GUIContent("", ""), focusedMat, typeof(Material), true);
        }

        if (focusedMat != null)
        {
            if (focusedMat.HasProperty("_Ramp"))
            {
                rampProperty = "_Ramp";
            }
            else
            {
                rampProperty = EditorGUILayout.TextField("Ramp Property Name", rampProperty);
                if (!focusedMat.HasProperty(rampProperty))
                {
                    GUILayout.Label("Property not found!");
                }
            }
        }

        if (changed)
        {
            updateTexture(width, height);
            if (focusedMat != null)
            {
                if (focusedMat.HasProperty(rampProperty))
                {
                    if (this.oldTexture == null)
                    {
                        if (focusedMat.GetTexture(rampProperty) == null)
                        {
                            this.oldTexture = EditorGUIUtility.whiteTexture;
                        }
                        else
                        {
                            this.oldTexture = focusedMat.GetTexture(rampProperty);
                        }
                    }
                    tex.wrapMode = TextureWrapMode.Clamp;
                    tex.Apply(false, false);
                    focusedMat.SetTexture(rampProperty, tex);
                }
            }
        }

        XSStyles.Separator();
        drawMGInputOutput();


        if (GUILayout.Button("Save Ramp"))
        {
            finalFilePath = XSStyles.findAssetPath(finalFilePath);
            string path = EditorUtility.SaveFilePanel("Save Ramp as PNG", finalFilePath + "/Textures/Shadow Ramps/Generated", "gradient", "png");
            if (path.Length != 0)
            {
                updateTexture(width, height);
                bool success = GenTexture(tex, path);
                if (success)
                {
                    if (focusedMat != null)
                    {
                        string s = path.Substring(path.IndexOf("Assets"));
                        Texture ramp = AssetDatabase.LoadAssetAtPath<Texture>(s);
                        if (ramp != null)
                        {
                            focusedMat.SetTexture(rampProperty, ramp);
                            this.oldTexture = null;
                        }
                    }
                }
            }
        }
        drawHelpText();
    }   

    Gradient reflessGradient(Gradient old_grad)
    {
        Gradient grad = new Gradient();
        grad.SetKeys(old_grad.colorKeys, old_grad.alphaKeys);
        grad.mode = old_grad.mode;
        return grad;
    }

    List<int> reflessIndexes(List<int> old_indexes)
    {
        List<int> indexes = new List<int>();
        for (int i = 0; i < old_indexes.Count; i++)
        {
            indexes.Add(old_indexes[i]);
        }
        return indexes;
    }

    void makeReorderedList()
    {
        grad_index_reorderable = new ReorderableList(gradients_index, typeof(int), true, false, false, false);
        grad_index_reorderable.headerHeight = 0f;
        grad_index_reorderable.footerHeight = 0f;
        grad_index_reorderable.showDefaultBackground = true;

        grad_index_reorderable.drawElementCallback = (Rect rect, int index, bool isActive, bool isFocused) =>
        {
            if (gradients.Count == 5)
            {
                Type editorGui = typeof(EditorGUI);
                MethodInfo mi = editorGui.GetMethod("GradientField", BindingFlags.NonPublic | BindingFlags.Static, null, new Type[2] { typeof(Rect), typeof(Gradient) }, null);
                mi.Invoke(this, new object[2] { rect, gradients[gradients_index[index]] });
                if (Event.current.type == EventType.Repaint)
                {
                    changed = true;
                }
            }
        };

        grad_index_reorderable.onChangedCallback = (ReorderableList list) =>
        {
            changed = true;
        };
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
                focusedMat.SetTexture(rampProperty, this.oldTexture);
                this.oldTexture = null;
            }
            focusedMat = null;
        }
    }

    void updateTexture(int width, int height)
    {
        tex = new Texture2D(width, height, TextureFormat.RGBA32, false);
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                if (gradients_index.Count != 1)
                {
                    int gradNum = Mathf.FloorToInt(y / 30f);
                    gradNum = Mathf.Abs(gradNum - 5) - 1;
                    if (gradNum >= gradients_index.Count)
                    {
                        tex.SetPixel(x, y, Color.white);
                    }
                    else
                    {
                        if (gradients[gradients_index[gradNum]] != null)
                        {
                            Color grad_col = gradients[gradients_index[gradNum]].Evaluate((float)x / (float)width);
                            tex.SetPixel(x, y, isLinear ? grad_col.gamma : grad_col);
                        }
                        else
                        {
                            tex.SetPixel(x, y, Color.white);
                        }
                    }
                }
                else
                {
                    Color grad_col = gradients[gradients_index[0]].Evaluate((float)x / (float)width);
                    tex.SetPixel(x, y, isLinear ? grad_col.gamma : grad_col);
                }
            }
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

            // texture.sRGBTexture = !isLinear; // We already do the conversion in tex.SetPixel

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

    void drawMGInputOutput()
    {
        GUILayout.BeginHorizontal();
        XSMultiGradient old_xsmg = xsmg;
        xsmg = (XSMultiGradient)EditorGUILayout.ObjectField("MultiGradient Preset", xsmg, typeof(XSMultiGradient), false, null);
        if (xsmg != old_xsmg)
        {
            if (xsmg != null)
            {
                this.gradients = xsmg.gradients;
                this.gradients_index = xsmg.order;
                makeReorderedList();
            }
            else
            {
                List<Gradient> new_Grads = new List<Gradient>();
                for (int i = 0; i < this.gradients.Count; i++)
                {
                    new_Grads.Add(reflessGradient(this.gradients[i]));
                }
                this.gradients = new_Grads;
                this.gradients_index = reflessIndexes(this.gradients_index);
                makeReorderedList();
            }
            changed = true;
        }

        if (GUILayout.Button("Save New", EditorStyles.miniButton, GUILayout.ExpandWidth(false)))
        {
            finalFilePath = XSStyles.findAssetPath(finalFilePath);
            string path = EditorUtility.SaveFilePanel("Save MultiGradient", (finalFilePath + "/Textures/Shadow Ramps/MGPresets"), "MultiGradient", "asset");
            if (path.Length != 0)
            {
                path = path.Substring(Application.dataPath.Length - "Assets".Length);
                XSMultiGradient _xsmg = ScriptableObject.CreateInstance<XSMultiGradient>();
                _xsmg.uniqueName = Path.GetFileNameWithoutExtension(path);
                foreach (Gradient grad in gradients)
                {
                    _xsmg.gradients.Add(reflessGradient(grad));
                }
                _xsmg.order.AddRange(gradients_index.ToArray());
                xsmg = _xsmg;
                AssetDatabase.CreateAsset(_xsmg, path);
                this.gradients = xsmg.gradients;
                this.gradients_index = xsmg.order;
                makeReorderedList();
                AssetDatabase.SaveAssets();
            }
        }
        GUILayout.EndHorizontal();
    }

    void drawAdvancedOptions()
    {
        GUILayout.BeginHorizontal();
        isLinear = GUILayout.Toggle(isLinear, "Make Linear Texture");
        manualMaterial = GUILayout.Toggle(manualMaterial, "Manual Material");
        GUILayout.EndHorizontal();
    }

    void drawHelpText()
    {
        XSStyles.Separator();
        dHelpText = XSStyles.ShurikenFoldout("Information", dHelpText);
        if(dHelpText)
        {
            scrollPos = EditorGUILayout.BeginScrollView(scrollPos);
                XSStyles.HelpBox("You can use this to create a custom shadow ramp in realtime. \nIf you do not save, the ramp will be reverted back to what it was previously. \n\n - Click the Gradient box. \n - Choose resolution of the texture. \n - Save.", MessageType.Info);
                XSStyles.HelpBox("Ramp textures support up to 5 ramps in one texture. That means you can have up to 5 ramps on a single material. You will need to author a ramp mask to choose which ramp to sample from. \n\nA texture that is fully black would sample from the bottom ramp, a texture that is fully white would sample from the top ramp, and a texture that is half gray would sample from the middle ramp. \n\n A quick tip would be that you can sample from each of the 5 ramps with 0, 0.25, 0.5, 0.75, and 1 on the texture. \n\nThe order of the gradients on the UI is the order that they will be on the texture.", MessageType.Info);
            EditorGUILayout.EndScrollView();
        }
    }
}