//Script created by Merlin and Xiexe.
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.IO;
namespace XSToon3
{
    public class XSTextureMerger : EditorWindow
    {

        private enum resolutions
        {
            Tiny_256x256,
            Small_512x512,
            Medium_1024x1024,
            Large_2048x2048,
            VeryLarge_4096x4096,
            Why_8192x8192
        }

        private enum EChannels
        {
            None,
            Red,
            Green,
            Blue,
            Alpha
        }

        private enum ETextures
        {
            None,
            Tex1,
            Tex2,
            Tex3,
            Tex4
        }


        private Texture2D[] textures = new Texture2D[4];
        private EChannels[] texChannels = new EChannels[4];
        private ETextures[] pickTexture = new ETextures[4];
        private bool[] invertChannel = new bool[4];

        private static int srcTex;
        private resolutions res;
        private Vector2 scrollPos;
        private static int resolution;
        private static string finalFilePath;
        private static Color outColor;
        private static Color[] texColors = new Color[4];

	    private static float progress;
	    [MenuItem("Tools/Xiexe/XSToon/Texture Merger")]
        static public void Init()
        {
            XSTextureMerger window = EditorWindow.GetWindow<XSTextureMerger>(false, "XSToon: Texture Merger", true);
            window.minSize = new Vector2(500, 300);
            window.maxSize = new Vector2(500, 500);
        }

