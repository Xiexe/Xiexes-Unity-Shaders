using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;
using System.Reflection;

namespace XSToon3
{
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
        public bool ShowAdvanced = false;
        public bool ShowEyeTracking = false;
        public bool ShowAudioLink = false;
        public bool ShowDissolve = false;
        public bool ShowFur = false;
    }

    public class XSToonInspector : ShaderGUI
    {
        protected static Dictionary<Material, FoldoutToggles> Foldouts = new Dictionary<Material, FoldoutToggles>();
        protected BindingFlags bindingFlags = BindingFlags.Public |
                                    BindingFlags.NonPublic |
                                    BindingFlags.Instance |
                                    BindingFlags.Static;

        //Assign all properties as null at first to stop hundreds of warnings spamming the log when script gets compiled.
        //If they aren't we get warnings, because assigning with reflection seems to make Unity think that the properties never actually get used.
        protected MaterialProperty _VertexColorAlbedo = null;
        protected MaterialProperty _TilingMode = null;
        protected MaterialProperty _Culling = null;
        protected MaterialProperty _BlendMode = null;
        protected MaterialProperty _MainTex = null;
        protected MaterialProperty _HSVMask = null;
        protected MaterialProperty _Saturation = null;
        protected MaterialProperty _Hue = null;
        protected MaterialProperty _Value = null;
        protected MaterialProperty _Color = null;
        protected MaterialProperty _Cutoff = null;
        protected MaterialProperty _FadeDither = null;
        protected MaterialProperty _FadeDitherDistance = null;
        protected MaterialProperty _BumpMap = null;
        protected MaterialProperty _BumpScale = null;
        protected MaterialProperty _DetailNormalMap = null;
        protected MaterialProperty _DetailMask = null;
        protected MaterialProperty _DetailNormalMapScale = null;
        protected MaterialProperty _ReflectionMode = null;
        protected MaterialProperty _ReflectionBlendMode = null;
        protected MaterialProperty _MetallicGlossMap = null;
        protected MaterialProperty _BakedCubemap = null;
        protected MaterialProperty _Matcap = null;
        protected MaterialProperty _MatcapTintToDiffuse = null;
        protected MaterialProperty _MatcapTint = null;
        protected MaterialProperty _ReflectivityMask = null;
        protected MaterialProperty _Metallic = null;
        protected MaterialProperty _Glossiness = null;
        protected MaterialProperty _Reflectivity = null;
        protected MaterialProperty _ClearCoat = null;
        protected MaterialProperty _ClearcoatStrength = null;
        protected MaterialProperty _ClearcoatSmoothness = null;
        protected MaterialProperty _EmissionMap = null;
        protected MaterialProperty _ScaleWithLight = null;
        protected MaterialProperty _ScaleWithLightSensitivity = null;
        protected MaterialProperty _EmissionColor = null;
        protected MaterialProperty _EmissionColor0 = null;
        protected MaterialProperty _EmissionColor1 = null;
        protected MaterialProperty _EmissionToDiffuse = null;
        protected MaterialProperty _RimColor = null;
        protected MaterialProperty _RimIntensity = null;
        protected MaterialProperty _RimRange = null;
        protected MaterialProperty _RimThreshold = null;
        protected MaterialProperty _RimSharpness = null;
        protected MaterialProperty _RimAlbedoTint = null;
        protected MaterialProperty _RimCubemapTint = null;
        protected MaterialProperty _RimAttenEffect = null;
        protected MaterialProperty _SpecularSharpness = null;
        protected MaterialProperty _SpecularMap = null;
        protected MaterialProperty _SpecularIntensity = null;
        protected MaterialProperty _SpecularArea = null;
        protected MaterialProperty _AnisotropicSpecular = null;
        protected MaterialProperty _AnisotropicReflection = null;
        protected MaterialProperty _SpecularAlbedoTint = null;
        protected MaterialProperty _RampSelectionMask = null;
        protected MaterialProperty _Ramp = null;
        protected MaterialProperty _RimMask = null;
        protected MaterialProperty _ShadowRim = null;
        protected MaterialProperty _ShadowRimRange = null;
        protected MaterialProperty _ShadowRimThreshold = null;
        protected MaterialProperty _ShadowRimSharpness = null;
        protected MaterialProperty _ShadowRimAlbedoTint = null;
        protected MaterialProperty _OcclusionMap = null;
        protected MaterialProperty _OcclusionIntensity = null;
        protected MaterialProperty _OcclusionMode = null;
        protected MaterialProperty _ThicknessMap = null;
        protected MaterialProperty _SSColor = null;
        protected MaterialProperty _SSDistortion = null;
        protected MaterialProperty _SSPower = null;
        protected MaterialProperty _SSScale = null;
        protected MaterialProperty _HalftoneDotSize = null;
        protected MaterialProperty _HalftoneDotAmount = null;
        protected MaterialProperty _HalftoneLineAmount = null;
        protected MaterialProperty _HalftoneLineIntensity = null;
        protected MaterialProperty _HalftoneType = null;
        protected MaterialProperty _UVSetAlbedo = null;
        protected MaterialProperty _UVSetNormal = null;
        protected MaterialProperty _UVSetDetNormal = null;
        protected MaterialProperty _UVSetDetMask = null;
        protected MaterialProperty _UVSetMetallic = null;
        protected MaterialProperty _UVSetSpecular = null;
        protected MaterialProperty _UVSetReflectivity = null;
        protected MaterialProperty _UVSetThickness = null;
        protected MaterialProperty _UVSetOcclusion = null;
        protected MaterialProperty _UVSetEmission = null;
        protected MaterialProperty _UVSetClipMap = null;
        protected MaterialProperty _UVSetDissolve = null;
        protected MaterialProperty _UVSetRimMask = null;
        protected MaterialProperty _Stencil = null;
        protected MaterialProperty _StencilComp = null;
        protected MaterialProperty _StencilOp = null;
        protected MaterialProperty _OutlineAlbedoTint = null;
        protected MaterialProperty _OutlineLighting = null;
        protected MaterialProperty _OutlineMask = null;
        protected MaterialProperty _OutlineWidth = null;
        protected MaterialProperty _OutlineColor = null;
        protected MaterialProperty _OutlineNormalMode = null;
        protected MaterialProperty _OutlineUVSelect = null;
        protected MaterialProperty _ShadowSharpness = null;
        protected MaterialProperty _AdvMode = null;
        protected MaterialProperty _ClipMap = null;
        protected MaterialProperty _ClipAgainstVertexColorGreaterZeroFive = null;
        protected MaterialProperty _ClipAgainstVertexColorLessZeroFive = null;
        protected MaterialProperty _IOR = null;
        protected MaterialProperty _NormalMapMode = null;
        protected MaterialProperty _DissolveCoordinates = null;
        protected MaterialProperty _DissolveTexture = null;
        protected MaterialProperty _DissolveStrength = null;
        protected MaterialProperty _DissolveColor = null;
        protected MaterialProperty _DissolveProgress = null;
        protected MaterialProperty _UseClipsForDissolve = null;
        protected MaterialProperty _WireColor = null;
        protected MaterialProperty _WireWidth = null;
        protected MaterialProperty _SrcBlend = null;
        protected MaterialProperty _DstBlend = null;
        protected MaterialProperty _ZWrite = null;


        protected MaterialProperty _EmissionAudioLinkChannel = null;
        protected MaterialProperty _ALGradientOnRed = null;
        protected MaterialProperty _ALGradientOnGreen = null;
        protected MaterialProperty _ALGradientOnBlue = null;
        protected MaterialProperty _ALUVWidth = null;

        //Experimenting
        protected MaterialProperty _DissolveBlendPower = null;
        protected MaterialProperty _DissolveLayer1Scale = null;
        protected MaterialProperty _DissolveLayer2Scale = null;
        protected MaterialProperty _DissolveLayer1Speed = null;
        protected MaterialProperty _DissolveLayer2Speed = null;
        protected MaterialProperty _ClipMask = null;
        protected MaterialProperty _ClipIndex = null;
        protected MaterialProperty _ClipSlider00 = null;
        protected MaterialProperty _ClipSlider01 = null;
        protected MaterialProperty _ClipSlider02 = null;
        protected MaterialProperty _ClipSlider03 = null;
        protected MaterialProperty _ClipSlider04 = null;
        protected MaterialProperty _ClipSlider05 = null;
        protected MaterialProperty _ClipSlider06 = null;
        protected MaterialProperty _ClipSlider07 = null;
        protected MaterialProperty _ClipSlider08 = null;
        protected MaterialProperty _ClipSlider09 = null;
        protected MaterialProperty _ClipSlider10 = null;
        protected MaterialProperty _ClipSlider11 = null;
        protected MaterialProperty _ClipSlider12 = null;
        protected MaterialProperty _ClipSlider13 = null;
        protected MaterialProperty _ClipSlider14 = null;
        protected MaterialProperty _ClipSlider15 = null;

        //Material Properties for Patreon Plugins
        protected MaterialProperty _LeftRightPan = null;
        protected MaterialProperty _UpDownPan = null;
        protected MaterialProperty _Twitchyness = null;
        protected MaterialProperty _AttentionSpan = null;
        protected MaterialProperty _FollowPower = null;
        protected MaterialProperty _FollowLimit = null;
        protected MaterialProperty _LookSpeed = null;
        protected MaterialProperty _IrisSize = null;
        protected MaterialProperty _EyeOffsetLimit = null;
        //--

        //Properties for Fur plugin
        protected MaterialProperty _FurTexture = null;
        protected MaterialProperty _FurLengthMask = null;
        protected MaterialProperty _NoiseTexture = null;
        protected MaterialProperty _LayerCount = null;
        protected MaterialProperty _FurLength = null;
        protected MaterialProperty _FurWidth = null;
        protected MaterialProperty _Gravity = null;
        protected MaterialProperty _CombX = null;
        protected MaterialProperty _CombY = null;
        protected MaterialProperty _FurOcclusion = null;
        protected MaterialProperty _OcclusionFalloffMin = null;
        protected MaterialProperty _OcclusionFalloffMax = null;
        protected MaterialProperty _ColorFalloffMin = null;
        protected MaterialProperty _ColorFalloffMax = null;
        protected MaterialProperty _BottomColor = null;
        protected MaterialProperty _TopColor = null;
        protected MaterialProperty _StrandAmount = null;
        //

        //!RDPSPropsInjection

        private static bool OverrideRenderSettings = false;
        protected static int BlendMode;
        protected bool isPatreonShader = false;
        protected bool isEyeTracking = false;
        protected bool isFurShader = false;
        protected bool isOutlined = false;
        protected bool isCutout = false;
        protected bool isCutoutMasked = false;
        protected bool isDithered = false;
        protected bool isA2C = false;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            Material material = materialEditor.target as Material;
            Shader shader = material.shader;

            BlendMode = material.GetInt("_BlendMode");
            isCutout = BlendMode == 1;
            isDithered = BlendMode == 2;
            isA2C = BlendMode == 3;
            isOutlined = shader.name.Contains("Outline");
            isPatreonShader = shader.name.Contains("Patreon");
            isEyeTracking = shader.name.Contains("EyeTracking");
            isFurShader = shader.name.Contains("Fur");

            SetupFoldoutDictionary(material);

            //Find all material properties listed in the script using reflection, and set them using a loop only if they're of type MaterialProperty.
            //This makes things a lot nicer to maintain and cleaner to look at.
            foreach (var property in GetType().GetFields(bindingFlags))
            {
                if (property.FieldType == typeof(MaterialProperty))
                {
                    try { property.SetValue(this, FindProperty(property.Name, props)); } catch { /*Is it really a problem if it doesn't exist?*/ }
                }
            }

            EditorGUI.BeginChangeCheck();
            XSStyles.ShurikenHeaderCentered("XSToon v" + XSStyles.ver);
            materialEditor.ShaderProperty(_AdvMode, new GUIContent("Shader Mode", "Setting this to 'Advanced' will give you access to things such as stenciling, and other expiremental/advanced features."));
            materialEditor.ShaderProperty(_Culling, new GUIContent("Culling Mode", "Changes the culling mode. 'Off' will result in a two sided material, while 'Front' and 'Back' will cull those sides respectively"));
            materialEditor.ShaderProperty(_TilingMode, new GUIContent("Tiling Mode", "Setting this to Merged will tile and offset all textures based on the Main texture's Tiling/Offset."));
            materialEditor.ShaderProperty(_BlendMode, new GUIContent("Blend Mode", "Blend mode of the material. (Opaque, transparent, cutout, etc.)"));

            if (!isFurShader)
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
            DrawFurSettings(materialEditor, material);
            DrawDissolveSettings(materialEditor, material);
            DrawShadowSettings(materialEditor, material);
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
            DrawPatreonSettings(materialEditor, material);

            //!RDPSFunctionCallInject

            XSStyles.DoFooter();
        }

        public virtual void PluginGUI(MaterialEditor materialEditor, Material material) {
        }

        private void SetupFoldoutDictionary(Material material)
        {
            if (Foldouts.ContainsKey(material))
                return;

            FoldoutToggles toggles = new FoldoutToggles();
            Foldouts.Add(material, toggles);
        }

        private void DoBlendModeSettings(Material material)
        {
            if (OverrideRenderSettings)
                return;

            switch (BlendMode)
            {
                case 0: //Opaque
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.Zero,
                        (int) UnityEngine.Rendering.RenderQueue.Geometry, 1, 0);
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHATEST_ON");
                    break;

                case 1: //Cutout
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.Zero,
                        (int) UnityEngine.Rendering.RenderQueue.AlphaTest, 1, 0);
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.EnableKeyword("_ALPHATEST_ON");
                    break;

                case 2: //Dithered
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.Zero,
                        (int) UnityEngine.Rendering.RenderQueue.AlphaTest, 1, 0);
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.EnableKeyword("_ALPHATEST_ON");
                    break;

                case 3: //Alpha To Coverage
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.Zero,
                        (int) UnityEngine.Rendering.RenderQueue.AlphaTest, 1, 1);
                    material.EnableKeyword("_ALPHABLEND_ON");
                    material.EnableKeyword("_ALPHATEST_ON");
                    break;

                case 4: //Transparent
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.One,
                        (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha,
                        (int) UnityEngine.Rendering.RenderQueue.Transparent, 0, 0);
                    material.EnableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHATEST_ON");
                    break;

                case 5: //Fade
                    SetBlend(material, (int) UnityEngine.Rendering.BlendMode.SrcAlpha,
                        (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha,
                        (int) UnityEngine.Rendering.RenderQueue.Transparent, 0, 0);
                    material.EnableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHATEST_ON");
                    break;

                case 6: //Additive
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
                materialEditor.TexturePropertySingleLine(new GUIContent("Main Texture", "The main Albedo texture."), _MainTex, _Color);
                if (isCutout)
                {
                    materialEditor.ShaderProperty(_Cutoff, new GUIContent("Cutoff", "The Cutoff Amount"), 2);
                }
                materialEditor.ShaderProperty(_UVSetAlbedo, new GUIContent("UV Set", "The UV set to use for the Albedo Texture."), 2);
                materialEditor.TextureScaleOffsetProperty(_MainTex);

                materialEditor.TexturePropertySingleLine(new GUIContent("HSV Mask", "RGB Mask: R = Hue,  G = Saturation, B = Brightness"), _HSVMask);
                materialEditor.ShaderProperty(_Hue, new GUIContent("Hue", "Controls Hue of the final output from the shader."));
                materialEditor.ShaderProperty(_Saturation, new GUIContent("Saturation", "Controls saturation of the final output from the shader."));
                materialEditor.ShaderProperty(_Value, new GUIContent("Brightness", "Controls value of the final output from the shader."));

                if (isDithered)
                {
                    XSStyles.SeparatorThin();
                    materialEditor.ShaderProperty(_FadeDither, new GUIContent("Distance Fading", "Make the shader dither out based on the distance to the camera."));
                    materialEditor.ShaderProperty(_FadeDitherDistance, new GUIContent("Fade Threshold", "The distance at which the fading starts happening."));
                }
            }
        }

        private void DrawDissolveSettings(MaterialEditor materialEditor, Material material)
        {
            if (isCutout || isDithered || isA2C)
            {
                Foldouts[material].ShowDissolve = XSStyles.ShurikenFoldout("Dissolve", Foldouts[material].ShowDissolve);
                if (Foldouts[material].ShowDissolve)
                {
                    materialEditor.ShaderProperty(_DissolveCoordinates, new GUIContent("Dissolve Coordinates", "Should Dissolve happen in world space, texture space, or vertically?"));
                    materialEditor.TexturePropertySingleLine(new GUIContent("Dissolve Texture", "Noise texture used to control up dissolve pattern"), _DissolveTexture, _DissolveColor);
                    materialEditor.TextureScaleOffsetProperty(_DissolveTexture);
                    materialEditor.ShaderProperty(_UVSetDissolve, new GUIContent("UV Set", "The UV set to use for the Dissolve Texture."), 2);


                    materialEditor.ShaderProperty(_DissolveBlendPower, new GUIContent("Layer Blend", "How much to boost the blended layers"));
                    materialEditor.ShaderProperty(_DissolveLayer1Scale, new GUIContent("Layer 1 Scale", "How much tiling to apply to the layer."));
                    materialEditor.ShaderProperty(_DissolveLayer1Speed, new GUIContent("Layer 1 Speed", "Scroll Speed of the layer, can be negative."));

                    materialEditor.ShaderProperty(_DissolveLayer2Scale, new GUIContent("Layer 2 Scale", "How much tiling to apply to the layer."));
                    materialEditor.ShaderProperty(_DissolveLayer2Speed, new GUIContent("Layer 2 Speed", "Scroll Speed of the layer, can be negative."));

                    materialEditor.ShaderProperty(_DissolveStrength, new GUIContent("Dissolve Sharpness", "Sharpness of the dissolve texture."));
                    materialEditor.ShaderProperty(_DissolveProgress, new GUIContent("Dissolve Progress", "Progress of the dissolve effect."));
                }
            }
        }

        private void DrawShadowSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowShadows = XSStyles.ShurikenFoldout("Shadows", Foldouts[material].ShowShadows);
            if (Foldouts[material].ShowShadows)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("Ramp Selection Mask", "A black to white mask that determins how far up on the multi ramp to sample. 0 for bottom, 1 for top, 0.5 for middle, 0.25, and 0.75 for mid bottom and mid top respectively."), _RampSelectionMask);

                XSStyles.SeparatorThin();
                if (_RampSelectionMask.textureValue != null)
                {
                    string rampMaskPath = AssetDatabase.GetAssetPath(_RampSelectionMask.textureValue);
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

                XSStyles.CallGradientEditor(material);
                materialEditor.TexturePropertySingleLine(new GUIContent("Shadow Ramp", "Shadow Ramp, Dark to Light should be Left to Right"), _Ramp);
                materialEditor.ShaderProperty(_ShadowSharpness, new GUIContent("Shadow Sharpness", "Controls the sharpness of recieved shadows, as well as the sharpness of 'shadows' from Vertex Lighting."));

                XSStyles.SeparatorThin();
                materialEditor.ShaderProperty(_OcclusionMode, new GUIContent("Occlusion Mode", "How to calculate the occlusion map contribution"));
                materialEditor.TexturePropertySingleLine(new GUIContent("Occlusion Map", "Occlusion Map, used to darken areas on the model artifically."), _OcclusionMap);
                materialEditor.ShaderProperty(_OcclusionIntensity, new GUIContent("Intensity", "Occlusion intensity"), 2);
                materialEditor.ShaderProperty(_UVSetOcclusion, new GUIContent("UV Set", "The UV set to use for the Occlusion Texture"), 2);
                materialEditor.TextureScaleOffsetProperty(_OcclusionMap);

            }
        }

        private void DrawOutlineSettings(MaterialEditor materialEditor, Material material)
        {
            if (isOutlined)
            {
                Foldouts[material].ShowOutlines = XSStyles.ShurikenFoldout("Outlines", Foldouts[material].ShowOutlines);
                if (Foldouts[material].ShowOutlines)
                {
                    materialEditor.ShaderProperty(_OutlineNormalMode, new GUIContent("Outline Normal Mode", "How to calcuate the outline expand direction. Using mesh normals may result in split edges."));

                    if (_OutlineNormalMode.floatValue == 2)
                        materialEditor.ShaderProperty(_OutlineUVSelect, new GUIContent("Normals UV", "UV Channel to pull the modified normals from for outlines."));

                    materialEditor.ShaderProperty(_OutlineLighting, new GUIContent("Outline Lighting", "Makes outlines respect the lighting, or be emissive."));
                    materialEditor.ShaderProperty(_OutlineAlbedoTint, new GUIContent("Outline Albedo Tint", "Includes the color of the Albedo Texture in the calculation for the color of the outline."));
                    materialEditor.TexturePropertySingleLine(new GUIContent("Outline Mask", "Outline width mask, black will make the outline minimum width."), _OutlineMask);
                    materialEditor.ShaderProperty(_OutlineWidth, new GUIContent("Outline Width", "Width of the Outlines"));
                    XSStyles.constrainedShaderProperty(materialEditor, _OutlineColor, new GUIContent("Outline Color", "Color of the outlines"), 0);
                }
            }
        }

        private void DrawNormalSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowNormal = XSStyles.ShurikenFoldout("Normal Maps", Foldouts[material].ShowNormal);
            if (Foldouts[material].ShowNormal)
            {
                materialEditor.ShaderProperty(_NormalMapMode, new GUIContent("Normal Map Source", "How to alter the normals of the mesh, using which source?"));
                if (_NormalMapMode.floatValue == 0)
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map", "Normal Map"), _BumpMap);
                    materialEditor.ShaderProperty(_BumpScale, new GUIContent("Normal Strength", "Strength of the main Normal Map"), 2);
                    materialEditor.ShaderProperty(_UVSetNormal, new GUIContent("UV Set", "The UV set to use for the Normal Map"), 2);
                    materialEditor.TextureScaleOffsetProperty(_BumpMap);

                    XSStyles.SeparatorThin();
                    materialEditor.TexturePropertySingleLine(new GUIContent("Detail Normal Map", "Detail Normal Map"), _DetailNormalMap);
                    materialEditor.ShaderProperty(_DetailNormalMapScale, new GUIContent("Detail Normal Strength", "Strength of the detail Normal Map"), 2);
                    materialEditor.ShaderProperty(_UVSetDetNormal, new GUIContent("UV Set", "The UV set to use for the Detail Normal Map"), 2);
                    materialEditor.TextureScaleOffsetProperty(_DetailNormalMap);

                    XSStyles.SeparatorThin();
                    materialEditor.TexturePropertySingleLine(new GUIContent("Detail Mask", "Mask for Detail Maps"), _DetailMask);
                    materialEditor.ShaderProperty(_UVSetDetMask, new GUIContent("UV Set", "The UV set to use for the Detail Mask"), 2);
                    materialEditor.TextureScaleOffsetProperty(_DetailMask);
                }
            }
        }

        private void DrawSpecularSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowSpecular = XSStyles.ShurikenFoldout("Specular", Foldouts[material].ShowSpecular);
            if (Foldouts[material].ShowSpecular)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("Specular Map(R,G,B)", "Specular Map. Red channel controls Intensity, Green controls how much specular is tinted by Albedo, and Blue controls Smoothness (Only for Blinn-Phong, and GGX)."), _SpecularMap);
                materialEditor.TextureScaleOffsetProperty(_SpecularMap);
                materialEditor.ShaderProperty(_UVSetSpecular, new GUIContent("UV Set", "The UV set to use for the Specular Map"), 2);
                materialEditor.ShaderProperty(_SpecularIntensity, new GUIContent("Intensity", "Specular Intensity."), 2);
                materialEditor.ShaderProperty(_SpecularArea, new GUIContent("Roughness", "Roughness"), 2);
                materialEditor.ShaderProperty(_SpecularAlbedoTint, new GUIContent("Albedo Tint", "How much the specular highlight should derive color from the albedo of the object."), 2);
                materialEditor.ShaderProperty(_SpecularSharpness, new GUIContent("Sharpness", "How hard of and edge transitions should the specular have?"), 2);
                materialEditor.ShaderProperty(_AnisotropicSpecular, new GUIContent("Anisotropy", "The amount of anisotropy the surface has - this will stretch the reflection along an axis (think bottom of a frying pan)"), 2);
            }
        }

        private void DrawReflectionsSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowReflection = XSStyles.ShurikenFoldout("Reflections", Foldouts[material].ShowReflection);
            if (Foldouts[material].ShowReflection)
            {
                materialEditor.ShaderProperty(_ReflectionMode, new GUIContent("Reflection Mode", "Reflection Mode."));

                if (_ReflectionMode.floatValue == 0) // PBR
                {
                    materialEditor.ShaderProperty(_ReflectionBlendMode, new GUIContent("Reflection Blend Mode", "Blend mode for reflection. Additive is Color + reflection, Multiply is Color * reflection, and subtractive is Color - reflection"));
                    materialEditor.ShaderProperty(_ClearCoat, new GUIContent("Clearcoat", "Clearcoat"));

                    XSStyles.SeparatorThin();
                    materialEditor.TexturePropertySingleLine(new GUIContent("Fallback Cubemap", " Used as fallback in 'Unity' reflection mode if reflection probe is black."), _BakedCubemap);

                    XSStyles.SeparatorThin();
                    materialEditor.TexturePropertySingleLine(new GUIContent("Metallic Map", "Metallic Map, Metallic on Red Channel, Smoothness on Alpha Channel. \nIf Clearcoat is enabled, Clearcoat Smoothness on Green Channel, Clearcoat Reflectivity on Blue Channel."), _MetallicGlossMap);
                    materialEditor.TextureScaleOffsetProperty(_MetallicGlossMap);
                    materialEditor.ShaderProperty(_UVSetMetallic, new GUIContent("UV Set", "The UV set to use for the Metallic Smoothness Map"), 2);
                    materialEditor.ShaderProperty(_AnisotropicReflection, new GUIContent("Anisotropy", "The amount of anisotropy the surface has - this will stretch the reflection along an axis (think bottom of a frying pan)"), 2);
                    materialEditor.ShaderProperty(_Metallic, new GUIContent("Metallic", "Metallic, set to 1 if using metallic map"), 2);
                    materialEditor.ShaderProperty(_Glossiness, new GUIContent("Smoothness", "Smoothness, set to 1 if using metallic map"), 2);
                    materialEditor.ShaderProperty(_ClearcoatSmoothness, new GUIContent("Clearcoat Smoothness", "Smoothness of the clearcoat."), 2);
                    materialEditor.ShaderProperty(_ClearcoatStrength, new GUIContent("Clearcoat Reflectivity", "The strength of the clearcoat reflection."), 2);
                }
                else if (_ReflectionMode.floatValue == 1) //Baked cube
                {
                    materialEditor.ShaderProperty(_ReflectionBlendMode, new GUIContent("Reflection Blend Mode", "Blend mode for reflection. Additive is Color + reflection, Multiply is Color * reflection, and subtractive is Color - reflection"));
                    materialEditor.ShaderProperty(_ClearCoat, new GUIContent("Clearcoat", "Clearcoat"));

                    XSStyles.SeparatorThin();
                    materialEditor.TexturePropertySingleLine(new GUIContent("Baked Cubemap", "Baked cubemap."), _BakedCubemap);

                    XSStyles.SeparatorThin();
                    materialEditor.TexturePropertySingleLine(new GUIContent("Metallic Map", "Metallic Map, Metallic on Red Channel, Smoothness on Alpha Channel. \nIf Clearcoat is enabled, Clearcoat Smoothness on Green Channel, Clearcoat Reflectivity on Blue Channel."), _MetallicGlossMap);
                    materialEditor.TextureScaleOffsetProperty(_MetallicGlossMap);
                    materialEditor.ShaderProperty(_UVSetMetallic, new GUIContent("UV Set", "The UV set to use for the MetallicSmoothness Map"), 2);
                    materialEditor.ShaderProperty(_AnisotropicReflection, new GUIContent("Anisotropic", "Anisotropic, stretches reflection in an axis."), 2);
                    materialEditor.ShaderProperty(_Metallic, new GUIContent("Metallic", "Metallic, set to 1 if using metallic map"), 2);
                    materialEditor.ShaderProperty(_Glossiness, new GUIContent("Smoothness", "Smoothness, set to 1 if using metallic map"), 2);
                    materialEditor.ShaderProperty(_ClearcoatSmoothness, new GUIContent("Clearcoat Smoothness", "Smoothness of the clearcoat."), 2);
                    materialEditor.ShaderProperty(_ClearcoatStrength, new GUIContent("Clearcoat Reflectivity", "The strength of the clearcoat reflection."), 2);
                }
                else if (_ReflectionMode.floatValue == 2) //Matcap
                {
                    materialEditor.ShaderProperty(_ReflectionBlendMode, new GUIContent("Reflection Blend Mode", "Blend mode for reflection. Additive is Color + reflection, Multiply is Color * reflection, and subtractive is Color - reflection"));

                    XSStyles.SeparatorThin();
                    materialEditor.TexturePropertySingleLine(new GUIContent("Matcap", "Matcap Texture"), _Matcap, _MatcapTint);
                    materialEditor.ShaderProperty(_Glossiness, new GUIContent("Matcap Blur", "Matcap blur, blurs the Matcap, set to 1 for full clarity"), 2);
                    materialEditor.ShaderProperty(_MatcapTintToDiffuse, new GUIContent("Tint To Diffuse", "Tints matcap to diffuse color."), 2);
                    material.SetFloat("_Metallic", 0);
                    material.SetFloat("_ClearCoat", 0);
                    material.SetTexture("_MetallicGlossMap", null);
                }
                if (_ReflectionMode.floatValue != 3)
                {
                    XSStyles.SeparatorThin();
                    materialEditor.TexturePropertySingleLine(new GUIContent("Reflectivity Mask", "Mask for reflections."), _ReflectivityMask);
                    materialEditor.TextureScaleOffsetProperty(_ReflectivityMask);
                    materialEditor.ShaderProperty(_UVSetReflectivity, new GUIContent("UV Set", "The UV set to use for the Reflectivity Mask"), 2);
                    materialEditor.ShaderProperty(_Reflectivity, new GUIContent("Reflectivity", "The strength of the reflections."), 2);
                }
                if (_ReflectionMode.floatValue == 3)
                {
                    material.SetFloat("_Metallic", 0);
                    material.SetFloat("_ReflectionBlendMode", 0);
                    material.SetFloat("_ClearCoat", 0);
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
                materialEditor.ShaderProperty(_EmissionAudioLinkChannel, new GUIContent("Emission Audio Link", "Use Audio Link for Emission Brightness"));

                if (!isPackedMapLink)
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Emission Map", "Emissive map. White to black, unless you want multiple colors."), _EmissionMap, _EmissionColor);
                    materialEditor.TextureScaleOffsetProperty(_EmissionMap);
                    materialEditor.ShaderProperty(_UVSetEmission, new GUIContent("UV Set", "The UV set to use for the Emission Map"), 2);
                    materialEditor.ShaderProperty(_EmissionToDiffuse, new GUIContent("Tint To Diffuse", "Tints the emission to the Diffuse Color"), 2);
                    if (isUVBased) {
                        materialEditor.ShaderProperty(_ALUVWidth, new GUIContent("History Sample Amount", "Controls the amount of Audio Link history to sample."));
                    }
                }
                else
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Emission Map (VRC Audio Link Packed)", "Emissive map. Each channel controls different audio link reactions. RGB = Lows, Mids, Highs, Alpha Channel can be used to have extra masking as a way to combat aliasing"), _EmissionMap);
                    materialEditor.TextureScaleOffsetProperty(_EmissionMap);
                    materialEditor.ShaderProperty(_UVSetEmission, new GUIContent("UV Set", "The UV set to use for the Emission Map"), 2);
                    materialEditor.ShaderProperty(_EmissionToDiffuse, new GUIContent("Tint To Diffuse", "Tints the emission to the Diffuse Color"), 2);

                    XSStyles.SeparatorThin();

                    materialEditor.ColorProperty(_EmissionColor, "Red Ch. Color (Lows)");
                    materialEditor.ShaderProperty(_ALGradientOnRed, new GUIContent("Gradient Bar", "Uses a gradient on this channel to create an animated bar from the audio link data."), 1);

                    materialEditor.ColorProperty(_EmissionColor0, "Green Ch. Color (Mids)");
                    materialEditor.ShaderProperty(_ALGradientOnGreen, new GUIContent("Gradient Bar", "Uses a gradient on this channel to create an animated bar from the audio link data."), 1);

                    materialEditor.ColorProperty(_EmissionColor1, "Blue Ch. Color (Highs)");
                    materialEditor.ShaderProperty(_ALGradientOnBlue, new GUIContent("Gradient Bar", "Uses a gradient on this channel to create an animated bar from the audio link data."), 1);
                }

                XSStyles.SeparatorThin();
                materialEditor.ShaderProperty(_ScaleWithLight, new GUIContent("Scale w/ Light", "Scales the emission intensity based on how dark or bright the environment is."));
                if (_ScaleWithLight.floatValue == 0)
                    materialEditor.ShaderProperty(_ScaleWithLightSensitivity, new GUIContent("Scaling Sensitivity", "How agressively the emission should scale with the light."));
            }
        }

        private void DrawRimlightSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowRimlight = XSStyles.ShurikenFoldout("Rim Light & Shadow", Foldouts[material].ShowRimlight);
            if (Foldouts[material].ShowRimlight)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("Rim Mask (Packed)", "Channels are used to mask out rim light and rim shadow effects. \n\n Red Channel: Rim Light Mask \n Green Channel: Rim Shadow Mask"), _RimMask);
                materialEditor.TextureScaleOffsetProperty(_RimMask);
                materialEditor.ShaderProperty(_UVSetRimMask, new GUIContent("UV Set", "The UV set to use for the Rim Mask"), 2);

                XSStyles.SeparatorThin();
                materialEditor.ShaderProperty(_RimColor, new GUIContent("Rimlight Tint", "The Tint of the Rimlight."));
                materialEditor.ShaderProperty(_RimAlbedoTint, new GUIContent("Rim Albedo Tint", "How much the Albedo texture should effect the rimlight color."));
                materialEditor.ShaderProperty(_RimCubemapTint, new GUIContent("Rim Environment Tint", "How much the Environment cubemap should effect the rimlight color."));
                materialEditor.ShaderProperty(_RimAttenEffect, new GUIContent("Rim Attenuation Effect", "How much should realtime shadows mask out the rimlight?"));
                materialEditor.ShaderProperty(_RimIntensity, new GUIContent("Rimlight Intensity", "Strength of the Rimlight."));
                materialEditor.ShaderProperty(_RimRange, new GUIContent("Range", "Range of the Rim"), 2);
                materialEditor.ShaderProperty(_RimThreshold, new GUIContent("Threshold", "Threshold of the Rim"), 2);
                materialEditor.ShaderProperty(_RimSharpness, new GUIContent("Sharpness", "Sharpness of the Rim"), 2);

                XSStyles.SeparatorThin();
                XSStyles.constrainedShaderProperty(materialEditor, _ShadowRim, new GUIContent("Shadow Rim", "Shadow Rim Color. Set to white to disable."), 0);
                materialEditor.ShaderProperty(_ShadowRimAlbedoTint, new GUIContent("Shadow Rim Albedo Tint", "How much the Albedo texture should effect the Shadow Rim color."));
                materialEditor.ShaderProperty(_ShadowRimRange, new GUIContent("Range", "Range of the Shadow Rim"), 2);
                materialEditor.ShaderProperty(_ShadowRimThreshold, new GUIContent("Threshold", "Threshold of the Shadow Rim"), 2);
                materialEditor.ShaderProperty(_ShadowRimSharpness, new GUIContent("Sharpness", "Sharpness of the Shadow Rim"), 2);
            }
        }

        private void DrawHalfToneSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowHalftones = XSStyles.ShurikenFoldout("Halftones", Foldouts[material].ShowHalftones);
            if (Foldouts[material].ShowHalftones)
            {
                materialEditor.ShaderProperty(_HalftoneType, new GUIContent("Halftone Style", "Controls where halftone and stippling effects are drawn."));

                if (_HalftoneType.floatValue == 1 || _HalftoneType.floatValue == 2)
                {
                    materialEditor.ShaderProperty(_HalftoneDotSize, new GUIContent("Stippling Scale", "How large should the stippling pattern be?"));
                    materialEditor.ShaderProperty(_HalftoneDotAmount, new GUIContent("Stippling Density", "How dense is the stippling effect?"));
                }

                if (_HalftoneType.floatValue == 0 || _HalftoneType.floatValue == 2)
                {
                    materialEditor.ShaderProperty(_HalftoneLineAmount, new GUIContent("Halftone Line Count", "How many lines should the halftone shadows have?"));
                    materialEditor.ShaderProperty(_HalftoneLineIntensity, new GUIContent("Halftone Line Intensity", "How dark should the halftone lines be?"));
                }
            }
        }

        private void DrawTransmissionSettings(MaterialEditor materialEditor, Material material)
        {
            Foldouts[material].ShowSubsurface = XSStyles.ShurikenFoldout("Transmission", Foldouts[material].ShowSubsurface);
            if (Foldouts[material].ShowSubsurface)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("Thickness Map", "Thickness Map, used to mask areas where transmission can happen"), _ThicknessMap);
                materialEditor.TextureScaleOffsetProperty(_ThicknessMap);
                materialEditor.ShaderProperty(_UVSetThickness, new GUIContent("UV Set", "The UV set to use for the Thickness Map"), 2);
                XSStyles.constrainedShaderProperty(materialEditor, _SSColor, new GUIContent("Transmission Color", "Transmission Color"), 2);
                materialEditor.ShaderProperty(_SSDistortion, new GUIContent("Transmission Distortion", "How much the Transmission should follow the normals of the mesh and/or normal map."), 2);
                materialEditor.ShaderProperty(_SSPower, new GUIContent("Transmission Power", "Subsurface Power"), 2);
                materialEditor.ShaderProperty(_SSScale, new GUIContent("Transmission Scale", "Subsurface Scale"), 2);
            }
        }

        private void DrawAdvancedSettings(MaterialEditor materialEditor, Material material)
        {
            if (_AdvMode.floatValue == 1)
            {
                Foldouts[material].ShowAdvanced = XSStyles.ShurikenFoldout("Advanced Settings", Foldouts[material].ShowAdvanced);
                if (Foldouts[material].ShowAdvanced)
                {
                    if (isDithered || isCutout || isA2C)
                    {
                        //XSStyles.CallTexArrayManager();
                        materialEditor.TexturePropertySingleLine(new GUIContent("Clip Map (RGB)", "Texture used to control clipping based on the Clip Index parameter."), _ClipMask);
                        materialEditor.ShaderProperty(_UseClipsForDissolve, new GUIContent("Use For Dissolve"), 2);

                        materialEditor.ShaderProperty(_UVSetClipMap, new GUIContent("UV Set", "The UV set to use for the Clip Map"), 2);

                        XSStyles.DoHeaderLeft("Clip Against");
                        materialEditor.ShaderProperty(_ClipIndex, new GUIContent("Clip Index", "Should be unique per material, controls which set of slider values to use for clipping. Can be 0 - 8(materials), with 8 masks in each texture, for a total of 64 unique masks."), 1);
                        XSStyles.SeparatorThin();
                        int materialClipIndex = material.GetInt("_ClipIndex");
                        switch (materialClipIndex)
                        {
                            case 0: DrawVectorSliders(materialEditor, material, _ClipSlider00, "Red", "Green", "Blue", "White"); DrawVectorSliders(materialEditor, material, _ClipSlider01, "Cyan", "Yellow", "Magenta", "Black"); break;
                            case 1: DrawVectorSliders(materialEditor, material, _ClipSlider02, "Red", "Green", "Blue", "White"); DrawVectorSliders(materialEditor, material, _ClipSlider03, "Cyan", "Yellow", "Magenta", "Black"); break;
                            case 2: DrawVectorSliders(materialEditor, material, _ClipSlider04, "Red", "Green", "Blue", "White"); DrawVectorSliders(materialEditor, material, _ClipSlider05, "Cyan", "Yellow", "Magenta", "Black"); break;
                            case 3: DrawVectorSliders(materialEditor, material, _ClipSlider06, "Red", "Green", "Blue", "White"); DrawVectorSliders(materialEditor, material, _ClipSlider07, "Cyan", "Yellow", "Magenta", "Black"); break;
                            case 4: DrawVectorSliders(materialEditor, material, _ClipSlider08, "Red", "Green", "Blue", "White"); DrawVectorSliders(materialEditor, material, _ClipSlider09, "Cyan", "Yellow", "Magenta", "Black"); break;
                            case 5: DrawVectorSliders(materialEditor, material, _ClipSlider10, "Red", "Green", "Blue", "White"); DrawVectorSliders(materialEditor, material, _ClipSlider11, "Cyan", "Yellow", "Magenta", "Black"); break;
                            case 6: DrawVectorSliders(materialEditor, material, _ClipSlider12, "Red", "Green", "Blue", "White"); DrawVectorSliders(materialEditor, material, _ClipSlider13, "Cyan", "Yellow", "Magenta", "Black"); break;
                            case 7: DrawVectorSliders(materialEditor, material, _ClipSlider14, "Red", "Green", "Blue", "White"); DrawVectorSliders(materialEditor, material, _ClipSlider15, "Cyan", "Yellow", "Magenta", "Black"); break;
                        }
                    }

                    XSStyles.Separator();
                    materialEditor.ShaderProperty(_VertexColorAlbedo, new GUIContent("Vertex Color Albedo", "Multiplies the vertex color of the mesh by the Albedo texture to derive the final Albedo color."));
                    materialEditor.ShaderProperty(_WireColor, new GUIContent("Wire Color On UV2", "This will only work with a specific second uv channel setup."));
                    materialEditor.ShaderProperty(_WireWidth, new GUIContent("Wire Width", "Controls the above wire width."));

                    XSStyles.Separator();
                    materialEditor.ShaderProperty(_Stencil, _Stencil.displayName);
                    materialEditor.ShaderProperty(_StencilComp, _StencilComp.displayName);
                    materialEditor.ShaderProperty(_StencilOp, _StencilOp.displayName);

                    XSStyles.Separator();
                    OverrideRenderSettings = EditorGUILayout.Toggle(new GUIContent("Override Render Settings", "Allows manual control over all render settings (Queue, ZWrite, Etc.)"), OverrideRenderSettings);

                    materialEditor.ShaderProperty(_SrcBlend, new GUIContent("SrcBlend", ""));
                    materialEditor.ShaderProperty(_DstBlend, new GUIContent("DstBlend", ""));
                    materialEditor.ShaderProperty(_ZWrite, new GUIContent("ZWrite", ""));
                    XSStyles.Separator();
                    materialEditor.RenderQueueField();
                    XSStyles.Separator();
                }
            }
        }

        private void DrawPatreonSettings(MaterialEditor materialEditor, Material material)
        {
            //Plugins for Patreon releases
            if (isPatreonShader)
            {
                if (isEyeTracking)
                {
                    Foldouts[material].ShowEyeTracking = XSStyles.ShurikenFoldout("Eye Tracking Settings", Foldouts[material].ShowEyeTracking);
                    if (Foldouts[material].ShowEyeTracking)
                    {
                        materialEditor.ShaderProperty(_LeftRightPan, new GUIContent("Left Right Adj.", "Adjusts the eyes manually left or right."));
                        materialEditor.ShaderProperty(_UpDownPan, new GUIContent("Up Down Adj.", "Adjusts the eyes manually up or down."));

                        XSStyles.SeparatorThin();
                        materialEditor.ShaderProperty(_AttentionSpan, new GUIContent("Attention Span", "How often should the eyes look at the target; 0 = never, 1 = always, 0.5 = half of the time."));
                        materialEditor.ShaderProperty(_FollowPower, new GUIContent("Follow Power", "The influence the target has on the eye"));
                        materialEditor.ShaderProperty(_LookSpeed, new GUIContent("Look Speed", "How fast the eye transitions to looking at the target"));
                        materialEditor.ShaderProperty(_Twitchyness, new GUIContent("Refocus Frequency", "How much should the eyes look around near the target?"));

                        XSStyles.SeparatorThin();
                        materialEditor.ShaderProperty(_IrisSize, new GUIContent("Iris Size", "Size of the iris"));
                        materialEditor.ShaderProperty(_FollowLimit, new GUIContent("Follow Limit", "Limits the angle from the front of the face on how far the eyes can track/rotate."));
                        materialEditor.ShaderProperty(_EyeOffsetLimit, new GUIContent("Offset Limit", "Limit for how far the eyes can turn"));
                    }
                }
            }
            //
        }

        private void DrawFurSettings(MaterialEditor materialEditor, Material material)
        {
            if (isFurShader)
            {
                Foldouts[material].ShowFur = XSStyles.ShurikenFoldout("Fur Settings", Foldouts[material].ShowFur);
                if (Foldouts[material].ShowFur)
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Noise Texture", "Used to control the pattern of the fur strands."), _NoiseTexture);
                    XSStyles.SeparatorThin();

                    materialEditor.TexturePropertySingleLine(new GUIContent("Fur Albedo", "Albedo Texture for the fur coat"), _FurTexture);
                    materialEditor.TextureScaleOffsetProperty(_FurTexture);
                    XSStyles.SeparatorThin();

                    materialEditor.TexturePropertySingleLine(new GUIContent("Length Mask", "Used to control length of the fur."), _FurLengthMask);
                    materialEditor.TextureScaleOffsetProperty(_FurLengthMask);
                    XSStyles.SeparatorThin();

                    materialEditor.ShaderProperty(_TopColor, new GUIContent("Top Color", ""));
                    materialEditor.ShaderProperty(_BottomColor, new GUIContent("Bottom Color", ""));
                    materialEditor.ShaderProperty(_ColorFalloffMin, new GUIContent("Blend Min", ""));
                    materialEditor.ShaderProperty(_ColorFalloffMax, new GUIContent("Blend Max", ""));
                    XSStyles.SeparatorThin();

                    materialEditor.ShaderProperty(_LayerCount, new GUIContent("Layer Count", ""));
                    materialEditor.ShaderProperty(_StrandAmount, new GUIContent("Strand Count", ""));
                    materialEditor.ShaderProperty(_FurLength, new GUIContent("Length", ""));
                    materialEditor.ShaderProperty(_FurWidth, new GUIContent("Strand Width", ""));
                    XSStyles.SeparatorThin();

                    materialEditor.ShaderProperty(_Gravity, new GUIContent("Gravity Strength", ""));
                    materialEditor.ShaderProperty(_CombX, new GUIContent("Comb X", ""));
                    materialEditor.ShaderProperty(_CombY, new GUIContent("Comb Y", ""));
                    XSStyles.SeparatorThin();
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
