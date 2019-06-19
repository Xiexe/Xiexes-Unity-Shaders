using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.Linq;
using System;
using System.Reflection;

public class XSToonInspector : ShaderGUI
{
    BindingFlags bindingFlags = BindingFlags.Public |
                                BindingFlags.NonPublic |
                                BindingFlags.Instance |
                                BindingFlags.Static;

    //Assign all properties as null at first to stop hundreds of warnings spamming the log when script gets compiled.
    //If they aren't we get warnings, because assigning with reflection seems to make Unity think that the properties never actually get used. 
    //
        MaterialProperty _TilingMode = null;
        MaterialProperty _Culling = null;
        MaterialProperty _MainTex = null;
        MaterialProperty _Saturation = null;
        MaterialProperty _Color = null;
        MaterialProperty _Cutoff = null;
        MaterialProperty _BumpMap = null;
        MaterialProperty _BumpScale = null;
        MaterialProperty _DetailNormalMap = null;
        MaterialProperty _DetailMask = null;
        MaterialProperty _DetailNormalMapScale = null;
        MaterialProperty _ReflectionMode = null;
        MaterialProperty _ReflectionBlendMode = null;
        MaterialProperty _MetallicGlossMap = null;
        MaterialProperty _BakedCubemap = null;
        MaterialProperty _Matcap = null;
        MaterialProperty _MatcapTint = null;
        MaterialProperty _ReflectivityMask = null;
        MaterialProperty _Metallic = null;
        MaterialProperty _Glossiness = null;
        MaterialProperty _Reflectivity = null;
        MaterialProperty _ClearCoat = null;
        MaterialProperty _ClearcoatStrength = null;
        MaterialProperty _ClearcoatSmoothness = null;
        MaterialProperty _EmissionMap = null;
        MaterialProperty _ScaleWithLight = null;
        MaterialProperty _ScaleWithLightSensitivity = null;
        MaterialProperty _EmissionColor = null;
        MaterialProperty _EmissionToDiffuse = null;
        MaterialProperty _RimColor = null;
        MaterialProperty _RimIntensity = null;
        MaterialProperty _RimRange = null;
        MaterialProperty _RimThreshold = null;
        MaterialProperty _RimSharpness = null;
        MaterialProperty _SpecMode = null;
        MaterialProperty _SpecularStyle = null;
        MaterialProperty _SpecularMap = null;
        MaterialProperty _SpecularIntensity = null;
        MaterialProperty _SpecularArea = null;
        MaterialProperty _AnisotropicAX = null;
        MaterialProperty _AnisotropicAY = null;
        MaterialProperty _SpecularAlbedoTint = null;
        MaterialProperty _RampSelectionMask = null;
        MaterialProperty _Ramp = null;
        MaterialProperty _ShadowRim = null;
        MaterialProperty _ShadowRimRange = null;
        MaterialProperty _ShadowRimThreshold = null;
        MaterialProperty _ShadowRimSharpness = null;
        MaterialProperty _OcclusionMap = null;
        MaterialProperty _OcclusionColor = null;
        MaterialProperty _ThicknessMap = null;
        MaterialProperty _SSColor = null;
        MaterialProperty _SSDistortion = null;
        MaterialProperty _SSPower = null;
        MaterialProperty _SSScale = null;
        MaterialProperty _SSSRange = null;
        MaterialProperty _SSSSharpness = null;
        //MaterialProperty _HalftoneDotSize = null;
        //MaterialProperty _HalftoneDotAmount = null;
        //MaterialProperty _HalftoneLineAmount = null;
        MaterialProperty _UVSetAlbedo = null;
        MaterialProperty _UVSetNormal = null;
        MaterialProperty _UVSetDetNormal = null;
        MaterialProperty _UVSetDetMask = null;
        MaterialProperty _UVSetMetallic = null;
        MaterialProperty _UVSetSpecular = null;
        MaterialProperty _UVSetReflectivity = null;
        MaterialProperty _UVSetThickness = null;
        MaterialProperty _UVSetOcclusion = null;
        MaterialProperty _UVSetEmission = null;
        MaterialProperty _Stencil = null;
        MaterialProperty _StencilComp = null;
        MaterialProperty _StencilOp = null;
        MaterialProperty _OutlineMask = null;
        MaterialProperty _OutlineWidth = null;
        MaterialProperty _OutlineColor = null;
        MaterialProperty _ShadowSharpness = null;
        MaterialProperty _AdvMode = null;
    //
    static bool showMainSettings = true;
    static bool showNormalMapSettings = false;
    static bool showShadows = true;
    static bool showSpecular = false;
    static bool showReflection = false;
    static bool showRimlight = false;
    static bool showSubsurface = false;
    static bool showOutlines = false;
    static bool showEmission = false;
    static bool showAdvanced = false;

