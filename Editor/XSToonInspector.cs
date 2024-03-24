using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace XSToon3
{
    // Would love to refactor / move this but it would break all the plugins...
    public partial class FoldoutToggles
    {
        public bool ShowMain = true;
        public bool ShowNormal = false;
        public bool ShowShadows = true;
        public bool ShowSpecular = false;
        public bool ShowReflection = false;
        public bool ShowRimlight = false;
        public bool ShowHalftones = false;
        public bool ShowSubsurface = false;
        public bool ShowOutlines = false;
        public bool ShowEmission = false;
        public bool ShowUvDiscard = false;
        public bool ShowAdvanced = false;
        public bool ShowEyeTracking = false;
        public bool ShowAudioLink = false;
        public bool ShowDissolve = false;
        public bool ShowFur = false;
    }
    
    public class XSToonInspector : ShaderGUI
    {
        protected static Dictionary<Material, FoldoutToggles> Foldouts = new Dictionary<Material, FoldoutToggles>();
        protected static MaterialInspector Inspector = new MaterialInspector();
        
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            Material material = materialEditor.target as Material;
            SetupFoldouts(material);
            Inspector.DoMaterialSettings(material, ref props);
            
            EditorGUI.BeginChangeCheck();
            XSStyles.ShurikenHeaderCentered($"XSToon v{XSStyles.ver}");
            materialEditor.ShaderProperty(Inspector.MaterialProperties._AdvMode, new GUIContent("Shader Mode", "Setting this to 'Advanced' will give you access to things such as stenciling, and other expiremental/advanced features."));
            materialEditor.ShaderProperty(Inspector.MaterialProperties._Culling, new GUIContent("Culling Mode", "Changes the culling mode. 'Off' will result in a two sided material, while 'Front' and 'Back' will cull those sides respectively"));
            materialEditor.ShaderProperty(Inspector.MaterialProperties._TilingMode, new GUIContent("Tiling Mode", "Setting this to Merged will tile and offset all textures based on the Main texture's Tiling/Offset."));
            materialEditor.ShaderProperty(Inspector.MaterialProperties._BlendMode, new GUIContent("Blend Mode", "Blend mode of the material. (Opaque, transparent, cutout, etc.)"));

            if (!Inspector.HasTypeFlag(Enums.ShaderTypeFlags.Fur))
            {
                DoBlendModeSettings(material);
            }
            else
            {
                SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                    (int) UnityEngine.Rendering.BlendMode.Zero,
                    (int) UnityEngine.Rendering.RenderQueue.AlphaTest, 1, 1);
                material.EnableKeyword("_ALPHABLEND_ON");
                material.EnableKeyword("_ALPHATEST_ON");
            }

            DrawMainSettings(materialEditor, material);
            DrawShadowSettings(materialEditor, material);
            DrawFurSettings(materialEditor, material);
            DrawDissolveSettings(materialEditor, material);
            DrawUvDiscardSettings(materialEditor, material);
            DrawOutlineSettings(materialEditor, material);
            DrawNormalSettings(materialEditor, material);
            DrawSpecularSettings(materialEditor, material);
            DrawReflectionsSettings(materialEditor, material);
            DrawEmissionSettings(materialEditor, material);
            DrawRimlightSettings(materialEditor, material);
            DrawHalfToneSettings(materialEditor, material);
            DrawTransmissionSettings(materialEditor, material);

            PluginGUI(materialEditor, material);

            DrawAdvancedSettings(materialEditor, material);
            DrawEyeTrackingSettings(materialEditor, material);

            //!RDPSFunctionCallInject

            XSStyles.DoFooter();
        }

        public virtual void PluginGUI(MaterialEditor materialEditor, Material material) {
        }

        private void SetupFoldouts(Material material)
        {
            if (Foldouts.ContainsKey(material))
                return;

            FoldoutToggles toggles = new FoldoutToggles();
            Foldouts.Add(material, toggles);
        }
        
        private void DoBlendModeSettings(Material material)
        {
            if (Inspector.OverrideRenderSettings)
                return;

            switch (Inspector.BlendMode)
            {
                case Enums.AlphaMode.Opaque:
                    material.SetInt("_Mode", (int)Enums.ShaderBlendMode.Opaque);
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.Zero,
                        (int) UnityEngine.Rendering.RenderQueue.Geometry, 1, 0);
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHATEST_ON");
                    break;

                case Enums.AlphaMode.Cutout:
                    material.SetInt("_Mode", (int)Enums.ShaderBlendMode.Cutout);
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.Zero,
                        (int) UnityEngine.Rendering.RenderQueue.AlphaTest, 1, 0);
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.EnableKeyword("_ALPHATEST_ON");
                    break;

                case Enums.AlphaMode.Dithered:
                    material.SetInt("_Mode", (int)Enums.ShaderBlendMode.Cutout);
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.Zero,
                        (int) UnityEngine.Rendering.RenderQueue.AlphaTest, 1, 0);
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.EnableKeyword("_ALPHATEST_ON");
                    break;

                case Enums.AlphaMode.AlphaToCoverage:
                    material.SetInt("_Mode", (int)Enums.ShaderBlendMode.Cutout);
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.Zero,
                        (int) UnityEngine.Rendering.RenderQueue.AlphaTest, 1, 1);
                    material.EnableKeyword("_ALPHABLEND_ON");
                    material.EnableKeyword("_ALPHATEST_ON");
                    break;

                case Enums.AlphaMode.Transparent:
                    material.SetInt("_Mode", (int)Enums.ShaderBlendMode.Transparent);
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha,
                        (int) UnityEngine.Rendering.RenderQueue.Transparent, 0, 0);
                    material.EnableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHATEST_ON");
                    break;

                case Enums.AlphaMode.Fade:
                    material.SetInt("_Mode", (int)Enums.ShaderBlendMode.Fade);
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.SrcAlpha,
                        (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha,
                        (int) UnityEngine.Rendering.RenderQueue.Transparent, 0, 0);
                    material.EnableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHATEST_ON");
                    break;

                case Enums.AlphaMode.Additive:
                    material.SetInt("_Mode", (int)Enums.ShaderBlendMode.Transparent);
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.RenderQueue.Transparent, 0, 0);
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHATEST_ON");
                    break;
            }
        }

        private void SetBlend(Material material, int src, int dst, int renderQueue, int zwrite, int alphatocoverage)
        {
            material.SetInt("_SrcBlend", src);
            material.SetInt("_DstBlend", dst);
            material.SetInt("_ZWrite", zwrite);
            material.SetInt("_AlphaToMask", alphatocoverage);
            material.renderQueue = renderQueue;
        }

        private void DrawMainSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowMain = XSStyles.ShurikenFoldout("Main Settings", Foldouts[material].ShowMain);
            if (Foldouts[material].ShowMain)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("Main Texture", "The main Albedo texture."), Inspector.MaterialProperties._MainTex, Inspector.MaterialProperties._Color);
                if (Inspector.HasTypeFlag(Enums.ShaderTypeFlags.Cutout))
                {
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._Cutoff, new GUIContent("Cutoff", "The Cutoff Amount"), 2);
                }
                materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetAlbedo, new GUIContent("UV Set", "The UV set to use for the Albedo Texture."), 2);
                materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._MainTex);

                materialEditor.TexturePropertySingleLine(new GUIContent("HSV Mask", "RGB Mask: R = Hue,  G = Saturation, B = Brightness"), Inspector.MaterialProperties._HSVMask);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._Hue, new GUIContent("Hue", "Controls Hue of the final output from the shader."));
                materialEditor.ShaderProperty(Inspector.MaterialProperties._Saturation, new GUIContent("Saturation", "Controls saturation of the final output from the shader."));
                materialEditor.ShaderProperty(Inspector.MaterialProperties._Value, new GUIContent("Brightness", "Controls value of the final output from the shader."));

                if (Inspector.HasTypeFlag(Enums.ShaderTypeFlags.Dithered))
                {
                    XSStyles.SeparatorThin();
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._FadeDither, new GUIContent("Distance Fading", "Make the shader dither out based on the distance to the camera."));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._FadeDitherDistance, new GUIContent("Fade Threshold", "The distance at which the fading starts happening."));
                }
            }
        }

        private void DrawDissolveSettings(MaterialEditor materialEditor, Material material)
        {
            if (Inspector.ShaderSupportsClipping(material))
            {
                Foldouts[material].ShowDissolve = XSStyles.ShurikenFoldout("Dissolve", Foldouts[material].ShowDissolve);
                if (Foldouts[material].ShowDissolve)
                {
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._DissolveCoordinates, new GUIContent("Dissolve Coordinates", "Should Dissolve happen in world space, texture space, or vertically?"));
                    materialEditor.TexturePropertySingleLine(new GUIContent("Dissolve Texture", "Noise texture used to control up dissolve pattern"), Inspector.MaterialProperties._DissolveTexture, Inspector.MaterialProperties._DissolveColor);
                    materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._DissolveTexture);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetDissolve, new GUIContent("UV Set", "The UV set to use for the Dissolve Texture."), 2);


                    materialEditor.ShaderProperty(Inspector.MaterialProperties._DissolveBlendPower, new GUIContent("Layer Blend", "How much to boost the blended layers"));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._DissolveLayer1Scale, new GUIContent("Layer 1 Scale", "How much tiling to apply to the layer."));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._DissolveLayer1Speed, new GUIContent("Layer 1 Speed", "Scroll Speed of the layer, can be negative."));

                    materialEditor.ShaderProperty(Inspector.MaterialProperties._DissolveLayer2Scale, new GUIContent("Layer 2 Scale", "How much tiling to apply to the layer."));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._DissolveLayer2Speed, new GUIContent("Layer 2 Speed", "Scroll Speed of the layer, can be negative."));

                    materialEditor.ShaderProperty(Inspector.MaterialProperties._DissolveStrength, new GUIContent("Dissolve Sharpness", "Sharpness of the dissolve texture."));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._DissolveProgress, new GUIContent("Dissolve Progress", "Progress of the dissolve effect."));
                }
            }
        }

        private void DrawShadowSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowShadows = XSStyles.ShurikenFoldout("Shadows", Foldouts[material].ShowShadows);
            if (Foldouts[material].ShowShadows)
            {
                materialEditor.ShaderProperty(Inspector.MaterialProperties._UseShadowMapTexture, new GUIContent("Use Shadow Control Map", "Use Shadow Map texture for shadows. (Mainly used for faces. Reference Genshin Impact for style.)"));
                bool useShadowMapTexture = material.GetInt("_UseShadowMapTexture") > 0;

                if (useShadowMapTexture)
                {
                    materialEditor.TexturePropertySingleLine(
                        new GUIContent("Shadow Control Map", "Shadow Control Texture, black to white, uses alpha to blend between shadowmap shading and normal based shading. Shadow texture should be in the style of Genshin Impact. (Mainly used for faces.)\n\n Note: Head Mesh must be separate from the rest of the body for this to work correctly."), 
                        Inspector.MaterialProperties._ShadowControlTexture
                    );
                }
                XSStyles.SeparatorThin();
                
                GUILayout.BeginHorizontal();
                materialEditor.TexturePropertySingleLine(new GUIContent("Shadow Ramp", "Shadow Ramp, Dark to Light should be Left to Right"), Inspector.MaterialProperties._Ramp);
                XSStyles.CallGradientEditor(material);
                GUILayout.EndHorizontal();
                
                materialEditor.TexturePropertySingleLine(
                    new GUIContent("Ramp Selection Mask", "A black to white mask that determins how far up on the multi ramp to sample. 0 for bottom, 1 for top, 0.5 for middle, 0.25, and 0.75 for mid bottom and mid top respectively."), 
                    Inspector.MaterialProperties._RampSelectionMask
                );

                XSStyles.SeparatorThin();
                if (Inspector.MaterialProperties._RampSelectionMask.textureValue != null)
                {
                    string rampMaskPath = AssetDatabase.GetAssetPath(Inspector.MaterialProperties._RampSelectionMask.textureValue);
                    TextureImporter ti = (TextureImporter)TextureImporter.GetAtPath(rampMaskPath);
                    if (ti.sRGBTexture)
                    {
                        if (XSStyles.HelpBoxWithButton(new GUIContent("This texture is not marked as Linear.", "This is recommended for the mask"), new GUIContent("Fix Now")))
                        {
                            ti.sRGBTexture = false;
                            AssetDatabase.ImportAsset(rampMaskPath, ImportAssetOptions.ForceUpdate);
                            AssetDatabase.Refresh();
                        }
                    }
                }

                materialEditor.ShaderProperty(Inspector.MaterialProperties._ShadowSharpness, new GUIContent("Shadow Sharpness", "Controls the sharpness of recieved shadows, as well as the sharpness of 'shadows' from Vertex Lighting."));

                XSStyles.SeparatorThin();
                materialEditor.ShaderProperty(Inspector.MaterialProperties._OcclusionMode, new GUIContent("Occlusion Mode", "How to calculate the occlusion map contribution"));
                materialEditor.TexturePropertySingleLine(new GUIContent("Occlusion Map", "Occlusion Map, used to darken areas on the model artifically."), Inspector.MaterialProperties._OcclusionMap);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._OcclusionIntensity, new GUIContent("Intensity", "Occlusion intensity"), 2);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetOcclusion, new GUIContent("UV Set", "The UV set to use for the Occlusion Texture"), 2);
                materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._OcclusionMap);
            }
        }

        private void DrawOutlineSettings(MaterialEditor materialEditor, Material material)
        {
            if (Inspector.HasTypeFlag(Enums.ShaderTypeFlags.Outlined))
            {
                Foldouts[material].ShowOutlines = XSStyles.ShurikenFoldout("Outlines", Foldouts[material].ShowOutlines);
                if (Foldouts[material].ShowOutlines)
                {
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._OutlineNormalMode, new GUIContent("Outline Normal Mode", "How to calcuate the outline expand direction. Using mesh normals may result in split edges."));

                    Enums.OutlineNormalMode outlineNormalMode = (Enums.OutlineNormalMode)Inspector.MaterialProperties._OutlineNormalMode.floatValue;
                    if (outlineNormalMode == Enums.OutlineNormalMode.UVChannel) // TODO:: Clean this into an enum
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._OutlineUVSelect, new GUIContent("Normals UV", "UV Channel to pull the modified normals from for outlines."));

                    materialEditor.ShaderProperty(Inspector.MaterialProperties._OutlineLighting, new GUIContent("Outline Lighting", "Makes outlines respect the lighting, or be emissive."));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._OutlineAlbedoTint, new GUIContent("Outline Albedo Tint", "Includes the color of the Albedo Texture in the calculation for the color of the outline."));
                    materialEditor.TexturePropertySingleLine(new GUIContent("Outline Mask", "Outline width mask, black will make the outline minimum width."), Inspector.MaterialProperties._OutlineMask);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._OutlineWidth, new GUIContent("Outline Width", "Width of the Outlines"));
                    XSStyles.constrainedShaderProperty(materialEditor, Inspector.MaterialProperties._OutlineColor, new GUIContent("Outline Color", "Color of the outlines"), 0);
                }
            }
        }

        private void DrawNormalSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowNormal = XSStyles.ShurikenFoldout("Normal Maps", Foldouts[material].ShowNormal);
            if (Foldouts[material].ShowNormal)
            {
                materialEditor.ShaderProperty(Inspector.MaterialProperties._NormalMapMode, new GUIContent("Normal Map Source", "How to alter the normals of the mesh, using which source?"));
                
                Enums.NormalMapMode normalMapMode = (Enums.NormalMapMode)Inspector.MaterialProperties._NormalMapMode.floatValue;
                if (normalMapMode == Enums.NormalMapMode.Texture)
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map", "Normal Map"), Inspector.MaterialProperties._BumpMap);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._BumpScale, new GUIContent("Normal Strength", "Strength of the main Normal Map"), 2);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetNormal, new GUIContent("UV Set", "The UV set to use for the Normal Map"), 2);
                    materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._BumpMap);

                    XSStyles.SeparatorThin();
                    materialEditor.TexturePropertySingleLine(new GUIContent("Detail Normal Map", "Detail Normal Map"), Inspector.MaterialProperties._DetailNormalMap);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._DetailNormalMapScale, new GUIContent("Detail Normal Strength", "Strength of the detail Normal Map"), 2);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetDetNormal, new GUIContent("UV Set", "The UV set to use for the Detail Normal Map"), 2);
                    materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._DetailNormalMap);

                    XSStyles.SeparatorThin();
                    materialEditor.TexturePropertySingleLine(new GUIContent("Detail Mask", "Mask for Detail Maps"), Inspector.MaterialProperties._DetailMask);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetDetMask, new GUIContent("UV Set", "The UV set to use for the Detail Mask"), 2);
                    materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._DetailMask);
                }
            }
        }

        private void DrawSpecularSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowSpecular = XSStyles.ShurikenFoldout("Direct Reflections", Foldouts[material].ShowSpecular);
            if (Foldouts[material].ShowSpecular)
            {
                materialEditor.TexturePropertySingleLine(
                    new GUIContent("Reflection Mask (R,G,B)", "Reflection Mask. \n\nRed = Intensity, \nGreen = Albedo Tint, \nBlue = Smoothness"), 
                    Inspector.MaterialProperties._SpecularMap
                );
                materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._SpecularMap);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetSpecular, new GUIContent("UV Set", "The UV set to use for the Specular Map"), 2);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._SpecularIntensity, new GUIContent("Intensity", "Specular Intensity."), 2);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._SpecularArea, new GUIContent("Roughness", "Roughness"), 2);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._SpecularAlbedoTint, new GUIContent("Albedo Tint", "How much the specular highlight should derive color from the albedo of the object."), 2);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._SpecularSharpness, new GUIContent("Sharpness", "How hard of and edge transitions should the specular have?"), 2);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._AnisotropicSpecular, new GUIContent("Anisotropy", "The amount of anisotropy the surface has - this will stretch the reflection along an axis (think bottom of a frying pan)"), 2);
            }
        }

        private void DrawReflectionsSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowReflection = XSStyles.ShurikenFoldout("Indirect Reflections", Foldouts[material].ShowReflection);
            if (Foldouts[material].ShowReflection)
            {
                materialEditor.ShaderProperty(Inspector.MaterialProperties._ReflectionMode, new GUIContent("Reflection Mode", "Reflection Mode."));

                Enums.ReflectionMode reflectionMode = (Enums.ReflectionMode)Inspector.MaterialProperties._ReflectionMode.floatValue;
                switch (reflectionMode)
                {
                    case Enums.ReflectionMode.PBR:
                    {
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._ReflectionBlendMode, new GUIContent("Reflection Blend Mode", "Blend mode for reflection. Additive is Color + reflection, Multiply is Color * reflection, and subtractive is Color - reflection"));
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._ClearCoat, new GUIContent("Clearcoat", "Clearcoat"));

                        XSStyles.SeparatorThin();
                        materialEditor.TexturePropertySingleLine(new GUIContent("Fallback Cubemap", " Used as fallback in 'Unity' reflection mode if reflection probe is black."), Inspector.MaterialProperties._BakedCubemap);

                        XSStyles.SeparatorThin();
                        materialEditor.TexturePropertySingleLine(new GUIContent("Metallic Map", "Metallic Map, Metallic on Red Channel, Smoothness on Alpha Channel. \nIf Clearcoat is enabled, Clearcoat Smoothness on Green Channel, Clearcoat Reflectivity on Blue Channel."), Inspector.MaterialProperties._MetallicGlossMap);
                        materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._MetallicGlossMap);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetMetallic, new GUIContent("UV Set", "The UV set to use for the Metallic Smoothness Map"), 2);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._AnisotropicReflection, new GUIContent("Anisotropy", "The amount of anisotropy the surface has - this will stretch the reflection along an axis (think bottom of a frying pan)"), 2);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._Metallic, new GUIContent("Metallic", "Metallic, set to 1 if using metallic map"), 2);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._Glossiness, new GUIContent("Smoothness", "Smoothness, set to 1 if using metallic map"), 2);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._ClearcoatSmoothness, new GUIContent("Clearcoat Smoothness", "Smoothness of the clearcoat."), 2);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._ClearcoatStrength, new GUIContent("Clearcoat Reflectivity", "The strength of the clearcoat reflection."), 2);
                        break;
                    }
                    
                    case Enums.ReflectionMode.BakedCube:
                    {
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._ReflectionBlendMode, new GUIContent("Reflection Blend Mode", "Blend mode for reflection. Additive is Color + reflection, Multiply is Color * reflection, and subtractive is Color - reflection"));
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._ClearCoat, new GUIContent("Clearcoat", "Clearcoat"));

                        XSStyles.SeparatorThin();
                        materialEditor.TexturePropertySingleLine(new GUIContent("Baked Cubemap", "Baked cubemap."), Inspector.MaterialProperties._BakedCubemap);

                        XSStyles.SeparatorThin();
                        materialEditor.TexturePropertySingleLine(new GUIContent("Metallic Map", "Metallic Map, Metallic on Red Channel, Smoothness on Alpha Channel. \nIf Clearcoat is enabled, Clearcoat Smoothness on Green Channel, Clearcoat Reflectivity on Blue Channel."), Inspector.MaterialProperties._MetallicGlossMap);
                        materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._MetallicGlossMap);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetMetallic, new GUIContent("UV Set", "The UV set to use for the MetallicSmoothness Map"), 2);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._AnisotropicReflection, new GUIContent("Anisotropic", "Anisotropic, stretches reflection in an axis."), 2);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._Metallic, new GUIContent("Metallic", "Metallic, set to 1 if using metallic map"), 2);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._Glossiness, new GUIContent("Smoothness", "Smoothness, set to 1 if using metallic map"), 2);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._ClearcoatSmoothness, new GUIContent("Clearcoat Smoothness", "Smoothness of the clearcoat."), 2);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._ClearcoatStrength, new GUIContent("Clearcoat Reflectivity", "The strength of the clearcoat reflection."), 2);
                        break;
                    }
                    
                    case Enums.ReflectionMode.Matcap:
                    {
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._ReflectionBlendMode, new GUIContent("Reflection Blend Mode", "Blend mode for reflection. Additive is Color + reflection, Multiply is Color * reflection, and subtractive is Color - reflection"));

                        XSStyles.SeparatorThin();
                        materialEditor.TexturePropertySingleLine(new GUIContent("Matcap", "Matcap Texture"), Inspector.MaterialProperties._Matcap, Inspector.MaterialProperties._MatcapTint);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._Glossiness, new GUIContent("Matcap Blur", "Matcap blur, blurs the Matcap, set to 1 for full clarity"), 2);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._MatcapTintToDiffuse, new GUIContent("Tint To Diffuse", "Tints matcap to diffuse color."), 2);
                        material.SetFloat("_Metallic", 0);
                        material.SetFloat("_ClearCoat", 0);
                        material.SetTexture("_MetallicGlossMap", null);
                        break;
                    }
                }
                
                if (reflectionMode != Enums.ReflectionMode.Matcap)
                {
                    XSStyles.SeparatorThin();
                    materialEditor.TexturePropertySingleLine(new GUIContent("Reflectivity Mask", "Mask for reflections."), Inspector.MaterialProperties._ReflectivityMask);
                    materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._ReflectivityMask);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetReflectivity, new GUIContent("UV Set", "The UV set to use for the Reflectivity Mask"), 2);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._Reflectivity, new GUIContent("Reflectivity", "The strength of the reflections."), 2);
                }
            }
        }

        private void DrawEmissionSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowEmission = XSStyles.ShurikenFoldout("Emission", Foldouts[material].ShowEmission);
            if (Foldouts[material].ShowEmission)
            {
                bool isAudioLink = material.GetInt("_EmissionAudioLinkChannel") > 0;
                bool isPackedMapLink = material.GetInt("_EmissionAudioLinkChannel") == 5;
                bool isUVBased = material.GetInt("_EmissionAudioLinkChannel") == 6;
                materialEditor.ShaderProperty(Inspector.MaterialProperties._EmissionAudioLinkChannel, new GUIContent("Emission Audio Link", "Use Audio Link for Emission Brightness"));

                if (!isPackedMapLink)
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Emission Map", "Emissive map. White to black, unless you want multiple colors."), Inspector.MaterialProperties._EmissionMap, Inspector.MaterialProperties._EmissionColor);
                    materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._EmissionMap);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetEmission, new GUIContent("UV Set", "The UV set to use for the Emission Map"), 2);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._EmissionToDiffuse, new GUIContent("Tint To Diffuse", "Tints the emission to the Diffuse Color"), 2);
                    if (isUVBased) {
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._ALUVWidth, new GUIContent("History Sample Amount", "Controls the amount of Audio Link history to sample."));
                    }
                }
                else
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Emission Map (VRC Audio Link Packed)", "Emissive map. Each channel controls different audio link reactions. RGB = Lows, Mids, Highs, Alpha Channel can be used to have extra masking as a way to combat aliasing"), Inspector.MaterialProperties._EmissionMap);
                    materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._EmissionMap);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetEmission, new GUIContent("UV Set", "The UV set to use for the Emission Map"), 2);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._EmissionToDiffuse, new GUIContent("Tint To Diffuse", "Tints the emission to the Diffuse Color"), 2);

                    XSStyles.SeparatorThin();

                    materialEditor.ColorProperty(Inspector.MaterialProperties._EmissionColor, "Red Ch. Color (Lows)");
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._ALGradientOnRed, new GUIContent("Gradient Bar", "Uses a gradient on this channel to create an animated bar from the audio link data."), 1);

                    materialEditor.ColorProperty(Inspector.MaterialProperties._EmissionColor0, "Green Ch. Color (Mids)");
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._ALGradientOnGreen, new GUIContent("Gradient Bar", "Uses a gradient on this channel to create an animated bar from the audio link data."), 1);

                    materialEditor.ColorProperty(Inspector.MaterialProperties._EmissionColor1, "Blue Ch. Color (Highs)");
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._ALGradientOnBlue, new GUIContent("Gradient Bar", "Uses a gradient on this channel to create an animated bar from the audio link data."), 1);
                }

                XSStyles.SeparatorThin();
                materialEditor.ShaderProperty(Inspector.MaterialProperties._ScaleWithLight, new GUIContent("Scale w/ Light", "Scales the emission intensity based on how dark or bright the environment is."));
                if (Inspector.MaterialProperties._ScaleWithLight.floatValue == 0)
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._ScaleWithLightSensitivity, new GUIContent("Scaling Sensitivity", "How agressively the emission should scale with the light."));
            }
        }

        private void DrawRimlightSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowRimlight = XSStyles.ShurikenFoldout("Rim Light & Shadow", Foldouts[material].ShowRimlight);
            if (Foldouts[material].ShowRimlight)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("Rim Mask (Packed)", "Channels are used to mask out rim light and rim shadow effects. \n\n Red Channel: Rim Light Mask \n Green Channel: Rim Shadow Mask"), Inspector.MaterialProperties._RimMask);
                materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._RimMask);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetRimMask, new GUIContent("UV Set", "The UV set to use for the Rim Mask"), 2);

                XSStyles.SeparatorThin();
                materialEditor.ShaderProperty(Inspector.MaterialProperties._RimColor, new GUIContent("Rimlight Tint", "The Tint of the Rimlight."));
                materialEditor.ShaderProperty(Inspector.MaterialProperties._RimAlbedoTint, new GUIContent("Rim Albedo Tint", "How much the Albedo texture should effect the rimlight color."));
                materialEditor.ShaderProperty(Inspector.MaterialProperties._RimCubemapTint, new GUIContent("Rim Environment Tint", "How much the Environment cubemap should effect the rimlight color."));
                materialEditor.ShaderProperty(Inspector.MaterialProperties._RimAttenEffect, new GUIContent("Rim Attenuation Effect", "How much should realtime shadows mask out the rimlight?"));
                materialEditor.ShaderProperty(Inspector.MaterialProperties._RimIntensity, new GUIContent("Rimlight Intensity", "Strength of the Rimlight."));
                materialEditor.ShaderProperty(Inspector.MaterialProperties._RimRange, new GUIContent("Range", "Range of the Rim"), 2);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._RimThreshold, new GUIContent("Threshold", "Threshold of the Rim"), 2);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._RimSharpness, new GUIContent("Sharpness", "Sharpness of the Rim"), 2);

                XSStyles.SeparatorThin();
                XSStyles.constrainedShaderProperty(materialEditor, Inspector.MaterialProperties._ShadowRim, new GUIContent("Shadow Rim", "Shadow Rim Color. Set to white to disable."), 0);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._ShadowRimAlbedoTint, new GUIContent("Shadow Rim Albedo Tint", "How much the Albedo texture should effect the Shadow Rim color."));
                materialEditor.ShaderProperty(Inspector.MaterialProperties._ShadowRimRange, new GUIContent("Range", "Range of the Shadow Rim"), 2);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._ShadowRimThreshold, new GUIContent("Threshold", "Threshold of the Shadow Rim"), 2);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._ShadowRimSharpness, new GUIContent("Sharpness", "Sharpness of the Shadow Rim"), 2);
            }
        }

        private void DrawHalfToneSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowHalftones = XSStyles.ShurikenFoldout("Halftones", Foldouts[material].ShowHalftones);
            if (Foldouts[material].ShowHalftones)
            {
                materialEditor.ShaderProperty(Inspector.MaterialProperties._HalftoneType, new GUIContent("Halftone Style", "Controls where halftone and stippling effects are drawn."));
                
                Enums.HalftoneType halftoneType = (Enums.HalftoneType)Inspector.MaterialProperties._HalftoneType.floatValue;
                switch (halftoneType)
                {
                    case Enums.HalftoneType.Shadows:
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._HalftoneLineAmount, new GUIContent("Halftone Line Count", "How many lines should the halftone shadows have?"));
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._HalftoneLineIntensity, new GUIContent("Halftone Line Intensity", "How dark should the halftone lines be?"));
                        break;
                    
                    case Enums.HalftoneType.Highlights:
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._HalftoneDotSize, new GUIContent("Stippling Scale", "How large should the stippling pattern be?"));
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._HalftoneDotAmount, new GUIContent("Stippling Density", "How dense is the stippling effect?"));
                        break;
                    
                    case Enums.HalftoneType.ShadowsAndHighlights:
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._HalftoneLineAmount, new GUIContent("Halftone Line Count", "How many lines should the halftone shadows have?"));
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._HalftoneLineIntensity, new GUIContent("Halftone Line Intensity", "How dark should the halftone lines be?"));
                        
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._HalftoneDotSize, new GUIContent("Stippling Scale", "How large should the stippling pattern be?"));
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._HalftoneDotAmount, new GUIContent("Stippling Density", "How dense is the stippling effect?"));
                        break;
                }
            }
        }

        private void DrawTransmissionSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowSubsurface = XSStyles.ShurikenFoldout("Transmission", Foldouts[material].ShowSubsurface);
            if (Foldouts[material].ShowSubsurface)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("Thickness Map", "Thickness Map, used to mask areas where transmission can happen"), Inspector.MaterialProperties._ThicknessMap);
                materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._ThicknessMap);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetThickness, new GUIContent("UV Set", "The UV set to use for the Thickness Map"), 2);
                XSStyles.constrainedShaderProperty(materialEditor, Inspector.MaterialProperties._SSColor, new GUIContent("Transmission Color", "Transmission Color"), 2);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._SSDistortion, new GUIContent("Transmission Distortion", "How much the Transmission should follow the normals of the mesh and/or normal map."), 2);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._SSPower, new GUIContent("Transmission Power", "Subsurface Power"), 2);
                materialEditor.ShaderProperty(Inspector.MaterialProperties._SSScale, new GUIContent("Transmission Scale", "Subsurface Scale"), 2);
            }
        }

        private void DrawUvDiscardSettings(MaterialEditor materialEditor, Material material)
        {
            if (Inspector.BlendMode == (int)Enums.AlphaMode.Opaque)
            {
                // TODO:: Refactor this into an enum.
                if(material.GetInt("_UVDiscardMode") == 2)
                {
                    material.SetInt("_UVDiscardMode", 1);
                }
            }
            
            Foldouts[material].ShowUvDiscard = XSStyles.ShurikenFoldout("UV Tile Discard", Foldouts[material].ShowUvDiscard);
            if (Foldouts[material].ShowUvDiscard)
            {
                Inspector.DiscardTile0 = material.GetInt("_DiscardTile0") > 0.5f;
                Inspector.DiscardTile1 = material.GetInt("_DiscardTile1") > 0.5f;
                Inspector.DiscardTile2 = material.GetInt("_DiscardTile2") > 0.5f;
                Inspector.DiscardTile3 = material.GetInt("_DiscardTile3") > 0.5f;
                Inspector.DiscardTile4 = material.GetInt("_DiscardTile4") > 0.5f;
                Inspector.DiscardTile5 = material.GetInt("_DiscardTile5") > 0.5f;
                Inspector.DiscardTile6 = material.GetInt("_DiscardTile6") > 0.5f;
                Inspector.DiscardTile7 = material.GetInt("_DiscardTile7") > 0.5f;
                Inspector.DiscardTile8 = material.GetInt("_DiscardTile8") > 0.5f;
                Inspector.DiscardTile9 = material.GetInt("_DiscardTile9") > 0.5f;
                Inspector.DiscardTile10 = material.GetInt("_DiscardTile10") > 0.5f;
                Inspector.DiscardTile11 = material.GetInt("_DiscardTile11") > 0.5f;
                Inspector.DiscardTile12 = material.GetInt("_DiscardTile12") > 0.5f;
                Inspector.DiscardTile13 = material.GetInt("_DiscardTile13") > 0.5f;
                Inspector.DiscardTile14 = material.GetInt("_DiscardTile14") > 0.5f;
                Inspector.DiscardTile15 = material.GetInt("_DiscardTile15") > 0.5f;

                if (Inspector.BlendMode != (int)Enums.AlphaMode.Opaque)
                {
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._UVDiscardMode,
                        new GUIContent("UV Discard Mode",
                            "How to discard pixels based on UV tile. It's recommended to use Vertex for performance reasons."));
                }

                materialEditor.ShaderProperty(Inspector.MaterialProperties._UVDiscardChannel, new GUIContent("Channel", "Discard pixels based on UV tile."));
                
                GUILayout.Space(16);
                XSStyles.DoHeaderLeft("Discard Tiles");

                GUILayout.BeginHorizontal(GUILayout.MaxWidth(80));
                Inspector.DiscardTile12 = EditorGUILayout.Toggle(Inspector.DiscardTile12);
                Inspector.DiscardTile13 = EditorGUILayout.Toggle(Inspector.DiscardTile13);
                Inspector.DiscardTile14 = EditorGUILayout.Toggle(Inspector.DiscardTile14);
                Inspector.DiscardTile15 = EditorGUILayout.Toggle(Inspector.DiscardTile15);
                GUILayout.EndHorizontal();
                
                GUILayout.BeginHorizontal(GUILayout.MaxWidth(80));
                Inspector.DiscardTile8 = EditorGUILayout.Toggle(Inspector.DiscardTile8);
                Inspector.DiscardTile9 = EditorGUILayout.Toggle(Inspector.DiscardTile9);
                Inspector.DiscardTile10 = EditorGUILayout.Toggle(Inspector.DiscardTile10);
                Inspector.DiscardTile11 = EditorGUILayout.Toggle(Inspector.DiscardTile11);
                GUILayout.EndHorizontal();

                GUILayout.BeginHorizontal(GUILayout.MaxWidth(80));
                Inspector.DiscardTile4 = EditorGUILayout.Toggle(Inspector.DiscardTile4);
                Inspector.DiscardTile5 = EditorGUILayout.Toggle(Inspector.DiscardTile5);
                Inspector.DiscardTile6 = EditorGUILayout.Toggle(Inspector.DiscardTile6);
                Inspector.DiscardTile7 = EditorGUILayout.Toggle(Inspector.DiscardTile7);
                GUILayout.EndHorizontal();

                GUILayout.BeginHorizontal(GUILayout.MaxWidth(80));
                Inspector.DiscardTile0 = EditorGUILayout.Toggle(Inspector.DiscardTile0);
                Inspector.DiscardTile1 = EditorGUILayout.Toggle(Inspector.DiscardTile1);
                Inspector.DiscardTile2 = EditorGUILayout.Toggle(Inspector.DiscardTile2);
                Inspector.DiscardTile3 = EditorGUILayout.Toggle(Inspector.DiscardTile3);
                GUILayout.EndHorizontal();


                material.SetInt("_DiscardTile0", Inspector.DiscardTile0 ? 1 : 0);
                material.SetInt("_DiscardTile1", Inspector.DiscardTile1 ? 1 : 0);
                material.SetInt("_DiscardTile2", Inspector.DiscardTile2 ? 1 : 0);
                material.SetInt("_DiscardTile3", Inspector.DiscardTile3 ? 1 : 0);
                material.SetInt("_DiscardTile4", Inspector.DiscardTile4 ? 1 : 0);
                material.SetInt("_DiscardTile5", Inspector.DiscardTile5 ? 1 : 0);
                material.SetInt("_DiscardTile6", Inspector.DiscardTile6 ? 1 : 0);
                material.SetInt("_DiscardTile7", Inspector.DiscardTile7 ? 1 : 0);
                material.SetInt("_DiscardTile8", Inspector.DiscardTile8 ? 1 : 0);
                material.SetInt("_DiscardTile9", Inspector.DiscardTile9 ? 1 : 0);
                material.SetInt("_DiscardTile10", Inspector.DiscardTile10 ? 1 : 0);
                material.SetInt("_DiscardTile11", Inspector.DiscardTile11 ? 1 : 0);
                material.SetInt("_DiscardTile12", Inspector.DiscardTile12 ? 1 : 0);
                material.SetInt("_DiscardTile13", Inspector.DiscardTile13 ? 1 : 0);
                material.SetInt("_DiscardTile14", Inspector.DiscardTile14 ? 1 : 0);
                material.SetInt("_DiscardTile15", Inspector.DiscardTile15 ? 1 : 0);
            }
        }

        private void DrawAdvancedSettings(MaterialEditor materialEditor, Material material)
        {
            Enums.ShaderMode shaderMode = (Enums.ShaderMode)Inspector.MaterialProperties._AdvMode.floatValue;
            if (shaderMode == Enums.ShaderMode.Advanced)
            {
                Foldouts[material].ShowAdvanced = XSStyles.ShurikenFoldout("Advanced Settings", Foldouts[material].ShowAdvanced);
                if (Foldouts[material].ShowAdvanced)
                {
                    if (Inspector.ShaderSupportsClipping(material))
                    {
                        //XSStyles.CallTexArrayManager();
                        materialEditor.TexturePropertySingleLine(new GUIContent("Clip Map (RGB)", "Texture used to control clipping based on the Clip Index parameter."), Inspector.MaterialProperties._ClipMask);
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._UseClipsForDissolve, new GUIContent("Use For Dissolve"), 2);

                        materialEditor.ShaderProperty(Inspector.MaterialProperties._UVSetClipMap, new GUIContent("UV Set", "The UV set to use for the Clip Map"), 2);

                        XSStyles.DoHeaderLeft("Clip Against");
                        materialEditor.ShaderProperty(Inspector.MaterialProperties._ClipIndex, new GUIContent("Clip Index", "Should be unique per material, controls which set of slider values to use for clipping. Can be 0 - 8(materials), with 8 masks in each texture, for a total of 64 unique masks."), 1);
                        XSStyles.SeparatorThin();
                        int materialClipIndex = material.GetInt("_ClipIndex");
                        switch (materialClipIndex)
                        {
                            case 0: 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider00, "Red", "Green", "Blue", "White"); 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider01, "Cyan", "Yellow", "Magenta", "Black");
                                break;
                            case 1: 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider02, "Red", "Green", "Blue", "White"); 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider03, "Cyan", "Yellow", "Magenta", "Black");
                                break;
                            case 2: 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider04, "Red", "Green", "Blue", "White"); 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider05, "Cyan", "Yellow", "Magenta", "Black");
                                break;
                            case 3: 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider06, "Red", "Green", "Blue", "White"); 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider07, "Cyan", "Yellow", "Magenta", "Black");
                                break;
                            case 4: 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider08, "Red", "Green", "Blue", "White"); 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider09, "Cyan", "Yellow", "Magenta", "Black");
                                break;
                            case 5: 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider10, "Red", "Green", "Blue", "White"); 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider11, "Cyan", "Yellow", "Magenta", "Black");
                                break;
                            case 6: 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider12, "Red", "Green", "Blue", "White"); 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider13, "Cyan", "Yellow", "Magenta", "Black");
                                break;
                            case 7: 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider14, "Red", "Green", "Blue", "White"); 
                                DrawVectorSliders(materialEditor, material, Inspector.MaterialProperties._ClipSlider15, "Cyan", "Yellow", "Magenta", "Black");
                                break;
                        }
                    }

                    XSStyles.SeparatorThin();
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._VertexColorAlbedo, new GUIContent("Vertex Color Albedo", "Multiplies the vertex color of the mesh by the Albedo texture to derive the final Albedo color."));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._WireColor, new GUIContent("Wire Color On UV2", "This will only work with a specific second uv channel setup."));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._WireWidth, new GUIContent("Wire Width", "Controls the above wire width."));

                    XSStyles.SeparatorThin();
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._Stencil, Inspector.MaterialProperties._Stencil.displayName);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._StencilComp, Inspector.MaterialProperties._StencilComp.displayName);
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._StencilOp, Inspector.MaterialProperties._StencilOp.displayName);

                    XSStyles.SeparatorThin();
                    Inspector.OverrideRenderSettings = EditorGUILayout.Toggle(new GUIContent("Override Render Settings", "Allows manual control over all render settings (Queue, ZWrite, Etc.)"), Inspector.OverrideRenderSettings);

                    materialEditor.ShaderProperty(Inspector.MaterialProperties._SrcBlend, new GUIContent("SrcBlend", ""));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._DstBlend, new GUIContent("DstBlend", ""));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._ZWrite, new GUIContent("ZWrite", ""));
                    XSStyles.SeparatorThin();
                    materialEditor.RenderQueueField();
                    XSStyles.SeparatorThin();
                    
                    XSStyles.DoHeader(new GUIContent("Debugging"));
                    XSStyles.DoHeaderLeft("Shader Flags:");
                    XSStyles.doLabelLeft($"{Inspector.ShaderType}");
                    XSStyles.SeparatorThin();
                }
            }
        }

        private void DrawEyeTrackingSettings(MaterialEditor materialEditor, Material material)
        {
            if (Inspector.HasTypeFlag(Enums.ShaderTypeFlags.EyeTracking))
            {
                Foldouts[material].ShowEyeTracking = XSStyles.ShurikenFoldout("Eye Tracking Settings", Foldouts[material].ShowEyeTracking);
                if (Foldouts[material].ShowEyeTracking)
                {
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._LeftRightPan, new GUIContent("Left Right Adj.", "Adjusts the eyes manually left or right."));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._UpDownPan, new GUIContent("Up Down Adj.", "Adjusts the eyes manually up or down."));

                    XSStyles.SeparatorThin();
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._AttentionSpan, new GUIContent("Attention Span", "How often should the eyes look at the target; 0 = never, 1 = always, 0.5 = half of the time."));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._FollowPower, new GUIContent("Follow Power", "The influence the target has on the eye"));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._LookSpeed, new GUIContent("Look Speed", "How fast the eye transitions to looking at the target"));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._Twitchyness, new GUIContent("Refocus Frequency", "How much should the eyes look around near the target?"));

                    XSStyles.SeparatorThin();
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._IrisSize, new GUIContent("Iris Size", "Size of the iris"));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._FollowLimit, new GUIContent("Follow Limit", "Limits the angle from the front of the face on how far the eyes can track/rotate."));
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._EyeOffsetLimit, new GUIContent("Offset Limit", "Limit for how far the eyes can turn"));
                }
            }
        }

        private void DrawFurSettings(MaterialEditor materialEditor, Material material)
        {
            if (Inspector.HasTypeFlag(Enums.ShaderTypeFlags.Fur))
            {
                Foldouts[material].ShowFur = XSStyles.ShurikenFoldout("Fur Settings", Foldouts[material].ShowFur);
                if (Foldouts[material].ShowFur)
                {
                    materialEditor.ShaderProperty(Inspector.MaterialProperties._FurMode, new GUIContent("Fur Style", "Fur Style. Shells are good for shorter fur, fins are good for longer fur."));
                    XSStyles.SeparatorThin();
                    
                    Enums.FurType furType = (Enums.FurType)Inspector.MaterialProperties._FurMode.floatValue;
                    switch (furType)
                    {
                        case Enums.FurType.Shell:
                        {
                            material.EnableKeyword("_FUR_SHELL");
                            material.DisableKeyword("_FUR_FIN");
                            
                            materialEditor.TexturePropertySingleLine(new GUIContent("Noise Texture", "Used to control the pattern of the fur strands."), Inspector.MaterialProperties._NoiseTexture);
                            XSStyles.SeparatorThin();

                            materialEditor.TexturePropertySingleLine(new GUIContent("Fur Albedo", "Albedo Texture for the fur coat"), Inspector.MaterialProperties._FurTexture);
                            materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._FurTexture);
                            XSStyles.SeparatorThin();

                            materialEditor.TexturePropertySingleLine(new GUIContent("Length Mask", "Used to control length of the fur."), Inspector.MaterialProperties._FurLengthMask);
                            materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._FurLengthMask);
                            XSStyles.SeparatorThin();

                            materialEditor.ShaderProperty(Inspector.MaterialProperties._TopColor, new GUIContent("Top Color", ""));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._BottomColor, new GUIContent("Bottom Color", ""));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._ColorFalloffMin, new GUIContent("Blend Min", ""));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._ColorFalloffMax, new GUIContent("Blend Max", ""));
                            XSStyles.SeparatorThin();

                            materialEditor.ShaderProperty(Inspector.MaterialProperties._LayerCount, new GUIContent("Layer Count", ""));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._StrandAmount, new GUIContent("Strand Count", ""));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._FurLength, new GUIContent("Length", ""));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._FurWidth, new GUIContent("Strand Width", ""));
                            XSStyles.SeparatorThin();

                            materialEditor.ShaderProperty(Inspector.MaterialProperties._Gravity, new GUIContent("Gravity Strength", ""));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._CombX, new GUIContent("Comb X", ""));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._CombY, new GUIContent("Comb Y", ""));
                            break;
                        }

                        case Enums.FurType.Fin:
                        {
                            material.DisableKeyword("_FUR_SHELL");
                            material.EnableKeyword("_FUR_FIN");
                            
                            materialEditor.TexturePropertySingleLine(new GUIContent("Fur Albedo", "Albedo Texture for the fur coat"), Inspector.MaterialProperties._FurTexture);
                            materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._FurTexture);
                            XSStyles.SeparatorThin();

                            materialEditor.TexturePropertySingleLine(new GUIContent("Length Mask", "Used to control length of the fur."), Inspector.MaterialProperties._FurLengthMask);
                            materialEditor.TextureScaleOffsetProperty(Inspector.MaterialProperties._FurLengthMask);
                            XSStyles.SeparatorThin();

                            materialEditor.ShaderProperty(Inspector.MaterialProperties._FurMessiness, new GUIContent("Messiness", "How messy the fur is."));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._FurLength, new GUIContent("Length", ""));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._FurLengthRandomness, new GUIContent("Length Variation"));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._FurWidth, new GUIContent("Width", ""));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._FurWidthRandomness, new GUIContent("Width Variation"));
                            XSStyles.SeparatorThin();
                            
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._TopColor, new GUIContent("Top Color", ""));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._BottomColor, new GUIContent("Bottom Color", ""));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._ColorFalloffMin, new GUIContent("Blend Min", ""));
                            materialEditor.ShaderProperty(Inspector.MaterialProperties._ColorFalloffMax, new GUIContent("Blend Max", ""));
                            
                            break;
                        }
                    }
                }
            }
        }

        //!RDPSFunctionInject

        private void DrawVectorSliders(MaterialEditor materialEditor, Material material, MaterialProperty property, string nameR, string nameG, string nameB, string nameA)
        {
            EditorGUI.BeginChangeCheck();
            Vector4 prop = property.vectorValue;
            EditorGUI.indentLevel += 1;
            // materialEditor.ShaderProperty(property, new GUIContent($"{nameR}|{nameG}|{nameB}|{nameA}", ""));
            prop.x = EditorGUILayout.Slider(new GUIContent(nameR, "Clip on mask channel R"), prop.x, 0, 1);
            prop.y = EditorGUILayout.Slider(new GUIContent(nameG, "Clip on mask channel G"), prop.y, 0, 1);
            prop.z = EditorGUILayout.Slider(new GUIContent(nameB, "Clip on mask channel B"), prop.z, 0, 1);
            prop.w = EditorGUILayout.Slider(new GUIContent(nameA, "Clip on mask channel A"), prop.w, 0, 1);
            EditorGUI.indentLevel -= 1;
            property.vectorValue = prop;
        }

        private Vector4 ClampVec4(Vector4 vec)
        {
            Vector4 value = vec;
            value.x = Mathf.Clamp01(value.x);
            value.y = Mathf.Clamp01(value.y);
            value.z = Mathf.Clamp01(value.z);
            value.w = Mathf.Clamp01(value.w);
            return value;
        }
    }
}