        public void OnGUI()
        {
            scrollPos = EditorGUILayout.BeginScrollView(scrollPos);

            GUILayout.BeginHorizontal();
                GUILayout.Space(105);
                    XSStyles.doLabel("1");
                GUILayout.Space(105);
                    XSStyles.doLabel("2");
                GUILayout.Space(105);
                    XSStyles.doLabel("3");
                GUILayout.Space(105);
                    XSStyles.doLabel("4");
            GUILayout.EndHorizontal();

            XSStyles.SeparatorThin();
            GUILayout.BeginHorizontal();
            for (int i = 0; i < 4; i++)
            {
                EditorGUIUtility.labelWidth = 0.01f;
                textures[i] = (Texture2D)EditorGUILayout.ObjectField(new GUIContent("", ""), textures[i], typeof(Texture2D), true);

            }
            GUILayout.EndHorizontal();

            float oldLabelWidth = EditorGUIUtility.labelWidth;
            EditorGUIUtility.labelWidth = 40;
            GUIStyle headerStyle = EditorStyles.boldLabel;
            headerStyle.alignment = TextAnchor.UpperLeft;
            headerStyle.fontStyle = FontStyle.Bold;
            headerStyle.stretchWidth = true;

            XSStyles.SeparatorThin();
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label("Output Channel:", headerStyle);

            GUILayout.Label("R", headerStyle);
            GUILayout.Label("G", headerStyle);
            GUILayout.Label("B", headerStyle);
            GUILayout.Label("A", headerStyle);
            EditorGUILayout.EndHorizontal();

            GUILayout.BeginHorizontal();
            GUILayout.Label("Src Texture:");
            GUILayout.Space(20);
                for(int i = 0; i < 4; i++)
                {
                    pickTexture[i] = (ETextures)EditorGUILayout.EnumPopup("", pickTexture[i]);
                }
            GUILayout.EndHorizontal();

            GUILayout.BeginHorizontal();
            GUILayout.Label("Src Channel:");
            GUILayout.Space(17);
                for(int i = 0; i < 4; i++)
                {
                    texChannels[i] = (EChannels)EditorGUILayout.EnumPopup("", texChannels[i]);
                }
            GUILayout.EndHorizontal();
            GUILayout.BeginHorizontal();
                GUILayout.Label("Invert Channel:");
                for(int i = 0; i < 4; i++)
                {
                    invertChannel[i] = EditorGUILayout.Toggle("", invertChannel[i]);
                }
            GUILayout.EndHorizontal();

            GUILayout.Space(20);
            EditorGUILayout.EndScrollView();

            //Button and Resolution
            GUILayout.BeginVertical();
                XSStyles.doLabel("Resolution");

                GUILayout.BeginHorizontal();
                    GUILayout.Space(175);
                        res = (resolutions)EditorGUILayout.EnumPopup("", res);
                    GUILayout.Space(175);
                GUILayout.EndHorizontal();

                if(GUILayout.Button("Merge Channels"))
                {
				    if (progress < 2)
				    {
					    EditorUtility.DisplayProgressBar("XSToon Texture Merger", "Merging and compressing new texture...", (float)(progress / 2));
				    }

			    //Set target textures to be ReadWriteable

			    for (int i = 0; i < textures.Length; i++)
                    {
                        if(textures[i] == null)
                            break;

                        string texturePath = AssetDatabase.GetAssetPath(textures[i]);
                        TextureImporter texture = (TextureImporter)TextureImporter.GetAtPath(texturePath);
                        if (texture != null)
                        {
                            texture.isReadable = true;
                            texture.SaveAndReimport();
                        }
                    }

                    switch(res)
                    {
                        case resolutions.Tiny_256x256:
                            resolution = 256;
                        break;

                        case resolutions.Small_512x512:
                            resolution = 512;
                        break;

                        case resolutions.Medium_1024x1024:
                            resolution = 1024;
                        break;

                        case resolutions.Large_2048x2048:
                            resolution = 2048;
                        break;

                        case resolutions.VeryLarge_4096x4096:
                            resolution = 4096;
                        break;

                        case resolutions.Why_8192x8192:
                            resolution = 8192;
                        break;
                    }

                    XSStyles.findAssetPath(finalFilePath);
                    finalFilePath = EditorUtility.SaveFilePanel("Save Merged Texture", finalFilePath + "/Textures/", "mergedTex.png", "png");


                    Texture2D newTexture = new Texture2D(resolution, resolution, TextureFormat.RGBA32, false);

                    //Get Colors textures and write them to the proper channel

                        for (int y = 0; y <  resolution; y++)
                        {
                            for (int x = 0; x <  resolution; x++)
                            {
                                float u = x / (float)resolution;
                                float v = y / (float)resolution;

							    // Grab out the texture values into an array for later lookup. Could probably just be done at the moment the texture color is needed.
                                for(int i = 0; i < textures.Length; i++)
                                {
                                    if(textures[i] != null)
                                    {
                                        texColors[i] = textures[i].GetPixelBilinear(u, v);
                                    }
								    else
								    {
									    texColors[i] = new Color(0, 0, 0, 1);
								    }
                                }

							    Color outputColor = new Color(0, 0, 0, 1);

							    // Iterate the output RGBA channels
							    for (int i = 0; i < 4; i++)
							    {
								    // Convert the enums to indices we can use. 'None' will turn into -1 which will be discarded as invalid.
								    int srcTexIdx = ((int)pickTexture[i]) - 1;
								    int srcChannelIdx = ((int)texChannels[i]) - 1;

								    // Go through each channel in the output color and assign it
								    if (srcTexIdx >= 0 && srcChannelIdx >= 0)
								    {
									    outputColor[i] = texColors[srcTexIdx][srcChannelIdx];

                                        //Allow you to invert specific channels.
                                        if (invertChannel[i])
                                        {
                                            outputColor[i] = 1f - outputColor[i];
                                        }
                                    }
							    }

                                newTexture.SetPixel(x, y, outputColor);
                            }
                        }
				    progress += 1;
				    newTexture.Apply();
                    ExportTexture(newTexture);
                }

                GUILayout.Space(10);
            GUILayout.EndVertical();



		    EditorGUIUtility.labelWidth = oldLabelWidth;
        }

        private static void ExportTexture(Texture2D newTexture)
        {
            var pngData = newTexture.EncodeToPNG();

            if (pngData != null)
            {
                File.WriteAllBytes(finalFilePath, pngData);
                AssetDatabase.Refresh();
            }
		    progress += 1;
		    EditorUtility.ClearProgressBar();
	    }
    }
}