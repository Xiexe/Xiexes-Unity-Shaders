using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System;
using UnityEditorInternal;

namespace XSToon3
{
    public class XSClipMapEditor : EditorWindow
    {
        [MenuItem("Tools/Xiexe/XSToon/Clip Map Editor")]
        static public void Init()
        {
            XSClipMapEditor window = EditorWindow.GetWindow<XSClipMapEditor>(false, "XSToon: Clip Map Editor", true);
            window.minSize = new Vector2(350, 330);
            window.minSize = new Vector2(350, 330);
        }

        private Vector2 ClipScrollPos;
        private int ClipMapCount = 1;
        public Texture2D[] ClipMaps = new Texture2D[8];
        public static Renderer Rend;


        public XSToon3.TextureList TexList;
        private XSToon3.TextureList oldTexList;
        public string[] filters = new string[] {"Point (No Filtering)", "Bilinear", "Trilinear"};
        public FilterMode filterMode = FilterMode.Bilinear;

        public bool copyMips = true;
        public float mipMapBias = 0;

        public string[] wraps = new string[] {"Repeat", "Clamp", "Mirror", "Mirror Once", "Per Axis"};
        public int wrapMode = 0;
        public string[] wrapsAxis = new string[] {"Repeat", "Clamp", "Mirror", "Mirror Once"};
        public TextureWrapMode wrapModeU = TextureWrapMode.Repeat;
        public TextureWrapMode wrapModeV = TextureWrapMode.Repeat;

        public int anisoLevel = 1;
        public bool AutoAssignToMaterials = false;

        public struct TextureSettings
        {
            public FilterMode filterMode;
            public bool copyMips;
            public float mipMapBias;
            public TextureWrapMode wrapModeU;
            public TextureWrapMode wrapModeV;
            public int anisoLevel;
        }

        public bool showProperties = false;

        public void OnGUI()
        {
            XSStyles.ShurikenHeaderCentered("Clip Map Editor");
            XSStyles.HelpBox("All images must have the exact same dimensions, format, and number of mip levels!", MessageType.Info);

            XSStyles.SeparatorThin();
            ClipMapCount = EditorGUILayout.IntSlider("Count: ", ClipMapCount, 1, 16);
            XSStyles.SeparatorThin();
            ClipScrollPos = EditorGUILayout.BeginScrollView(ClipScrollPos);
            for (int i = 0; i < ClipMapCount; i++)
            {
                ClipMaps[i] = (Texture2D)EditorGUILayout.ObjectField($"Clip Map {i}:", ClipMaps[i], typeof(Texture2D));
            }
            EditorGUILayout.EndScrollView();
            XSStyles.SeparatorThin();
            GUI2DArray();
            XSStyles.SeparatorThin();
            if (GUILayout.Button("Create Array"))
            {
                CreateTextureArray();

            }
            GUILayout.Space(8);
        }

        private void CreateTextureArray()
        {
            TextureSettings settings = new TextureSettings();
            settings.filterMode = filterMode;
            settings.copyMips = copyMips;
            settings.mipMapBias = mipMapBias;
            settings.wrapModeU = wrapModeU;
            settings.wrapModeV = wrapModeV;
            settings.anisoLevel = anisoLevel;
            CopyListIntoArray(TexList, settings);
        }

        private void GUI2DArray()
        {
            /* Do we want mip maps? if so, copy them from the source textures **/
            copyMips = EditorGUILayout.Toggle("Copy Mip Maps", copyMips);
            if (copyMips)
            {
                mipMapBias = EditorGUILayout.FloatField("    Mip Map Bias", mipMapBias);
            }

            filterMode = (FilterMode) EditorGUILayout.Popup("Filter Mode", (int) filterMode, filters);

            /* Set the wrap mode to the same value on both axes unless wrapMode is 4 (Per Axis), then show separate options**/
            wrapMode = EditorGUILayout.Popup("Wrap Mode", wrapMode, wraps);
            if (wrapMode == 4)
            {
                wrapModeU = (TextureWrapMode) EditorGUILayout.Popup("    U Axis", (int) wrapModeU, wrapsAxis);
                wrapModeV = (TextureWrapMode) EditorGUILayout.Popup("    V Axis", (int) wrapModeV, wrapsAxis);
            }
            else
            {
                wrapModeU = (TextureWrapMode) wrapMode;
                wrapModeV = (TextureWrapMode) wrapMode;
            }

            anisoLevel = EditorGUILayout.IntSlider("Aniso Level", anisoLevel, 0, 16);
        }