    bool isOutlined = false;
    bool isCutout = false;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        Material material = materialEditor.target as Material;
        Shader shader = material.shader;

        isCutout = shader.name.Contains("Cutout") && !shader.name.Contains("A2C");
        isOutlined = shader.name.Contains("Outline");

        //Find all material properties listed in the script using reflection, and set them using a loop only if they're of type MaterialProperty. 
        //This makes things a lot nicer to maintain and cleaner to look at.
        foreach (var property in GetType().GetFields(bindingFlags)) 
        {                                                           
            if (property.FieldType == typeof(MaterialProperty))
            {
                property.SetValue(this, FindProperty(property.Name, props));
            }
        }

        EditorGUI.BeginChangeCheck();
        {
            if (!isCutout)// Do this to make sure that if you're using AlphaToCoverage that you fallback to cutout with 0.5 Cutoff if your shaders are blocked.
            {
                material.SetFloat("_Cutoff", 0.5f);
            }

            XSStyles.ShurikenHeaderCentered("XSToon v" + XSStyles.ver);
                materialEditor.ShaderProperty(_AdvMode, new GUIContent("Shader Mode", "Setting this to 'Advanced' will give you access to things such as stenciling, and other expiremental/advanced features."));
                materialEditor.ShaderProperty(_Culling, new GUIContent("Culling Mode", "Changes the culling mode. 'Off' will result in a two sided material, while 'Front' and 'Back' will cull those sides respectively"));
                materialEditor.ShaderProperty(_TilingMode, new GUIContent("Tiling Mode", "Setting this to Merged will tile and offset all textures based on the Main texture's Tiling/Offset."));

            showMainSettings = XSStyles.ShurikenFoldout("Main Settings", showMainSettings);
            if (showMainSettings)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("Main Texture", "The Main Texture."), _MainTex, _Color);
                if (isCutout)
                {
                    materialEditor.ShaderProperty(_Cutoff, new GUIContent("Cutoff", "The Cutoff Amount"), 2);
                }
                materialEditor.ShaderProperty(_UVSetAlbedo, new GUIContent("UV Set", "The UV set to use for the Albedo Texture"), 2);
                materialEditor.TextureScaleOffsetProperty(_MainTex);
                materialEditor.ShaderProperty(_Saturation, new GUIContent("Saturation", "Controls saturation of the final output from the shader."));

            }

            showShadows = XSStyles.ShurikenFoldout("Shadows", showShadows);
            if (showShadows)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("Ramp Selection Mask", "A black to white mask that determins how far up on the multi ramp to sample. 0 for bottom, 1 for top, 0.5 for middle, 0.25, and 0.75 for mid bottom and mid top respectively."), _RampSelectionMask);
                
                if (_RampSelectionMask.textureValue != null) 
                {
                    string rampMaskPath = AssetDatabase.GetAssetPath(_RampSelectionMask.textureValue);
                    TextureImporter ti = (TextureImporter)TextureImporter.GetAtPath(rampMaskPath);
                    if (ti.sRGBTexture) 
                    {
                        if (XSStyles.HelpBoxWithButton(new GUIContent("This texture is not marked as Linear.", "This is recommended for the mask"), new GUIContent("Fix Now"))) {
                            ti.sRGBTexture = false;
                            AssetDatabase.ImportAsset(rampMaskPath, ImportAssetOptions.ForceUpdate);
                            AssetDatabase.Refresh();
                        }
                    }
                }
                
                materialEditor.TexturePropertySingleLine(new GUIContent("Shadow Ramp", "Shadow Ramp, Dark to Light should be Left to Right, or Down to Up"), _Ramp);
                materialEditor.ShaderProperty(_ShadowSharpness, new GUIContent("Shadow Sharpness", "Controls the sharpness of recieved shadows, as well as the sharpness of 'shadows' from Vertex Lighting."));

                GUILayout.Space(5);
                materialEditor.TexturePropertySingleLine(new GUIContent("Occlusion Map", "Occlusion Map, used to darken areas on the model artifically."), _OcclusionMap);
                XSStyles.constrainedShaderProperty(materialEditor, _OcclusionColor, new GUIContent("Occlusion Tint", "Occlusion shadow tint."), 2);
                materialEditor.ShaderProperty(_UVSetOcclusion, new GUIContent("UV Set", "The UV set to use for the Occlusion Texture"), 2);
                materialEditor.TextureScaleOffsetProperty(_OcclusionMap);

                GUILayout.Space(5);
                XSStyles.constrainedShaderProperty(materialEditor, _ShadowRim, new GUIContent("Shadow Rim", "Shadow Rim Color. Set to white to disable."), 0);
                materialEditor.ShaderProperty(_ShadowRimRange, new GUIContent("Range", "Range of the Shadow Rim"), 2);
                materialEditor.ShaderProperty(_ShadowRimThreshold, new GUIContent("Threshold", "Threshold of the Shadow Rim"), 2);
                materialEditor.ShaderProperty(_ShadowRimSharpness, new GUIContent("Sharpness", "Sharpness of the Shadow Rim"), 2);
                XSStyles.callGradientEditor(material);
            }

            if (isOutlined)
            {
                showOutlines = XSStyles.ShurikenFoldout("Outlines", showOutlines);
                if (showOutlines)
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Outline Mask", "Outline width mask, black will make the outline minimum width."), _OutlineMask);
                    materialEditor.ShaderProperty(_OutlineWidth, new GUIContent("Outline Width", "Width of the Outlines"));
                    XSStyles.constrainedShaderProperty(materialEditor, _OutlineColor, new GUIContent("Outline Color", "Color of the outlines"), 0);
                }
            }

            showNormalMapSettings = XSStyles.ShurikenFoldout("Normal Maps", showNormalMapSettings);
            if (showNormalMapSettings)
            {

                materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map", "Normal Map"), _BumpMap);
                materialEditor.ShaderProperty(_BumpScale, new GUIContent("Normal Strength", "Strength of the main Normal Map"), 2);
                materialEditor.ShaderProperty(_UVSetNormal, new GUIContent("UV Set", "The UV set to use for the Normal Map"), 2);
                materialEditor.TextureScaleOffsetProperty(_BumpMap);

                GUILayout.Space(5);
                materialEditor.TexturePropertySingleLine(new GUIContent("Detail Normal Map", "Detail Normal Map"), _DetailNormalMap);
                materialEditor.ShaderProperty(_DetailNormalMapScale, new GUIContent("Detail Normal Strength", "Strength of the detail Normal Map"), 2);
                materialEditor.ShaderProperty(_UVSetDetNormal, new GUIContent("UV Set", "The UV set to use for the Detail Normal Map"), 2);
                materialEditor.TextureScaleOffsetProperty(_DetailNormalMap);

                GUILayout.Space(5);
                materialEditor.TexturePropertySingleLine(new GUIContent("Detail Mask", "Mask for Detail Normal Map"), _DetailMask);
                materialEditor.ShaderProperty(_UVSetDetMask, new GUIContent("UV Set", "The UV set to use for the Detail Mask"), 2);
                materialEditor.TextureScaleOffsetProperty(_DetailMask);

            }

            showSpecular = XSStyles.ShurikenFoldout("Specular", showSpecular);
            if (showSpecular)
            {
                materialEditor.ShaderProperty(_SpecMode, new GUIContent("Specular Mode", "Specular Mode."));
                materialEditor.ShaderProperty(_SpecularStyle, new GUIContent("Specular Style", "Specular Style."));
                materialEditor.TexturePropertySingleLine(new GUIContent("Specular Map(R,G,B)", "Specular Map. Red channel controls Intensity, Green controls how much specular is tinted by Albedo, and Blue controls Smoothness (Only for Blinn-Phong, and GGX)."), _SpecularMap);
                materialEditor.TextureScaleOffsetProperty(_SpecularMap);
                materialEditor.ShaderProperty(_UVSetSpecular, new GUIContent("UV Set", "The UV set to use for the Specular Map"), 2);
                materialEditor.ShaderProperty(_SpecularIntensity, new GUIContent("Specular Intensity", "Specular Intensity."), 2);
                materialEditor.ShaderProperty(_SpecularAlbedoTint, new GUIContent("Specular Albedo Tint", "How much the specular highlight should derive color from the albedo of the object."), 2);
                if (_SpecMode.floatValue == 0 || _SpecMode.floatValue == 2)
                {
                    materialEditor.ShaderProperty(_SpecularArea, new GUIContent("Specular Area", "Specular Area."), 2);
                }
                else
                {
                    materialEditor.ShaderProperty(_AnisotropicAX, new GUIContent("Anisotropic Width", "Anisotropic Width, makes anistropic relfections more horizontal"), 2);
                    materialEditor.ShaderProperty(_AnisotropicAY, new GUIContent("Anisotropic Height", "Anisotropic Height, makes anistropic relfections more vertical"), 2);
                }
            }

            showReflection = XSStyles.ShurikenFoldout("Reflections", showReflection);
            if (showReflection)
            {
                materialEditor.ShaderProperty(_ReflectionMode, new GUIContent("Reflection Mode", "Reflection Mode."));

                if (_ReflectionMode.floatValue == 0) // PBR
                {
                    materialEditor.ShaderProperty(_ReflectionBlendMode, new GUIContent("Reflection Blend Mode", "Blend mode for reflection. Additive is Color + reflection, Multiply is Color * reflection, and subtractive is Color - reflection"));
                    materialEditor.ShaderProperty(_ClearCoat, new GUIContent("Clearcoat", "Clearcoat"));
                    materialEditor.TexturePropertySingleLine(new GUIContent("Fallback Cubemap", " Used as fallback in 'Unity' reflection mode if reflection probe is black."), _BakedCubemap);
                    materialEditor.TexturePropertySingleLine(new GUIContent("Metallic Map", "Metallic Map, Metallic on Red Channel, Smoothness on Alpha Channel. \nIf Clearcoat is enabled, Clearcoat Smoothness on Green Channel, Clearcoat Reflectivity on Blue Channel."), _MetallicGlossMap);
                    materialEditor.TextureScaleOffsetProperty(_MetallicGlossMap);
                    materialEditor.ShaderProperty(_UVSetMetallic, new GUIContent("UV Set", "The UV set to use for the Metallic Smoothness Map"), 2);
                    materialEditor.ShaderProperty(_Metallic, new GUIContent("Metallic", "Metallic, set to 1 if using metallic map"), 2);
                    materialEditor.ShaderProperty(_Glossiness, new GUIContent("Smoothness", "Smoothness, set to 1 if using metallic map"), 2);
                    materialEditor.ShaderProperty(_ClearcoatSmoothness, new GUIContent("Clearcoat Smoothness", "Smoothness of the clearcoat."), 2);
                    materialEditor.ShaderProperty(_ClearcoatStrength, new GUIContent("Clearcoat Reflectivity", "The strength of the clearcoat reflection."), 2);
                }
                else if (_ReflectionMode.floatValue == 1) //Baked cube
                {
                    materialEditor.ShaderProperty(_ReflectionBlendMode, new GUIContent("Reflection Blend Mode", "Blend mode for reflection. Additive is Color + reflection, Multiply is Color * reflection, and subtractive is Color - reflection"));
                    materialEditor.ShaderProperty(_ClearCoat, new GUIContent("Clearcoat", "Clearcoat"));
                    materialEditor.TexturePropertySingleLine(new GUIContent("Baked Cubemap", "Baked cubemap."), _BakedCubemap);
                    materialEditor.TexturePropertySingleLine(new GUIContent("Metallic Map", "Metallic Map, Metallic on Red Channel, Smoothness on Alpha Channel. \nIf Clearcoat is enabled, Clearcoat Smoothness on Green Channel, Clearcoat Reflectivity on Blue Channel."), _MetallicGlossMap);
                    materialEditor.TextureScaleOffsetProperty(_MetallicGlossMap);
                    materialEditor.ShaderProperty(_UVSetMetallic, new GUIContent("UV Set", "The UV set to use for the MetallicSmoothness Map"), 2);
                    materialEditor.ShaderProperty(_Metallic, new GUIContent("Metallic", "Metallic, set to 1 if using metallic map"), 2);
                    materialEditor.ShaderProperty(_Glossiness, new GUIContent("Smoothness", "Smoothness, set to 1 if using metallic map"), 2);
                    materialEditor.ShaderProperty(_ClearcoatSmoothness, new GUIContent("Clearcoat Smoothness", "Smoothness of the clearcoat."), 2);
                    materialEditor.ShaderProperty(_ClearcoatStrength, new GUIContent("Clearcoat Reflectivity", "The strength of the clearcoat reflection."), 2);
                }
                else if (_ReflectionMode.floatValue == 2) //Matcap
                {
                    materialEditor.ShaderProperty(_ReflectionBlendMode, new GUIContent("Reflection Blend Mode", "Blend mode for reflection. Additive is Color + reflection, Multiply is Color * reflection, and subtractive is Color - reflection"));
                    materialEditor.TexturePropertySingleLine(new GUIContent("Matcap", "Matcap Texture"), _Matcap, _MatcapTint);
                    materialEditor.ShaderProperty(_Glossiness, new GUIContent("Matcap Blur", "Matcap blur, blurs the Matcap, set to 1 for full clarity"), 2);
                    material.SetFloat("_Metallic", 0);
                    material.SetFloat("_ClearCoat", 0);
                    material.SetTexture("_MetallicGlossMap", null);
                }
                if (_ReflectionMode.floatValue != 3)
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Reflectivity Mask", "Mask for reflections."), _ReflectivityMask);
                    materialEditor.TextureScaleOffsetProperty(_ReflectivityMask);
                    materialEditor.ShaderProperty(_UVSetReflectivity, new GUIContent("UV Set", "The UV set to use for the Reflectivity Mask"), 2);
                    materialEditor.ShaderProperty(_Reflectivity, new GUIContent("Reflectivity", "The strength of the reflections."), 2);
                }
                if(_ReflectionMode.floatValue == 3)
                {
                    material.SetFloat("_Metallic", 0);
                    material.SetFloat("_ReflectionBlendMode", 0);
                    material.SetFloat("_ClearCoat", 0);
                }
            }

            showEmission = XSStyles.ShurikenFoldout("Emission", showEmission);
            if (showEmission)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("Emission Map", "Emissive map. White to black, unless you want multiple colors."), _EmissionMap, _EmissionColor);
                materialEditor.TextureScaleOffsetProperty(_EmissionMap);
                materialEditor.ShaderProperty(_UVSetEmission, new GUIContent("UV Set", "The UV set to use for the Emission Map"), 2);
                materialEditor.ShaderProperty(_EmissionToDiffuse, new GUIContent("Tint To Diffuse", "Tints the emission to the Diffuse Color"), 2);

                GUILayout.Space(5);
                materialEditor.ShaderProperty(_ScaleWithLight, new GUIContent("Scale w/ Light", "Scales the emission intensity based on how dark or bright the environment is."));
                if(_ScaleWithLight.floatValue == 0)
                    materialEditor.ShaderProperty(_ScaleWithLightSensitivity, new GUIContent("Scaling Sensitivity", "How agressively the emission should scale with the light."));
            }

            showRimlight = XSStyles.ShurikenFoldout("Rimlight", showRimlight);
            if (showRimlight)
            {
                materialEditor.ShaderProperty(_RimColor, new GUIContent("Rimlight Tint", "The Tint of the Rimlight."));
                materialEditor.ShaderProperty(_RimIntensity, new GUIContent("Rimlight Intensity", "Strength of the Rimlight."));
                materialEditor.ShaderProperty(_RimRange, new GUIContent("Range", "Range of the Rim"), 2);
                materialEditor.ShaderProperty(_RimThreshold, new GUIContent("Threshold", "Threshold of the Rim"), 2);
                materialEditor.ShaderProperty(_RimSharpness, new GUIContent("Sharpness", "Sharpness of the Rim"), 2);
            }

            showSubsurface = XSStyles.ShurikenFoldout("Subsurface Scattering", showSubsurface);
            if (showSubsurface)
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("Thickness Map", "Thickness Map, used to mask areas where subsurface can happen"), _ThicknessMap);
                materialEditor.TextureScaleOffsetProperty(_ThicknessMap);
                materialEditor.ShaderProperty(_UVSetThickness, new GUIContent("UV Set", "The UV set to use for the Thickness Map"), 2);

                XSStyles.constrainedShaderProperty(materialEditor, _SSColor, new GUIContent("Subsurface Color", "Subsurface Scattering Color"), 2);
                materialEditor.ShaderProperty(_SSDistortion, new GUIContent("Subsurface Distortion", "How much the subsurface follows the normals of the mesh, Normal map."), 2);
                materialEditor.ShaderProperty(_SSPower, new GUIContent("Subsurface Power", "Subsurface Power"), 2);
                materialEditor.ShaderProperty(_SSScale, new GUIContent("Subsurface Scale", "Subsurface Scale"), 2);
                materialEditor.ShaderProperty(_SSSRange, new GUIContent("Subsurface Range", "Subsurface Range"), 2);
                materialEditor.ShaderProperty(_SSSSharpness, new GUIContent("Subsurface Sharpness", "Subsurface Sharpness"), 2);
            }

            if (_AdvMode.floatValue == 1)
            {
                showAdvanced = XSStyles.ShurikenFoldout("Advanced Settings", showAdvanced);
                if (showAdvanced)
                {
                    materialEditor.ShaderProperty(_Stencil, _Stencil.displayName);
                    materialEditor.ShaderProperty(_StencilComp, _StencilComp.displayName);
                    materialEditor.ShaderProperty(_StencilOp, _StencilOp.displayName);
                }
            }

            XSStyles.DoFooter();
        }
    }
}