        private bool HasSameSettings(Texture2D first, Texture2D nth, int index)
        {

            int fail = 0;
            if (first.width == nth.width && first.height == nth.height)
            {
                if (first.format == nth.format)
                {
                    if (first.mipmapCount != nth.mipmapCount)
                        fail = 3;
                }
                else fail = 2;
            }
            else fail = 1;

            switch (fail)
            {
                case 1:
                    EditorUtility.DisplayDialog("Textures not the same dimensions",
                        string.Format("Texture {0} has size of {1}x{2}, expected {3}x{4}",
                            index, nth.width, nth.height, first.width, first.height),
                        "ok");
                    return false;
                case 2:
                    EditorUtility.DisplayDialog("Textures not the format",
                        string.Format("Texture {0} has {1} format, expected {2}",
                            index, nth.format.ToString(), first.format.ToString()),
                        "ok");
                    return false;
                case 3:
                    EditorUtility.DisplayDialog("Not all Textures have the same number of mip levels",
                        string.Format("Texture {0} has {1} mip levels, expected {2}",
                            index, nth.mipmapCount, first.mipmapCount),
                        "ok");
                    return false;
                default:
                    return true;
            }
        }

        private void CopyListIntoArray(TextureList List, TextureSettings Settings)
        {
            if (ClipMaps.Length > 0)
            {
                if (ClipMaps[0] == null)
                {
                    EditorUtility.DisplayDialog("First element unassigned", "Element 0 of the texture list is empty!",
                        "ok");
                    return;
                }

                Texture2DArray output = new Texture2DArray(ClipMaps[0].width, ClipMaps[0].height, ClipMaps.Length, ClipMaps[0].format, Settings.copyMips);
                output.mipMapBias = Settings.mipMapBias;
                output.filterMode = Settings.filterMode;
                output.wrapModeU = Settings.wrapModeU;
                output.wrapModeV = Settings.wrapModeV;
                output.anisoLevel = Settings.anisoLevel;

                bool consistentSettings = true;
                for (int i = 0; i < ClipMapCount; i++)
                {
                    /* Stop if one of the elements in the list is empty **/
                    if (ClipMaps[i] == null)
                    {
                        EditorUtility.DisplayDialog("Element unassigned",
                            string.Format("Element {0} of the texture list is empty!", i), "ok");
                        return;
                    }

                    /* Stop if the texture being copied doesn't have the same settings as the first element of the array **/
                    consistentSettings = HasSameSettings(ClipMaps[0], ClipMaps[i], i);
                    if (consistentSettings == false)
                        return;

                    /* Copy the contents of the texture into the corresponding slice of the Texture2DArray, and copy over all the mips if copyMips is true **/
                    if (Settings.copyMips)
                    {
                        for (int j = 0; j < ClipMaps[0].mipmapCount; j++)
                        {
                            Graphics.CopyTexture(ClipMaps[i], 0, j, output, i, j);
                        }
                    }
                    else
                    {
                        Graphics.CopyTexture(ClipMaps[i], 0, 0, output, i, 0);
                    }
                }

                output.Apply(false);

                string path = "";
                if(Rend != null)
                    path = EditorUtility.SaveFilePanelInProject("Save Array", $"{Rend.name}_texarray.asset", "asset", "Please enter a file name to save the texture array to");
                else
                    path = EditorUtility.SaveFilePanelInProject("Save Array", "SwapMask_texarray.asset", "asset", "Please enter a file name to save the texture array to");

                if (path.Length != 0)
                {
                    AssetDatabase.CreateAsset(output, path);
                }
            }
        }
    }
}